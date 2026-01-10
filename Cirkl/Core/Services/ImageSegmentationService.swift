import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Image Segmentation Service (Person Background Removal)
/// Service qui utilise Vision Framework pour détourer automatiquement les personnes
/// et créer des images avec fond transparent pour l'effet glass bubble
@MainActor
final class ImageSegmentationService: ObservableObject {
    static let shared = ImageSegmentationService()

    // Cache des images segmentées (évite de retraiter à chaque affichage)
    private var segmentedImagesCache: [String: UIImage] = [:]

    // Context Core Image pour le traitement
    private let ciContext: CIContext

    private init() {
        // Créer un contexte optimisé pour le traitement d'images
        self.ciContext = CIContext(options: [
            .useSoftwareRenderer: false,
            .highQualityDownsample: true
        ])
    }

    // MARK: - Public API

    /// Retourne une image détourée (fond transparent) à partir du nom d'asset
    /// - Parameter imageName: Nom de l'image dans les Assets
    /// - Returns: UIImage avec fond transparent, ou l'originale si échec
    func getSegmentedImage(named imageName: String) async -> UIImage? {
        // Vérifier le cache d'abord
        if let cached = segmentedImagesCache[imageName] {
            print("✅ Cache hit for \(imageName)")
            return cached
        }

        // Charger l'image originale
        guard let originalImage = UIImage(named: imageName) else {
            print("❌ Image not found: \(imageName)")
            return nil
        }

        print("🔄 Processing segmentation for \(imageName)...")

        // Effectuer la segmentation
        if let segmented = await segmentPerson(from: originalImage) {
            segmentedImagesCache[imageName] = segmented
            print("✅ Segmentation complete for \(imageName)")
            return segmented
        }

        print("⚠️ Segmentation failed for \(imageName), returning original")
        // Fallback: retourner l'originale
        return originalImage
    }

    /// Précharge et segmente toutes les images de profil
    func preloadAllProfileImages() async {
        let profileNames = [
            "photo_gil", "photo_denis", "photo_shay",
            "photo_salome", "photo_dan", "photo_gilles", "photo_judith"
        ]

        for name in profileNames {
            _ = await getSegmentedImage(named: name)
        }
    }

    // MARK: - Person Segmentation (Vision Framework)

