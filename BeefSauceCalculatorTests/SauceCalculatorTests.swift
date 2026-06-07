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

    func testNutritionDataReviewWarningUsesWideThresholds() {
        XCTAssertTrue(
            SauceCalculator.shouldReviewNutritionData(sodiumMilligrams: 5000.1, referenceGrams: 15)
        )
        XCTAssertTrue(
            SauceCalculator.shouldReviewNutritionData(sodiumMilligrams: 900, referenceGrams: 100.1)
        )
        XCTAssertFalse(
            SauceCalculator.shouldReviewNutritionData(sodiumMilligrams: 5000, referenceGrams: 100)
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

    func testNumberTextFormatsInputWithoutGroupingSeparator() {
        XCTAssertEqual(NumberText.formatInput(3900), "3900")
        XCTAssertEqual(NumberText.formatInput(3900.125), "3900.12")
    }

    func testNumberTextParsesThousandsAndDecimalCommas() throws {
        XCTAssertEqual(try XCTUnwrap(NumberText.parse("3,900")), 3900, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(NumberText.parse("3,9")), 3.9, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(NumberText.parse("3900")), 3900, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(NumberText.parse("1,234.56")), 1234.56, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(NumberText.parse("3.900")), 3.9, accuracy: 0.0001)
    }
}
