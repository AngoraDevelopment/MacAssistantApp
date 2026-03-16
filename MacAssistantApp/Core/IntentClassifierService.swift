import Foundation
import CoreML

struct IntentPrediction {
    let label: String
    let confidence: Double
}

final class IntentClassifierService {
    private var model: IntentClassifier?

    init() {
        do {
            model = try IntentClassifier(configuration: MLModelConfiguration())
        } catch {
            print("No se pudo cargar el modelo de Create ML: \(error)")
            model = nil
        }
    }

    func predictIntent(for text: String) -> IntentPrediction {
        guard let model else {
            return IntentPrediction(label: "unknown", confidence: 0)
        }

        do {
            let prediction = try model.prediction(text: text)
            return IntentPrediction(label: prediction.label, confidence: 1.0)
        } catch {
            print("Error al predecir intención: \(error)")
            return IntentPrediction(label: "unknown", confidence: 0)
        }
    }
}