    /// Segmente une personne de l'arrière-plan en utilisant Vision
    private func segmentPerson(from image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else {
            print("❌ Cannot get CGImage")
            return nil
        }

        print("🔄 Starting Vision segmentation for image \(cgImage.width)x\(cgImage.height)...")

        // Exécuter Vision sur un thread background
        let maskBuffer: CVPixelBuffer? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {

                // Essayer d'abord VNGeneratePersonSegmentationRequest
                let personRequest = VNGeneratePersonSegmentationRequest()
                personRequest.qualityLevel = .accurate
                personRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                do {
                    try handler.perform([personRequest])

                    if let result = personRequest.results?.first {
                        print("✅ VNGeneratePersonSegmentationRequest succeeded!")
                        continuation.resume(returning: result.pixelBuffer)
                        return
                    } else {
                        print("⚠️ VNGeneratePersonSegmentationRequest returned no results")
                    }
                } catch {
                    print("⚠️ VNGeneratePersonSegmentationRequest failed: \(error.localizedDescription)")
                }

                // Fallback: essayer VNGenerateForegroundInstanceMaskRequest (iOS 17+)
                if #available(iOS 17.0, *) {
                    print("🔄 Trying VNGenerateForegroundInstanceMaskRequest fallback...")
                    let foregroundRequest = VNGenerateForegroundInstanceMaskRequest()

                    do {
                        try handler.perform([foregroundRequest])

                        if let result = foregroundRequest.results?.first {
                            // Générer le masque pour toutes les instances
                            let allInstances = result.allInstances
                            if let maskPixelBuffer = try? result.generateScaledMaskForImage(forInstances: allInstances, from: handler) {
                                print("✅ VNGenerateForegroundInstanceMaskRequest succeeded!")
                                continuation.resume(returning: maskPixelBuffer)
                                return
                            }
                        }
                        print("⚠️ VNGenerateForegroundInstanceMaskRequest returned no usable mask")
                    } catch {
                        print("⚠️ VNGenerateForegroundInstanceMaskRequest failed: \(error.localizedDescription)")
                    }
                }

                print("❌ All segmentation methods failed")
                continuation.resume(returning: nil)
            }
        }

        // Appliquer le masque sur le main thread (où ciContext vit)
        guard let maskBuffer = maskBuffer else {
            print("❌ No mask buffer returned from Vision - segmentation failed")
            return nil
        }

        print("🔄 Applying mask to create transparent image...")
        return createTransparentImage(originalCGImage: cgImage, maskBuffer: maskBuffer)
    }

    /// Crée une image avec fond transparent en utilisant le masque comme canal alpha
    private func createTransparentImage(originalCGImage: CGImage, maskBuffer: CVPixelBuffer) -> UIImage? {
        print("🔍 Creating transparent image...")

        // Convertir l'image originale en CIImage
        let originalCIImage = CIImage(cgImage: originalCGImage)

        // Convertir le masque CVPixelBuffer en CIImage
        let maskCIImage = CIImage(cvPixelBuffer: maskBuffer)

        print("🔍 Original size: \(originalCIImage.extent)")
        print("🔍 Mask size: \(maskCIImage.extent)")

        // Redimensionner le masque pour correspondre à l'image originale
        let scaleX = originalCIImage.extent.width / maskCIImage.extent.width
        let scaleY = originalCIImage.extent.height / maskCIImage.extent.height

        var scaledMask = maskCIImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // S'assurer que le masque est bien aligné avec l'image originale
        scaledMask = scaledMask.transformed(by: CGAffineTransform(translationX: originalCIImage.extent.origin.x - scaledMask.extent.origin.x,
                                                                   y: originalCIImage.extent.origin.y - scaledMask.extent.origin.y))

        print("🔍 Scaled mask size: \(scaledMask.extent)")

        // MÉTHODE 1: Utiliser le masque comme canal alpha directement
        // Composer: RGB de l'original + Alpha du masque

        // D'abord, convertir le masque grayscale en alpha
        guard let maskToAlphaFilter = CIFilter(name: "CIMaskToAlpha") else {
            print("❌ Cannot create CIMaskToAlpha filter")
            // Fallback: essayer avec CIBlendWithAlphaMask
            return createTransparentImageWithBlend(originalCIImage: originalCIImage, maskCIImage: scaledMask)
        }

        maskToAlphaFilter.setValue(scaledMask, forKey: kCIInputImageKey)

        guard let alphaMask = maskToAlphaFilter.outputImage else {
            print("❌ CIMaskToAlpha produced no output, trying blend approach")
            return createTransparentImageWithBlend(originalCIImage: originalCIImage, maskCIImage: scaledMask)
        }

        // Utiliser CIBlendWithAlphaMask pour combiner
        guard let blendFilter = CIFilter(name: "CIBlendWithAlphaMask") else {
            print("❌ Cannot create CIBlendWithAlphaMask filter")
            return createTransparentImageWithBlend(originalCIImage: originalCIImage, maskCIImage: scaledMask)
        }

        // Background transparent
        let clearImage = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: originalCIImage.extent)

        blendFilter.setValue(originalCIImage, forKey: kCIInputImageKey)
        blendFilter.setValue(clearImage, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(alphaMask, forKey: kCIInputMaskImageKey)

        guard let outputCIImage = blendFilter.outputImage else {
            print("❌ CIBlendWithAlphaMask produced no output")
            return createTransparentImageWithBlend(originalCIImage: originalCIImage, maskCIImage: scaledMask)
        }

        return renderToUIImage(outputCIImage, extent: originalCIImage.extent)
    }

    /// Méthode alternative avec CIBlendWithMask
    private func createTransparentImageWithBlend(originalCIImage: CIImage, maskCIImage: CIImage) -> UIImage? {
        print("🔍 Trying CIBlendWithMask fallback...")

        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            print("❌ Cannot create CIBlendWithMask filter")
            return nil
        }

        let clearImage = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
            .cropped(to: originalCIImage.extent)

        blendFilter.setValue(originalCIImage, forKey: kCIInputImageKey)
        blendFilter.setValue(clearImage, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(maskCIImage, forKey: kCIInputMaskImageKey)

        guard let outputCIImage = blendFilter.outputImage else {
            print("❌ CIBlendWithMask produced no output")
            return nil
        }

        return renderToUIImage(outputCIImage, extent: originalCIImage.extent)
    }

    /// Render CIImage to UIImage with transparency support
    private func renderToUIImage(_ ciImage: CIImage, extent: CGRect) -> UIImage? {
        // Utiliser un format qui supporte la transparence
        let format = CIFormat.RGBA8
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let outputCGImage = ciContext.createCGImage(
            ciImage,
            from: extent,
            format: format,
            colorSpace: colorSpace
        ) else {
            print("❌ Cannot render final CGImage")
            return nil
        }

        print("✅ Created transparent image! Size: \(outputCGImage.width)x\(outputCGImage.height), hasAlpha: \(outputCGImage.alphaInfo != .none)")
        return UIImage(cgImage: outputCGImage)
    }

    // MARK: - Cache Management

    /// Vide le cache des images segmentées
    func clearCache() {
        segmentedImagesCache.removeAll()
    }

    /// Vérifie si une image est déjà en cache
    func isCached(_ imageName: String) -> Bool {
        return segmentedImagesCache[imageName] != nil
    }
}

// MARK: - SwiftUI Image Extension pour faciliter l'usage
extension Image {
    /// Crée une Image à partir d'une UIImage optionnelle avec fallback
    init(uiImage: UIImage?, fallbackSystemName: String) {
        if let uiImage = uiImage {
            self.init(uiImage: uiImage)
        } else {
            self.init(systemName: fallbackSystemName)
        }
    }
}

// MARK: - Async Image View avec Segmentation
/// Vue qui charge et affiche une image segmentée de manière asynchrone
struct SegmentedAsyncImage: View {
    let imageName: String
    let size: CGSize
    let placeholderColor: Color

    @State private var segmentedImage: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let image = segmentedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(Circle())
            } else if isLoading {
                // Placeholder pendant le chargement avec spinner
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                placeholderColor.opacity(0.15),
                                placeholderColor.opacity(0.25)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size.width * 0.5
                        )
                    )
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(placeholderColor.opacity(0.6))
                    )
            } else {
                // Fallback si pas d'image - icône personne
                Image(systemName: "person.fill")
                    .font(.system(size: size.width * 0.35, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                placeholderColor.opacity(0.8),
                                placeholderColor.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .task {
            await loadSegmentedImage()
        }
    }

    private func loadSegmentedImage() async {
        isLoading = true
        segmentedImage = await ImageSegmentationService.shared.getSegmentedImage(named: imageName)
        isLoading = false
    }
}
