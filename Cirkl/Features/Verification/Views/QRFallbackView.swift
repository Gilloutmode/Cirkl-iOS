import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins

// MARK: - QRFallbackView
/// Vue de fallback QR code pour la vérification quand MultipeerConnectivity/UWB n'est pas disponible
struct QRFallbackView: View {

    // MARK: - Properties
    @Bindable var viewModel: VerificationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var mode: QRMode = .display
    @State private var scannedCode: String?
    @State private var showError = false
    @State private var errorMessage = ""

    enum QRMode {
        case display
        case scan
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.04, green: 0.05, blue: 0.15)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Mode picker
                    modePicker

                    // Content
                    if mode == .display {
                        qrDisplayView
                    } else {
                        qrScannerView
                    }
                }
                .padding()
            }
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Mode Picker
    private var modePicker: some View {
        HStack(spacing: 0) {
            modeButton(title: "Mon QR", mode: .display, icon: "qrcode")
            modeButton(title: "Scanner", mode: .scan, icon: "qrcode.viewfinder")
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    private func modeButton(title: String, mode: QRMode, icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                self.mode = mode
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(self.mode == mode ? .white : .white.opacity(0.6))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(self.mode == mode ? .mint.opacity(0.3) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - QR Display View
    private var qrDisplayView: some View {
        VStack(spacing: 24) {
            // QR Code
            if let qrData = viewModel.generateQRData(),
               let qrImage = generateQRCode(from: qrData) {
                ZStack {
                    // Glow
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white)
                        .frame(width: 220, height: 220)
                        .shadow(color: .mint.opacity(0.3), radius: 30)

                    // QR Image
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )
            } else {
                // Error state
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)

                    Text("Impossible de générer le QR code")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(width: 260, height: 260)
            }

            // Instructions
            VStack(spacing: 12) {
                Text("Faites scanner ce QR code")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("L'autre personne doit scanner ce code avec son application CirKL pour vérifier votre rencontre.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            Spacer()
        }
    }

    // MARK: - QR Scanner View
    private var qrScannerView: some View {
        VStack(spacing: 24) {
            // Camera preview
            QRScannerRepresentable { code in
                handleScannedCode(code)
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.mint.opacity(0.5), lineWidth: 2)
            )
            .overlay(
                // Scanning frame
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.mint, lineWidth: 2)
                    .frame(width: 200, height: 200)
            )

            // Instructions
            VStack(spacing: 12) {
                Text("Scannez le QR code")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("Pointez la caméra vers le QR code affiché sur le téléphone de l'autre personne.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private func generateQRCode(from data: Data) -> UIImage? {
        guard let string = String(data: data, encoding: .utf8) else { return nil }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        // Scale up the QR code
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private func handleScannedCode(_ code: String) {
        guard scannedCode == nil else { return } // Prevent multiple scans
        scannedCode = code

        // Try to decode as VerificationData
        guard let data = code.data(using: .utf8) else {
            showError(message: "Code QR invalide")
            return
        }

        viewModel.processScannedQR(data)
        dismiss()
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
        scannedCode = nil // Allow retry
    }
}

// MARK: - QR Scanner Representable
struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

// MARK: - QR Scanner View Controller
class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var onCodeScanned: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)

            let output = AVCaptureMetadataOutput()
            captureSession?.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.bounds
            view.layer.addSublayer(previewLayer!)

        } catch {
            print("QRScanner: Error setting up camera: \(error)")
        }
    }

    private func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    private func stopScanning() {
        captureSession?.stopRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else { return }

        // Vibrate feedback
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        stopScanning()
        onCodeScanned?(stringValue)
    }
}

// MARK: - Preview
#Preview {
    QRFallbackView(viewModel: VerificationViewModel())
}
