import Foundation

struct SauceInput: Equatable {
    var sodiumMilligrams: Double
    var referenceGrams: Double
    var grams: Double
}

struct SauceCalculation: Equatable {
    var targetNaClGrams: Double
    var sweetNaClGrams: Double
    var beanNaClGrams: Double
    var soyNaClGrams: Double
    var soyGrams: Double

    var currentNaClGrams: Double {
        sweetNaClGrams + beanNaClGrams + soyNaClGrams
    }

    var manualNaClGrams: Double {
        sweetNaClGrams + beanNaClGrams
    }
}

enum SauceCalculator {
    static let sodiumToNaCl = 2.542

    static func targetNaClGrams(meatGrams: Double, saltPercent: Double) -> Double {
        guard meatGrams > 0, saltPercent > 0 else { return 0 }
        return meatGrams * saltPercent / 100
    }

    static func naclRate(sodiumMilligrams: Double, referenceGrams: Double) -> Double {
        guard sodiumMilligrams > 0, referenceGrams > 0 else { return 0 }
        return sodiumMilligrams * sodiumToNaCl / 1000 / referenceGrams
    }

    static func naclContribution(grams: Double, sodiumMilligrams: Double, referenceGrams: Double) -> Double {
        grams * naclRate(sodiumMilligrams: sodiumMilligrams, referenceGrams: referenceGrams)
    }

    static func calculate(
        meatGrams: Double,
        saltPercent: Double,
        sweet: SauceInput,
        bean: SauceInput,
        soy: SauceInput
    ) -> SauceCalculation {
        let target = targetNaClGrams(meatGrams: meatGrams, saltPercent: saltPercent)
        let sweetNaCl = naclContribution(
            grams: sweet.grams,
            sodiumMilligrams: sweet.sodiumMilligrams,
            referenceGrams: sweet.referenceGrams
        )
        let beanNaCl = naclContribution(
            grams: bean.grams,
            sodiumMilligrams: bean.sodiumMilligrams,
            referenceGrams: bean.referenceGrams
        )
        let remaining = target - sweetNaCl - beanNaCl
        let soyRate = naclRate(sodiumMilligrams: soy.sodiumMilligrams, referenceGrams: soy.referenceGrams)
        let soyGrams = soyRate > 0 && remaining > 0 ? remaining / soyRate : 0
        let soyNaCl = naclContribution(
            grams: soyGrams,
            sodiumMilligrams: soy.sodiumMilligrams,
            referenceGrams: soy.referenceGrams
        )

        return SauceCalculation(
            targetNaClGrams: target,
            sweetNaClGrams: sweetNaCl,
            beanNaClGrams: beanNaCl,
            soyNaClGrams: soyNaCl,
            soyGrams: soyGrams
        )
    }

    static func trimmedManualGrams(
        _ grams: Double,
        sodiumMilligrams: Double,
        referenceGrams: Double,
        targetNaClGrams: Double
    ) -> Double {
        let rate = naclRate(sodiumMilligrams: sodiumMilligrams, referenceGrams: referenceGrams)
        guard rate > 0 else { return 0 }
        guard targetNaClGrams > 0 else { return min(max(0, grams), 100) }
        let maximum = max(20, targetNaClGrams / rate * 1.25)
        return min(max(0, grams), maximum)
    }
}
