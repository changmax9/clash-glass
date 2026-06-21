import SwiftUI

public enum ApplicationDisclaimer {
    static let purpose =
        "Clash Glass is provided solely for lawful educational, academic, interoperability, and security research purposes."

    static let responsibility =
        "You are solely responsible for obtaining all required authorization and for complying with all applicable laws, regulations, licenses, network policies, and third-party terms. You must not use this software to gain unauthorized access, interfere with services, evade lawful restrictions, infringe rights, or facilitate unlawful activity."

    static let liability =
        "To the maximum extent permitted by applicable law, this software is provided \"as is\" and \"as available,\" without warranties of any kind. The developer and contributors are not liable for any direct, indirect, incidental, special, exemplary, punitive, or consequential loss, including loss of data, privacy, profits, service, accounts, devices, or network availability, arising from or related to the software or its use, even if advised of the possibility of such loss."

    static let thirdParties =
        "Mihomo, network providers, subscription providers, websites, and other third-party components or services are independent from Clash Glass. Their availability, security, content, conduct, and terms are outside the developer's control."

    static let indemnity =
        "To the maximum extent permitted by applicable law, you agree to defend, indemnify, and hold harmless the developer and contributors from claims, damages, penalties, liabilities, costs, and reasonable legal fees arising from your use, misuse, distribution, configuration, or violation of law or third-party rights."
}

public struct AppSettingsView: View {
    @Bindable private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    public init(store: AppStore) {
        self.store = store
    }

    public var body: some View {
        let palette = GlassPalette(colorScheme: colorScheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.text(.settings))
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                    Text(store.text(.settingsSubtitle))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                ForEach(SettingsPagePolicy.groups, id: \.self) { group in
                    settingsGroup(group)
                }
            }
            .padding(PageSurfaceMetrics.horizontalInset)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(palette.primaryText)
        .background(palette.background)
        .environment(\.locale, store.language.locale)
    }

    @ViewBuilder
    private func settingsGroup(_ group: SettingsGroupKind) -> some View {
        switch group {
        case .appearance:
            appearanceSettings
        case .language:
            languageSettings
        case .about:
            aboutSettings
        }
    }

    private var appearanceSettings: some View {
        SettingsGroup(title: store.text(.appearance), symbol: "paintbrush") {
            HStack {
                Text(store.text(.colorScheme))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Spacer()
                PillSegment(
                    values: AppAppearance.allCases,
                    selection: $store.appearanceMode
                ) { appearanceTitle($0) }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
        }
    }

    private var languageSettings: some View {
        SettingsGroup(title: store.text(.language), symbol: "globe") {
            HStack {
                Text(store.text(.language))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Spacer()
                Picker("", selection: $store.language) {
                    ForEach(AppLanguage.selectableCases) { language in
                        Text(language.nativeDisplayName)
                            .tag(language)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 190, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
        }
    }

    private var aboutSettings: some View {
        VStack(spacing: 14) {
            SettingsGroup(title: store.text(.about), symbol: "info.circle") {
                SettingsValueRow(title: store.text(.version), value: appVersion)
                SettingsValueRow(
                    title: store.text(.engine),
                    value: store.text(.poweredByMihomo)
                )
            }

            SettingsGroup(title: store.text(.legalNotice), symbol: "exclamationmark.shield") {
                SettingsLegalNotice(
                    title: store.text(.permittedUse),
                    text: store.text(.disclaimerPurpose)
                )
                SettingsLegalNotice(
                    title: store.text(.yourResponsibility),
                    text: store.text(.disclaimerResponsibility)
                )
                SettingsLegalNotice(
                    title: store.text(.noWarranty),
                    text: store.text(.disclaimerLiability)
                )
                SettingsLegalNotice(
                    title: store.text(.thirdPartyServices),
                    text: store.text(.disclaimerThirdParties)
                )
                SettingsLegalNotice(
                    title: store.text(.indemnification),
                    text: store.text(.disclaimerIndemnity)
                )
            }
        }
    }

    private func appearanceTitle(_ appearance: AppAppearance) -> String {
        switch appearance {
        case .system: store.text(.system)
        case .light: store.text(.light)
        case .dark: store.text(.dark)
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "Development"
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        GlassCard(radius: 16, padding: 0) {
            VStack(spacing: 0) {
                Label(title, systemImage: symbol)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                Divider().opacity(0.12)
                content
            }
        }
    }
}

private struct SettingsValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 18) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}

private struct SettingsLegalNotice: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}
