import SwiftUI
import UIKit

private enum SauceID: String, CaseIterable, Identifiable {
    case sweet
    case bean
    case soy

    var id: String { rawValue }

    var name: String {
        switch self {
        case .sweet: "甜面酱"
        case .bean: "豆瓣酱"
        case .soy: "酱油"
        }
    }

    var color: Color {
        switch self {
        case .sweet: Color(red: 0.72, green: 0.20, blue: 0.16)
        case .bean: Color(red: 0.76, green: 0.39, blue: 0.09)
        case .soy: Color(red: 0.24, green: 0.31, blue: 0.55)
        }
    }
}

private struct SauceConfig: Codable, Equatable {
    var sodiumMilligrams: Double
    var referenceGrams: Double
}

private struct SavedSauceConfigs: Codable {
    var sweet: SauceConfig
    var bean: SauceConfig
    var soy: SauceConfig
}

struct ContentView: View {
    private let sodiumToNaCl = 2.542
    private let configKey = "beefSauceNaConfigV1"
    private let bg = Color(red: 0.97, green: 0.94, blue: 0.88)
    private let card = Color(red: 1.0, green: 0.985, blue: 0.95)
    private let field = Color.white
    private let ink = Color(red: 0.12, green: 0.08, blue: 0.05)
    private let subInk = Color(red: 0.36, green: 0.30, blue: 0.24)

