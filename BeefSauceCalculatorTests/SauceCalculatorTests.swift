import XCTest
@testable import BeefSauceCalculator

final class SauceCalculatorTests: XCTestCase {
    func testTargetNaClUsesMeatWeightAndSaltPercent() {
        XCTAssertEqual(
            SauceCalculator.targetNaClGrams(meatGrams: 1000, saltPercent: 4),
            40,
            accuracy: 0.0001
        )
    }

    func testSodiumRateConvertsNaToNaCl() {
        XCTAssertEqual(
            SauceCalculator.naclRate(sodiumMilligrams: 750, referenceGrams: 15),
            750 * 2.542 / 1000 / 15,
            accuracy: 0.0001
        )
    }

    func testSoyAutomaticallyFillsRemainingNaCl() {
        let result = SauceCalculator.calculate(
            meatGrams: 1000,
            saltPercent: 4,
            sweet: SauceInput(sodiumMilligrams: 750, referenceGrams: 15, grams: 30),
            bean: SauceInput(sodiumMilligrams: 1100, referenceGrams: 15, grams: 20),
            soy: SauceInput(sodiumMilligrams: 900, referenceGrams: 15, grams: 0)
        )

        XCTAssertEqual(result.targetNaClGrams, 40, accuracy: 0.0001)
        XCTAssertEqual(result.currentNaClGrams, 40, accuracy: 0.0001)
        XCTAssertGreaterThan(result.soyGrams, 0)
    }

    func testSoyIsZeroWhenManualSaucesExceedTarget() {
        let result = SauceCalculator.calculate(
            meatGrams: 1000,
            saltPercent: 4,
            sweet: SauceInput(sodiumMilligrams: 750, referenceGrams: 15, grams: 200),
            bean: SauceInput(sodiumMilligrams: 1100, referenceGrams: 15, grams: 200),
            soy: SauceInput(sodiumMilligrams: 900, referenceGrams: 15, grams: 0)
        )

        XCTAssertEqual(result.soyGrams, 0, accuracy: 0.0001)
        XCTAssertGreaterThan(result.currentNaClGrams, result.targetNaClGrams)
    }

    func testInvalidSauceHasZeroContribution() {
        XCTAssertEqual(
            SauceCalculator.naclContribution(grams: 50, sodiumMilligrams: 0, referenceGrams: 15),
            0,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            SauceCalculator.naclContribution(grams: 50, sodiumMilligrams: 750, referenceGrams: 0),
            0,
            accuracy: 0.0001
        )
    }

    func testInvalidManualSauceTrimsToZero() {
        XCTAssertEqual(
            SauceCalculator.trimmedManualGrams(
                50,
                sodiumMilligrams: 0,
                referenceGrams: 15,
                targetNaClGrams: 40
            ),
            0,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            SauceCalculator.trimmedManualGrams(
                50,
                sodiumMilligrams: 750,
                referenceGrams: 0,
                targetNaClGrams: 40
            ),
            0,
            accuracy: 0.0001
        )
    }
}
