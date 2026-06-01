import ImageIO
import UIKit
import Vision

enum NutritionOCRError: Error {
    case missingImageData
    case recognitionFailed
}

enum NutritionOCRService {
    static func recognizeText(from image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw NutritionOCRError.missingImageData
        }

        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["zh-Hans", "en-US"]

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: CGImagePropertyOrientation(image.imageOrientation),
                options: [:]
            )
            try handler.perform([request])

            guard let observations = request.results else {
                throw NutritionOCRError.recognitionFailed
            }

            return observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
        }.value
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