    @State private var meatWeightText = "1000"
    @State private var saltPercentText = "4"
    @State private var configs: [SauceID: SauceConfig] = [
        .sweet: SauceConfig(sodiumMilligrams: 750, referenceGrams: 15),
        .bean: SauceConfig(sodiumMilligrams: 1100, referenceGrams: 15),
        .soy: SauceConfig(sodiumMilligrams: 900, referenceGrams: 15)
    ]
    @State private var sweetGrams = 0.0
    @State private var beanGrams = 0.0
    @State private var savedMessageVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                header
                baseSection
                sauceSection
                statusView
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 6)
        }
        .background(bg.ignoresSafeArea())
        .onAppear(perform: loadConfigs)
        .foregroundStyle(ink)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    dismissKeyboard()
                }
                .font(.system(size: 16, weight: .bold))
            }
        }
    }

    private var header: some View {
        HStack {
            Text("卤牛肉计算器")
                .font(.system(size: 25, weight: .heavy))
                .foregroundStyle(ink)
            Spacer()
            Text("Na × 2.542")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(subInk)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.65))
                .clipShape(Capsule())
        }
    }

    private var baseSection: some View {
        compactCard {
            VStack(spacing: 8) {
                HStack {
                    Text("基础用量")
                        .font(.system(size: 17, weight: .heavy))
                    Spacer()
                    Text("NaCl = 肉重 × %")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(subInk)
                }

                HStack(spacing: 8) {
                    numberField(title: "肉重", text: $meatWeightText, unit: "g")
                    numberField(title: "盐度", text: $saltPercentText, unit: "%")
                }

                HStack(spacing: 8) {
                    metricCard(title: "目标 NaCl", value: format(targetNaClGrams, digits: 2) + "g")
                    metricCard(title: "当前 NaCl", value: format(currentNaClGrams, digits: 2) + "g")
                }
            }
        }
    }

    private var sauceSection: some View {
        compactCard {
            VStack(spacing: 0) {
                HStack {
                    Text("酱料调配")
                        .font(.system(size: 17, weight: .heavy))
                    Spacer()
                    Button(action: saveConfigs) {
                        Text("保存配置")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                    }
                    .background(Color(red: 0.38, green: 0.25, blue: 0.14))
                    .clipShape(Capsule())
                }
                .padding(.bottom, 6)

                sauceRow(id: .sweet, grams: $sweetGrams, automatic: false)
                Divider().overlay(Color(red: 0.74, green: 0.67, blue: 0.57))
                sauceRow(id: .bean, grams: $beanGrams, automatic: false)
                Divider().overlay(Color(red: 0.74, green: 0.67, blue: 0.57))
                sauceRow(id: .soy, grams: .constant(soyGrams), automatic: true)
            }
        }
    }

    private var statusView: some View {
        let state = status
        return Text(state.message)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(state.warning ? Color(red: 0.62, green: 0.10, blue: 0.08) : Color(red: 0.12, green: 0.34, blue: 0.19))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(state.warning ? Color(red: 1.0, green: 0.90, blue: 0.87) : Color(red: 0.89, green: 0.95, blue: 0.87))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(state.warning ? Color(red: 0.88, green: 0.58, blue: 0.52) : Color(red: 0.67, green: 0.80, blue: 0.63))
            )
    }

    private func sauceRow(id: SauceID, grams: Binding<Double>, automatic: Bool) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 7) {
                Circle()
                    .fill(id.color)
                    .frame(width: 10, height: 10)
                Text(id.name)
                    .font(.system(size: 16, weight: .heavy))
                if automatic {
                    Text("自动")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(id.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(id.color.opacity(0.14))
                        .clipShape(Capsule())
                }
                Spacer()
                Text(format(grams.wrappedValue, digits: 1) + "g")
                    .font(.system(size: 21, weight: .heavy))
                    .foregroundStyle(id.color)
            }

            HStack(spacing: 6) {
                configField(id: id, title: "Na", keyPath: \.sodiumMilligrams, unit: "mg")
                Text("/")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(subInk)
                    .padding(.top, 14)
                configField(id: id, title: "重量", keyPath: \.referenceGrams, unit: "g")
            }

            HStack(spacing: 8) {
                Slider(
                    value: grams,
                    in: 0...max(20, sliderMaximum(for: id)),
                    step: 0.1
                )
                .tint(id.color)
                .disabled(automatic || !isValid(id) || targetNaClGrams <= 0)

                Text(format(naclContribution(id: id, grams: grams.wrappedValue), digits: 2) + "g")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(subInk)
                    .frame(width: 48, alignment: .trailing)
            }
        }
        .padding(.vertical, 8)
    }

    private func numberField(title: String, text: Binding<String>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(subInk)
            HStack(spacing: 4) {
                TextField("", text: text)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(ink)
                Text(unit)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(subInk)
            }
            .padding(.horizontal, 10)
            .frame(height: 42)
            .background(field)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.82, green: 0.74, blue: 0.63), lineWidth: 1.2))
        }
    }

    private func configField(
        id: SauceID,
        title: String,
        keyPath: WritableKeyPath<SauceConfig, Double>,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(subInk)
            HStack(spacing: 4) {
                TextField("", value: configBinding(id: id, keyPath: keyPath), format: .number)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(ink)
                Text(unit)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(subInk)
            }
            .padding(.horizontal, 9)
            .frame(height: 38)
            .background(field)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.82, green: 0.74, blue: 0.63), lineWidth: 1.1))
        }
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(subInk)
            Text(value)
                .font(.system(size: 25, weight: .heavy))
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(red: 1.0, green: 0.94, blue: 0.81))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.88, green: 0.74, blue: 0.52), lineWidth: 1.1))
    }

    private func compactCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(10)
            .background(card)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.82, green: 0.74, blue: 0.63), lineWidth: 1.1))
            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private var status: (message: String, warning: Bool) {
        if savedMessageVisible {
            return ("配置已保存到本机。", false)
        }
        if targetNaClGrams <= 0 {
            return ("请输入大于 0 的牛肉重量和目标盐度。", true)
        }
        if invalidSauces.count == SauceID.allCases.count {
            return ("至少填写一种有效酱料钠含量。", true)
        }
        if manualNaClGrams > targetNaClGrams + 0.005 {
            return ("甜面酱和豆瓣酱已超出目标，请减少。", true)
        }
        if !isValid(.soy) && manualNaClGrams < targetNaClGrams - 0.005 {
            return ("酱油钠含量无效，无法自动补足。", true)
        }
        if !invalidSauces.isEmpty {
            return (invalidSauces.map(\.name).joined(separator: "、") + " 钠含量无效。", false)
        }
        return ("酱油已自动补足目标 NaCl。", false)
    }

    private var targetNaClGrams: Double {
        let meat = parse(meatWeightText)
        let percent = parse(saltPercentText)
        guard meat > 0, percent > 0 else { return 0 }
        return meat * percent / 100
    }

    private var currentNaClGrams: Double {
        naclContribution(id: .sweet, grams: sweetGrams)
        + naclContribution(id: .bean, grams: beanGrams)
        + naclContribution(id: .soy, grams: soyGrams)
    }

    private var manualNaClGrams: Double {
        naclContribution(id: .sweet, grams: sweetGrams)
        + naclContribution(id: .bean, grams: beanGrams)
    }

    private var soyGrams: Double {
        guard isValid(.soy), targetNaClGrams > 0 else { return 0 }
        let remaining = targetNaClGrams - manualNaClGrams
        guard remaining > 0 else { return 0 }
        return remaining / naclRate(for: .soy)
    }

    private var invalidSauces: [SauceID] {
        SauceID.allCases.filter { !isValid($0) }
    }

    private func configBinding(id: SauceID, keyPath: WritableKeyPath<SauceConfig, Double>) -> Binding<Double> {
        Binding {
            configs[id, default: defaultConfig(for: id)][keyPath: keyPath]
        } set: { newValue in
            var config = configs[id, default: defaultConfig(for: id)]
            config[keyPath: keyPath] = max(0, newValue)
            configs[id] = config
            trimManualSliders()
        }
    }

    private func defaultConfig(for id: SauceID) -> SauceConfig {
        switch id {
        case .sweet: SauceConfig(sodiumMilligrams: 750, referenceGrams: 15)
        case .bean: SauceConfig(sodiumMilligrams: 1100, referenceGrams: 15)
        case .soy: SauceConfig(sodiumMilligrams: 900, referenceGrams: 15)
        }
    }

    private func isValid(_ id: SauceID) -> Bool {
        let config = configs[id, default: defaultConfig(for: id)]
        return config.sodiumMilligrams > 0 && config.referenceGrams > 0
    }

    private func naclRate(for id: SauceID) -> Double {
        let config = configs[id, default: defaultConfig(for: id)]
        guard config.sodiumMilligrams > 0, config.referenceGrams > 0 else { return 0 }
        return config.sodiumMilligrams * sodiumToNaCl / 1000 / config.referenceGrams
    }

    private func naclContribution(id: SauceID, grams: Double) -> Double {
        grams * naclRate(for: id)
    }

    private func sliderMaximum(for id: SauceID) -> Double {
        let rate = naclRate(for: id)
        guard targetNaClGrams > 0, rate > 0 else { return 100 }
        return max(20, targetNaClGrams / rate * 1.25)
    }

    private func trimManualSliders() {
        sweetGrams = min(max(0, sweetGrams), sliderMaximum(for: .sweet))
        beanGrams = min(max(0, beanGrams), sliderMaximum(for: .bean))
    }

    private func loadConfigs() {
        guard let data = UserDefaults.standard.data(forKey: configKey),
              let saved = try? JSONDecoder().decode(SavedSauceConfigs.self, from: data) else {
            return
        }
        configs[.sweet] = saved.sweet
        configs[.bean] = saved.bean
        configs[.soy] = saved.soy
        trimManualSliders()
    }

    private func saveConfigs() {
        dismissKeyboard()

        let saved = SavedSauceConfigs(
            sweet: configs[.sweet, default: defaultConfig(for: .sweet)],
            bean: configs[.bean, default: defaultConfig(for: .bean)],
            soy: configs[.soy, default: defaultConfig(for: .soy)]
        )
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: configKey)
        }

        savedMessageVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            savedMessageVisible = false
        }
    }

    private func parse(_ text: String) -> Double {
        Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func format(_ value: Double, digits: Int) -> String {
        value.formatted(.number.precision(.fractionLength(digits)))
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
