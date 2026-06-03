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
            let orientation = CGImagePropertyOrientation(image.imageOrientation)
            var results = try recognize(cgImage: cgImage, orientation: orientation)

            if let enhancedImage = enhancedNutritionImage(from: cgImage) {
                results.append(contentsOf: try recognize(cgImage: enhancedImage, orientation: orientation))
            }

            return deduplicated(results)
        }.value
    }

    private static func recognize(cgImage: CGImage, orientation: CGImagePropertyOrientation) throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.customWords = ["营养成分表", "每份", "每100克", "钠", "纳", "鈉", "毫克", "mg"]
        request.minimumTextHeight = 0.002

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            throw NutritionOCRError.recognitionFailed
        }

        return observations.flatMap { observation in
            observation.topCandidates(5).map(\.string)
        }
    }

    private static func enhancedNutritionImage(from cgImage: CGImage) -> CGImage? {
        let input = CIImage(cgImage: cgImage)
        let filters = input
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputBrightnessKey: 0.08,
                kCIInputContrastKey: 1.85
            ])
            .applyingFilter("CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: 0.75
            ])

        return CIContext(options: nil).createCGImage(filters, from: filters.extent)
    }

    private static func deduplicated(_ lines: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for line in lines {
            let normalized = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty, !seen.contains(normalized) else { continue }
            seen.insert(normalized)
            result.append(normalized)
        }
        return result
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
