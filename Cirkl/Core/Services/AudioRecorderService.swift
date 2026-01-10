import AVFoundation
import Foundation

// MARK: - Recording State
enum RecordingState: Equatable {
    case idle
    case requestingPermission
    case recording
    case processing
    case error(String)

    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }
}

// MARK: - Recording Errors
enum AudioRecordingError: LocalizedError {
    case permissionDenied
    case sessionConfigurationFailed(Error)
    case recorderInitializationFailed(Error)
    case noRecordingData
    case recordingInProgress
    case notRecording

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Accès au microphone refusé. Activez-le dans les Réglages."
        case .sessionConfigurationFailed(let error):
            return "Erreur configuration audio: \(error.localizedDescription)"
        case .recorderInitializationFailed(let error):
            return "Erreur initialisation: \(error.localizedDescription)"
        case .noRecordingData:
            return "Aucune donnée audio enregistrée."
        case .recordingInProgress:
            return "Un enregistrement est déjà en cours."
        case .notRecording:
            return "Aucun enregistrement en cours."
        }
    }
}

// MARK: - AudioRecorderService
/// Service for recording audio messages for the CirKL AI assistant
@MainActor
final class AudioRecorderService: NSObject, ObservableObject {

    // MARK: - Singleton
    static let shared = AudioRecorderService()

    // MARK: - Published State
    @Published private(set) var state: RecordingState = .idle
    @Published private(set) var recordingDuration: TimeInterval = 0
    @Published private(set) var audioLevel: Float = 0

    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var durationTimer: Timer?
    private var levelTimer: Timer?

    private let audioSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVEncoderBitRateKey: 128000
    ]

    // MARK: - Configuration
    static let maxRecordingDuration: TimeInterval = 60 // 1 minute max
    static let minRecordingDuration: TimeInterval = 0.5 // 0.5 sec min

    // MARK: - Init
    private override init() {
        super.init()
    }

    // MARK: - Permission

    /// Request microphone permission
    /// - Returns: true if permission granted
    func requestPermission() async -> Bool {
        state = .requestingPermission

        let status = AVAudioApplication.shared.recordPermission

        switch status {
        case .granted:
            state = .idle
            return true

        case .denied:
            state = .error("Permission refusée")
            return false

        case .undetermined:
            let granted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            state = granted ? .idle : .error("Permission refusée")
            return granted

        @unknown default:
            state = .error("Statut permission inconnu")
            return false
        }
    }

    /// Check if microphone permission is granted
    var hasPermission: Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }

    // MARK: - Recording Control

    /// Start audio recording
    func startRecording() async throws {
        guard state != .recording else {
            throw AudioRecordingError.recordingInProgress
        }

        // Check permission
        guard await requestPermission() else {
            throw AudioRecordingError.permissionDenied
        }

        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            state = .error("Erreur session audio")
            throw AudioRecordingError.sessionConfigurationFailed(error)
        }

        // Create temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "cirkl_audio_\(UUID().uuidString).m4a"
        recordingURL = tempDir.appendingPathComponent(fileName)

        guard let url = recordingURL else {
            throw AudioRecordingError.recorderInitializationFailed(NSError(domain: "AudioRecorder", code: -1))
        }

        // Initialize recorder
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: audioSettings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true

            guard audioRecorder?.prepareToRecord() == true else {
                throw AudioRecordingError.recorderInitializationFailed(NSError(domain: "AudioRecorder", code: -2))
            }

            audioRecorder?.record(forDuration: Self.maxRecordingDuration)
            state = .recording
            recordingDuration = 0

            startTimers()

            #if DEBUG
            print("🎤 Recording started: \(url.lastPathComponent)")
            #endif

        } catch {
            state = .error("Erreur enregistrement")
            throw AudioRecordingError.recorderInitializationFailed(error)
        }
    }

    /// Stop recording and return audio data
    /// - Returns: Audio data as Data (AAC encoded)
    func stopRecording() async throws -> Data {
        guard state == .recording, let recorder = audioRecorder else {
            throw AudioRecordingError.notRecording
        }

        stopTimers()

        // Check minimum duration
        let duration = recorder.currentTime
        guard duration >= Self.minRecordingDuration else {
            recorder.stop()
            cleanupRecording()
            throw AudioRecordingError.noRecordingData
        }

        state = .processing
        recorder.stop()

        // Deactivate session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        // Read audio data
        guard let url = recordingURL else {
            cleanupRecording()
            throw AudioRecordingError.noRecordingData
        }

        do {
            let data = try Data(contentsOf: url)

            #if DEBUG
            print("🎤 Recording stopped: \(duration)s, \(data.count) bytes")
            #endif

            cleanupRecording()
            state = .idle

            return data
        } catch {
            cleanupRecording()
            state = .error("Erreur lecture audio")
            throw AudioRecordingError.noRecordingData
        }
    }

    /// Cancel recording without returning data
    func cancelRecording() {
        stopTimers()
        audioRecorder?.stop()
        cleanupRecording()
        state = .idle

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        #if DEBUG
        print("🎤 Recording cancelled")
        #endif
    }

    // MARK: - Private Helpers

    private func startTimers() {
        // Duration timer
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let recorder = self.audioRecorder else { return }
                self.recordingDuration = recorder.currentTime

                // Auto-stop at max duration
                if self.recordingDuration >= Self.maxRecordingDuration {
                    // Will be handled by delegate
                }
            }
        }

        // Level metering timer
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let recorder = self.audioRecorder else { return }
                recorder.updateMeters()
                // Normalize from -160...0 to 0...1
                let level = recorder.averagePower(forChannel: 0)
                self.audioLevel = max(0, min(1, (level + 60) / 60))
            }
        }
    }

    private func stopTimers() {
        durationTimer?.invalidate()
        durationTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0
    }

    private func cleanupRecording() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        audioRecorder = nil
        recordingDuration = 0
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorderService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag && state == .recording {
                state = .error("Enregistrement échoué")
                cleanupRecording()
            }

            #if DEBUG
            print("🎤 Recorder finished: success=\(flag)")
            #endif
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            state = .error(error?.localizedDescription ?? "Erreur encodage")
            cleanupRecording()

            #if DEBUG
            print("🎤 Recorder error: \(error?.localizedDescription ?? "unknown")")
            #endif
        }
    }
}
