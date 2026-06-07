import PhotosUI
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
        case .bean: "黄豆酱"
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

private struct OCRConfirmation: Identifiable {
    let id = UUID()
    var sauceID: SauceID
    var originalImage: UIImage
    var candidates: [NutritionLabelCandidate]
}

private enum AppTheme {
    static let bg = Color(red: 0.97, green: 0.94, blue: 0.88)
    static let card = Color(red: 1.0, green: 0.985, blue: 0.95)
    static let field = Color.white
    static let ink = Color(red: 0.12, green: 0.08, blue: 0.05)
    static let subInk = Color(red: 0.36, green: 0.30, blue: 0.24)
    static let brown = Color(red: 0.38, green: 0.25, blue: 0.14)
    static let border = Color(red: 0.82, green: 0.74, blue: 0.63)
    static let warmHighlight = Color(red: 1.0, green: 0.94, blue: 0.81)

    enum Radius {
        static let card: CGFloat = 16
        static let control: CGFloat = 14
    }
}

private struct MainLayoutMetrics {
    var outerSpacing: CGFloat
    var horizontalPadding: CGFloat
    var verticalPadding: CGFloat
    var sectionTitleFontSize: CGFloat
    var baseSpacing: CGFloat
    var rowSpacing: CGFloat
    var sauceRowVerticalPadding: CGFloat
    var sauceNameFontSize: CGFloat
    var sauceAmountFontSize: CGFloat
    var saveButtonHeight: CGFloat
    var saveButtonFontSize: CGFloat
    var scanButtonSize: CGSize
    var inputFieldHeight: CGFloat
    var numberFieldHeight: CGFloat
    var configFieldHeight: CGFloat
    var amountFieldHeight: CGFloat
    var cardPadding: CGFloat
    var cardShadowRadius: CGFloat
    var cardShadowY: CGFloat
    var statusFontSize: CGFloat
    var statusVerticalPadding: CGFloat
    var warningFontSize: CGFloat

    static let regular = MainLayoutMetrics(
        outerSpacing: 12,
        horizontalPadding: 14,
        verticalPadding: 14,
        sectionTitleFontSize: 17,
        baseSpacing: 10,
        rowSpacing: 7,
        sauceRowVerticalPadding: 9,
        sauceNameFontSize: 16,
        sauceAmountFontSize: 21,
        saveButtonHeight: 36,
        saveButtonFontSize: 13,
        scanButtonSize: CGSize(width: 34, height: 32),
        inputFieldHeight: 42,
        numberFieldHeight: 42,
        configFieldHeight: 42,
        amountFieldHeight: 42,
        cardPadding: 12,
        cardShadowRadius: 8,
        cardShadowY: 3,
        statusFontSize: 13,
        statusVerticalPadding: 8,
        warningFontSize: 12
    )
}

struct ContentView: View {
    private let configKey = "beefSauceNaConfigV1"
    private let bg = AppTheme.bg
    private let card = AppTheme.card
    private let field = AppTheme.field
    private let ink = AppTheme.ink
    private let subInk = AppTheme.subInk

