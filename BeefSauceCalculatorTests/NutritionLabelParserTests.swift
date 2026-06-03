import XCTest
@testable import BeefSauceCalculator

final class NutritionLabelParserTests: XCTestCase {
    func testParsesSodiumPerFifteenGrams() throws {
        let candidates = NutritionLabelParser.candidates(from: "钠 750mg 每15g")
        let candidate = try XCTUnwrap(candidates.first)

        XCTAssertEqual(candidate.sodiumMilligrams, 750, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(candidate.referenceGrams), 15, accuracy: 0.0001)
    }

    func testParsesSodiumPerHundredGrams() throws {
        let candidates = NutritionLabelParser.candidates(from: "每100g 钠 5200 毫克")
        let candidate = try XCTUnwrap(candidates.first)

        XCTAssertEqual(candidate.sodiumMilligrams, 5200, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(candidate.referenceGrams), 100, accuracy: 0.0001)
    }

    func testParsesTableStyleNutritionText() throws {
        let candidates = NutritionLabelParser.candidates(from: "项目 每100克 NRV%\n钠 750毫克 38%")
        let candidate = try XCTUnwrap(candidates.first)

        XCTAssertEqual(candidate.sodiumMilligrams, 750, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(candidate.referenceGrams), 100, accuracy: 0.0001)
    }

    func testParsesSplitColumnNutritionText() throws {
        let candidates = NutritionLabelParser.candidates(
            from: """
            营养成分表
            项目
            每份(15 g)
            营养素参考值%
            能量
            103 kJ
            1%
            蛋白质
            1.5 g
            3%
            脂肪
            0.2 g
            0%
            碳水化合物
            4.2 g
            1%
            钠
            531mg
            27%
            """
        )
        let candidate = try XCTUnwrap(candidates.first)

        XCTAssertEqual(candidate.sodiumMilligrams, 531, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(candidate.referenceGrams), 15, accuracy: 0.0001)
    }

    func testReturnsMultipleCandidatesWithoutChoosingForUser() {
        let candidates = NutritionLabelParser.candidates(
            from: """
            每15g 钠 750mg
            每100g 钠 5200mg
            """
        )

        XCTAssertEqual(candidates.count, 2)
        XCTAssertTrue(candidates.contains { $0.sodiumMilligrams == 750 && $0.referenceGrams == 15 })
        XCTAssertTrue(candidates.contains { $0.sodiumMilligrams == 5200 && $0.referenceGrams == 100 })
    }

    func testMissingReferenceRequiresUserCompletion() throws {
        let candidates = NutritionLabelParser.candidates(from: "钠 750mg")
        let candidate = try XCTUnwrap(candidates.first)

        XCTAssertEqual(candidate.sodiumMilligrams, 750, accuracy: 0.0001)
        XCTAssertNil(candidate.referenceGrams)
    }

    func testParsesCommonSodiumCharacterMisrecognition() throws {
        let candidates = NutritionLabelParser.candidates(from: "项目 每份(15g)\n纳\n531mg\n27%")
        let candidate = try XCTUnwrap(candidates.first)

        XCTAssertEqual(candidate.sodiumMilligrams, 531, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(candidate.referenceGrams), 15, accuracy: 0.0001)
    }

    func testFallsBackToSingleMilligramValueInNutritionTable() throws {
        let candidates = NutritionLabelParser.candidates(
            from: """
            营养成分表
            项目
            每份(15 g)
            能量
            103 kJ
            蛋白质
            1.5 g
            脂肪
            0.2 g
            碳水化合物
            4.2 g
            531mg
            27%
            """
        )
        let candidate = try XCTUnwrap(candidates.first)

        XCTAssertEqual(candidate.sodiumMilligrams, 531, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(candidate.referenceGrams), 15, accuracy: 0.0001)
    }
}