    @State private var meatWeightText = "1000"
    @State private var saltPercentText = "4"
    @State private var configs: [SauceID: SauceConfig] = [
        .sweet: SauceConfig(sodiumMilligrams: 750, referenceGrams: 15),
        .bean: SauceConfig(sodiumMilligrams: 1100, referenceGrams: 15),
        .soy: SauceConfig(sodiumMilligrams: 900, referenceGrams: 15)
    ]
    @State private var sweetGramsText = "0"
    @State private var beanGramsText = "0"
    @State private var savedMessageVisible = false
    @State private var scanMessage: (text: String, warning: Bool)?
    @State private var pendingScanSauce: SauceID?
    @State private var sourceDialogVisible = false
    @State private var cameraPickerVisible = false
    @State private var photoPickerVisible = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var ocrConfirmation: OCRConfirmation?
    @State private var ocrCandidateIndex = 0
    @State private var ocrSodiumText = ""
    @State private var ocrReferenceText = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                mainContent(metrics: .regular)
            }
            .scrollDismissesKeyboard(.interactively)

            if sourceDialogVisible {
                Color.black.opacity(0.24)
                    .ignoresSafeArea()
                    .onTapGesture {
                        cancelOCRSourceOptions()
                    }

                OCRSourceDialog(
                    sauceName: pendingScanSauce?.name ?? "酱料",
                    cameraAvailable: UIImagePickerController.isSourceTypeAvailable(.camera),
                    onCamera: {
                        sourceDialogVisible = false
                        dismissKeyboard()
                        cameraPickerVisible = true
                    },
                    onPhoto: {
                        sourceDialogVisible = false
                        dismissKeyboard()
                        photoPickerVisible = true
                    },
                    onCancel: cancelOCRSourceOptions
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 6)
        }
        .background(bg.ignoresSafeArea())
        .onAppear(perform: loadConfigs)
        .foregroundStyle(ink)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    dismissKeyboard()
                }
                .font(.system(size: 16, weight: .bold))
            }
        }
        .animation(.easeOut(duration: 0.18), value: sourceDialogVisible)
        .sheet(isPresented: $cameraPickerVisible) {
            ImagePicker(sourceType: .camera) { image in
                recognizeNutritionLabel(from: image)
            }
            .ignoresSafeArea()
        }
        .photosPicker(
            isPresented: $photoPickerVisible,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, item in
            loadPhotoPickerItem(item)
        }
        .sheet(item: $ocrConfirmation) { confirmation in
            OCRConfirmationSheet(
                sauceID: confirmation.sauceID,
                sauceName: confirmation.sauceID.name,
                accentColor: confirmation.sauceID.color,
                candidates: confirmation.candidates,
                originalImage: confirmation.originalImage,
                selectedIndex: $ocrCandidateIndex,
                sodiumText: $ocrSodiumText,
                referenceText: $ocrReferenceText,
                onCandidateSelected: applyOCRCandidate,
                onCancel: {
                    ocrConfirmation = nil
                    pendingScanSauce = nil
                },
                onConfirm: {
                    applyOCRConfirmation(for: confirmation.sauceID)
                }
            )
        }
    }

    private func mainContent(metrics: MainLayoutMetrics) -> some View {
        VStack(spacing: metrics.outerSpacing) {
            baseSection(metrics: metrics)
            sauceSection(metrics: metrics)
            statusView(metrics: metrics)
        }
        .padding(.horizontal, metrics.horizontalPadding)
        .padding(.vertical, metrics.verticalPadding)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func baseSection(metrics: MainLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader(title: "基础用量", metrics: metrics)
            compactCard(metrics: metrics) {
                HStack(spacing: 8) {
                    numberField(title: "肉重", text: $meatWeightText, unit: "g", metrics: metrics)
                    numberField(title: "盐度", text: $saltPercentText, unit: "%", metrics: metrics)
                }
            }
        }
    }

    private func sauceSection(metrics: MainLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader(title: "酱料调配", metrics: metrics) {
                saveConfigButton(metrics: metrics)
            }
            compactCard(metrics: metrics) {
                VStack(spacing: 0) {
                    sauceRow(id: .sweet, gramsText: $sweetGramsText, automatic: false, metrics: metrics)
                    Divider().overlay(Color(red: 0.74, green: 0.67, blue: 0.57))
                    sauceRow(id: .bean, gramsText: $beanGramsText, automatic: false, metrics: metrics)
                    Divider().overlay(Color(red: 0.74, green: 0.67, blue: 0.57))
                    sauceRow(id: .soy, gramsText: nil, automatic: true, metrics: metrics)
                }
            }
        }
    }

    private func sectionHeader(title: String, metrics: MainLayoutMetrics) -> some View {
        sectionHeader(title: title, metrics: metrics) {
            EmptyView()
        }
    }

    private func sectionHeader<Content: View>(
        title: String,
        metrics: MainLayoutMetrics,
        @ViewBuilder trailing: () -> Content
    ) -> some View {
        HStack {
            Text(title)
                .font(.system(size: metrics.sectionTitleFontSize, weight: .heavy))
            Spacer()
            trailing()
        }
        .frame(maxWidth: .infinity)
    }

    private func saveConfigButton(metrics: MainLayoutMetrics) -> some View {
        Button(action: saveConfigs) {
            Label("保存配置", systemImage: "square.and.arrow.down")
                .font(.system(size: metrics.saveButtonFontSize, weight: .heavy))
                .foregroundStyle(AppTheme.brown)
                .padding(.horizontal, 10)
                .frame(height: metrics.saveButtonHeight)
        }
        .background(AppTheme.field)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1.1)
                .allowsHitTesting(false)
        )
        .accessibilityLabel("保存配置")
    }

    private func statusView(metrics: MainLayoutMetrics) -> some View {
        let state = status
        return Text(state.message)
            .font(.system(size: metrics.statusFontSize, weight: .bold))
            .foregroundStyle(state.warning ? Color(red: 0.62, green: 0.10, blue: 0.08) : Color(red: 0.12, green: 0.34, blue: 0.19))
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
            .truncationMode(.tail)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 10)
            .padding(.vertical, metrics.statusVerticalPadding)
            .background(state.warning ? Color(red: 1.0, green: 0.90, blue: 0.87) : Color(red: 0.89, green: 0.95, blue: 0.87))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .stroke(state.warning ? Color(red: 0.88, green: 0.58, blue: 0.52) : Color(red: 0.67, green: 0.80, blue: 0.63))
                    .allowsHitTesting(false)
            )
    }

    @ViewBuilder
    private func sauceRow(id: SauceID, gramsText: Binding<String>?, automatic: Bool, metrics: MainLayoutMetrics) -> some View {
        let gramsValue = automatic ? soyGrams : parseAmount(gramsText?.wrappedValue ?? "")

        VStack(spacing: metrics.rowSpacing) {
            HStack(spacing: 7) {
                Circle()
                    .fill(id.color)
                    .frame(width: 10, height: 10)
                Text(id.name)
                    .font(.system(size: metrics.sauceNameFontSize, weight: .heavy))
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
                Button {
                    presentOCRSourceOptions(for: id)
                } label: {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(AppTheme.brown)
                        .frame(width: metrics.scanButtonSize.width, height: metrics.scanButtonSize.height)
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1.0)
                                .allowsHitTesting(false)
                        )
                }
                .accessibilityLabel("扫描\(id.name)钠含量")

                Text(format(gramsValue, digits: 1) + usageUnit(for: id))
                    .font(.system(size: metrics.sauceAmountFontSize, weight: .heavy))
                    .foregroundStyle(id.color)
            }

            HStack(spacing: 6) {
                configField(id: id, title: "Na", keyPath: \.sodiumMilligrams, unit: "mg", metrics: metrics)
                Text("/")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(subInk)
                    .padding(.top, 14)
                configField(id: id, title: referenceTitle(for: id), keyPath: \.referenceGrams, unit: usageUnit(for: id), metrics: metrics)
            }

            if shouldReviewNutritionData(for: id) {
                reviewWarningText(metrics: metrics)
            }

            if let gramsText {
                amountField(title: "用量", text: gramsText, unit: usageUnit(for: id), metrics: metrics)
            } else {
                Text("自动补足")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(subInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .frame(height: metrics.inputFieldHeight)
                    .background(AppTheme.field)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1.0)
                            .allowsHitTesting(false)
                    )
            }
        }
        .padding(.vertical, metrics.sauceRowVerticalPadding)
    }

    private func usageUnit(for id: SauceID) -> String {
        id == .soy ? "mL" : "g"
    }

    private func referenceTitle(for id: SauceID) -> String {
        id == .soy ? "容量" : "重量"
    }

    private func numberField(title: String, text: Binding<String>, unit: String, metrics: MainLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(subInk)
            HStack(spacing: 4) {
                TextField("", text: text)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(ink)
                    .accessibilityLabel(title)
                Text(unit)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(subInk)
            }
            .padding(.horizontal, 10)
            .frame(height: metrics.inputFieldHeight)
            .background(field)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control)
                    .stroke(Color(red: 0.82, green: 0.74, blue: 0.63), lineWidth: 1.2)
                    .allowsHitTesting(false)
            )
        }
    }

    private func configField(
        id: SauceID,
        title: String,
        keyPath: WritableKeyPath<SauceConfig, Double>,
        unit: String,
        metrics: MainLayoutMetrics
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
                    .accessibilityLabel("\(id.name) \(title)")
                Text(unit)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(subInk)
            }
            .padding(.horizontal, 9)
            .frame(height: metrics.inputFieldHeight)
            .background(field)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control)
                    .stroke(Color(red: 0.82, green: 0.74, blue: 0.63), lineWidth: 1.1)
                    .allowsHitTesting(false)
            )
        }
    }

    private func amountField(title: String, text: Binding<String>, unit: String, metrics: MainLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(subInk)
            HStack(spacing: 4) {
                TextField("", text: text)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(ink)
                    .accessibilityLabel(title)
                Text(unit)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(subInk)
            }
            .padding(.horizontal, 9)
            .frame(height: metrics.inputFieldHeight)
            .background(field)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control)
                    .stroke(AppTheme.border, lineWidth: 1.1)
                    .allowsHitTesting(false)
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func reviewWarningText(metrics: MainLayoutMetrics) -> some View {
        Text("数值偏高，请复核标签")
            .font(.system(size: metrics.warningFontSize, weight: .bold))
            .foregroundStyle(Color(red: 0.62, green: 0.10, blue: 0.08))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactCard<Content: View>(metrics: MainLayoutMetrics, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(metrics.cardPadding)
            .background(card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(Color(red: 0.82, green: 0.74, blue: 0.63), lineWidth: 1.1)
                    .allowsHitTesting(false)
            )
            .shadow(color: Color.black.opacity(0.04), radius: metrics.cardShadowRadius, y: metrics.cardShadowY)
    }

    private var status: (message: String, warning: Bool) {
        if let scanMessage {
            return (scanMessage.text, scanMessage.warning)
        }
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
            return ("甜面酱和黄豆酱已超出目标，请减少。", true)
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
        SauceCalculator.targetNaClGrams(meatGrams: parse(meatWeightText), saltPercent: parse(saltPercentText))
    }

    private var currentNaClGrams: Double {
        currentCalculation.currentNaClGrams
    }

    private var manualNaClGrams: Double {
        currentCalculation.manualNaClGrams
    }

    private var soyGrams: Double {
        currentCalculation.soyGrams
    }

    private var currentCalculation: SauceCalculation {
        SauceCalculator.calculate(
            meatGrams: parse(meatWeightText),
            saltPercent: parse(saltPercentText),
            sweet: sauceInput(for: .sweet, grams: parseAmount(sweetGramsText)),
            bean: sauceInput(for: .bean, grams: parseAmount(beanGramsText)),
            soy: sauceInput(for: .soy, grams: 0)
        )
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

    private func shouldReviewNutritionData(for id: SauceID) -> Bool {
        let config = configs[id, default: defaultConfig(for: id)]
        return SauceCalculator.shouldReviewNutritionData(
            sodiumMilligrams: config.sodiumMilligrams,
            referenceGrams: config.referenceGrams
        )
    }

    private func sauceInput(for id: SauceID, grams: Double) -> SauceInput {
        let config = configs[id, default: defaultConfig(for: id)]
        return SauceInput(
            sodiumMilligrams: config.sodiumMilligrams,
            referenceGrams: config.referenceGrams,
            grams: grams
        )
    }

    private func loadConfigs() {
        guard let data = UserDefaults.standard.data(forKey: configKey),
              let saved = try? JSONDecoder().decode(SavedSauceConfigs.self, from: data) else {
            return
        }
        configs[.sweet] = saved.sweet
        configs[.bean] = saved.bean
        configs[.soy] = saved.soy
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

    private func presentOCRSourceOptions(for id: SauceID) {
        pendingScanSauce = id
        scanMessage = nil
        sourceDialogVisible = true
    }

    private func cancelOCRSourceOptions() {
        sourceDialogVisible = false
        pendingScanSauce = nil
    }

    private func loadPhotoPickerItem(_ item: PhotosPickerItem?) {
        guard let item else { return }
        selectedPhotoItem = nil
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                await MainActor.run {
                    scanMessage = ("无法读取这张图片。", true)
                }
                return
            }
            await MainActor.run {
                recognizeNutritionLabel(from: image)
            }
        }
    }

    private func recognizeNutritionLabel(from image: UIImage) {
        guard pendingScanSauce != nil else { return }
        scanMessage = ("正在识别营养成分表...", false)

        Task {
            do {
                let lines = try await NutritionOCRService.recognizeText(from: image)
                await MainActor.run {
                    handleRecognizedText(lines, from: image)
                }
            } catch {
                await MainActor.run {
                    scanMessage = ("OCR 识别失败，请换一张更清晰的照片。", true)
                }
            }
        }
    }

    private func handleRecognizedText(_ lines: [String], from image: UIImage) {
        let text = lines.joined(separator: "\n")
        let candidates = NutritionLabelParser.candidates(from: text)
        guard let sauce = pendingScanSauce, !candidates.isEmpty else {
            scanMessage = ("未识别到钠含量，请对准营养成分表重拍。", true)
            return
        }

        ocrCandidateIndex = 0
        applyOCRCandidate(candidates[0])
        ocrConfirmation = OCRConfirmation(
            sauceID: sauce,
            originalImage: image,
            candidates: candidates
        )
        scanMessage = nil
    }

    private func applyOCRCandidate(_ candidate: NutritionLabelCandidate) {
        ocrSodiumText = formatInput(candidate.sodiumMilligrams)
        ocrReferenceText = candidate.referenceGrams.map(formatInput) ?? ""
    }

    private func applyOCRConfirmation(for id: SauceID) {
        let sodium = parse(ocrSodiumText)
        let reference = parse(ocrReferenceText)
        guard sodium > 0, reference > 0 else {
            scanMessage = ("请补全 Na mg 和对应\(referenceTitle(for: id)) \(usageUnit(for: id))。", true)
            return
        }

        configs[id] = SauceConfig(sodiumMilligrams: sodium, referenceGrams: reference)
        ocrConfirmation = nil
        pendingScanSauce = nil
        scanMessage = ("已填入\(id.name)钠配置，点击保存配置后会保存在本机。", false)
    }

    private func parse(_ text: String) -> Double {
        NumberText.parse(text) ?? 0
    }

    private func parseAmount(_ text: String) -> Double {
        max(0, parse(text))
    }

    private func format(_ value: Double, digits: Int) -> String {
        value.formatted(.number.precision(.fractionLength(digits)))
    }

    private func formatInput(_ value: Double) -> String {
        NumberText.formatInput(value)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

}

private struct OCRSourceDialog: View {
    var sauceName: String
    var cameraAvailable: Bool
    var onCamera: () -> Void
    var onPhoto: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("识别钠含量")
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundStyle(AppTheme.ink)
                    Text("选择\(sauceName)包装照片来源")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.subInk)
                }
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(AppTheme.brown)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1.0)
                                .allowsHitTesting(false)
                        )
                }
                .accessibilityLabel("取消")
            }

            if cameraAvailable {
                sourceButton(title: "拍照", systemImage: "camera.fill", action: onCamera)
            }
            sourceButton(title: "从相册选择", systemImage: "photo.on.rectangle.angled", action: onPhoto)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1.2)
                .allowsHitTesting(false)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 16, y: 6)
    }

    private func sourceButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .heavy))
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 16, weight: .heavy))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .heavy))
            }
            .foregroundStyle(AppTheme.brown)
            .padding(.horizontal, 13)
            .frame(height: 48)
            .background(AppTheme.field)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1.1)
                    .allowsHitTesting(false)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct OCRConfirmationSheet: View {
    var sauceID: SauceID
    var sauceName: String
    var accentColor: Color
    var candidates: [NutritionLabelCandidate]
    var originalImage: UIImage
    @Binding var selectedIndex: Int
    @Binding var sodiumText: String
    @Binding var referenceText: String
    var onCandidateSelected: (NutritionLabelCandidate) -> Void
    var onCancel: () -> Void
    var onConfirm: () -> Void

    @State private var imageViewerVisible = false

    var body: some View {
        GeometryReader { proxy in
            let topMaxHeight = min(320, proxy.size.height * 0.36)

            VStack(alignment: .leading, spacing: 8) {
                confirmationHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("选择识别结果")
                            ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                                candidateButton(index: index, candidate: candidate)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionTitle("确认后填入\(sauceName)")
                            HStack(spacing: 8) {
                                editableField(title: "Na", text: $sodiumText, unit: "mg")
                                Text("/")
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundStyle(AppTheme.subInk)
                                    .padding(.top, 18)
                                editableField(title: referenceTitle, text: $referenceText, unit: referenceUnit)
                            }
                            if shouldReviewNutritionData {
                                Text("数值偏高，请复核标签")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(red: 0.62, green: 0.10, blue: 0.08))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 2)
                }
                .frame(maxHeight: topMaxHeight)

                VStack(alignment: .leading, spacing: 6) {
                    sectionTitle("原图")
                    Button {
                        imageViewerVisible = true
                    } label: {
                        GeometryReader { imageProxy in
                            Image(uiImage: originalImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: imageProxy.size.width, height: imageProxy.size.height)
                                .clipped()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                                .stroke(accentColor.opacity(0.75), lineWidth: 1.3)
                                .allowsHitTesting(false)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("查看原图大图")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            .background(AppTheme.bg.ignoresSafeArea())
        }
        .fullScreenCover(isPresented: $imageViewerVisible) {
            OriginalImageViewer(image: originalImage)
        }
    }

    private var confirmationHeader: some View {
        HStack(spacing: 10) {
            Button("取消", action: onCancel)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(AppTheme.brown)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(AppTheme.field)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1.1)
                        .allowsHitTesting(false)
                )

            Spacer()

            Button("填入", action: onConfirm)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(canConfirm ? AppTheme.field : AppTheme.subInk.opacity(0.55))
                .padding(.horizontal, 16)
                .frame(height: 38)
                .background(canConfirm ? accentColor : AppTheme.field.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                        .stroke(canConfirm ? accentColor : AppTheme.border, lineWidth: 1.1)
                        .allowsHitTesting(false)
                )
                .disabled(!canConfirm)
        }
        .overlay {
            Text("确认钠含量")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(AppTheme.ink)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
    }

    private func sectionTitle(_ title: String) -> some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accentColor)
                .frame(width: 4, height: 18)
            Text(title)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(AppTheme.ink)
        }
    }

    private func candidateButton(index: Int, candidate: NutritionLabelCandidate) -> some View {
        Button {
            selectedIndex = index
            onCandidateSelected(candidate)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(candidate.sodiumMilligrams.formatted(.number.precision(.fractionLength(0...2)))) mg / \(candidateReferenceText(candidate))")
                        .font(.system(size: 16, weight: .heavy))
                    Text(candidate.sourceText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.subInk)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: selectedIndex == index ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(selectedIndex == index ? accentColor : AppTheme.border)
            }
            .foregroundStyle(AppTheme.ink)
            .padding(10)
            .background(selectedIndex == index ? accentColor.opacity(0.14) : AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .stroke(selectedIndex == index ? accentColor : AppTheme.border, lineWidth: 1.1)
                    .allowsHitTesting(false)
            )
        }
        .buttonStyle(.plain)
    }

    private var canConfirm: Bool {
        parsedPositiveDouble(sodiumText) != nil && parsedPositiveDouble(referenceText) != nil
    }

    private var shouldReviewNutritionData: Bool {
        guard let sodium = NumberText.parse(sodiumText),
              let reference = NumberText.parse(referenceText) else {
            return false
        }
        return SauceCalculator.shouldReviewNutritionData(
            sodiumMilligrams: sodium,
            referenceGrams: reference
        )
    }

    private var referenceTitle: String {
        sauceID == .soy ? "容量" : "重量"
    }

    private var referenceUnit: String {
        sauceID == .soy ? "mL" : "g"
    }

    private func candidateReferenceText(_ candidate: NutritionLabelCandidate) -> String {
        if let reference = candidate.referenceGrams {
            return reference.formatted(.number.precision(.fractionLength(0...2))) + " " + referenceUnit
        }
        return "需补\(referenceTitle)"
    }

    private func parsedPositiveDouble(_ text: String) -> Double? {
        let value = NumberText.parse(text)
        guard let value, value > 0 else { return nil }
        return value
    }

    private func editableField(title: String, text: Binding<String>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.subInk)
            HStack(spacing: 4) {
                TextField("", text: text)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                    .accessibilityLabel(title)
                Text(unit)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.subInk)
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
            .background(AppTheme.field)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .stroke(accentColor.opacity(0.55), lineWidth: 1.1)
                    .allowsHitTesting(false)
            )
        }
    }

}

private struct OriginalImageViewer: View {
    var image: UIImage

    @Environment(\.dismiss) private var dismiss
    @State private var scale = 1.0
    @State private var lastScale = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = min(max(lastScale * value, 1), 5)
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale == 1 {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                guard scale > 1 else { return }
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        if scale > 1 {
                            scale = 1
                            lastScale = 1
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.5
                            lastScale = 2.5
                        }
                    }
                    .padding()
            }
            .navigationTitle("原图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
