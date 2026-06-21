import Foundation

public enum AppString: String, CaseIterable, Sendable {
    case settings
    case settingsSubtitle
    case appearance
    case colorScheme
    case system
    case light
    case dark
    case language
    case systemDefault
    case about
    case version
    case engine
    case legalNotice
    case permittedUse
    case yourResponsibility
    case noWarranty
    case thirdPartyServices
    case indemnification
    case disclaimerPurpose
    case disclaimerResponsibility
    case disclaimerLiability
    case disclaimerThirdParties
    case disclaimerIndemnity
    case update
    case dashboard
    case proxies
    case routing
    case profiles
    case requests
    case connections
    case resources
    case logs
    case coreStatus
    case quickEdit
    case cancel
    case confirm
    case restartCore
    case startCore
    case renameProfile
    case profileName
    case rename
    case systemProxy
    case networkSpeed
    case networkDetection
    case outboundMode
    case trafficUsage
    case intranetIP
    case options
    case rule
    case global
    case direct
    case upload
    case download
    case search
    case closeAll
    case refresh
    case noConnections
    case host
    case chain
    case closeConnection
    case stopAutoScroll
    case scrollToTop
    case noRequests
    case reload
    case openFolder
    case ready
    case clear
    case export
    case noLogs
    case stopped
    case connected
    case coreRunning
    case nodes
    case noProxyNodes
    case validateAll
    case openManagedFolder
    case importYAML
    case importConfiguration
    case noMatchingProfiles
    case deleteProfile
    case managedYAML
    case running
    case current
    case managed
    case selected
    case use
    case validate
    case revealInFinder
    case delete
    case delayTest
    case providers
    case automatic
    case collapse
    case expand
    case addRule
    case saving
    case domainRouting
    case deleteRule
    case noMatchingRoutingRules
    case addDomainHint
    case start
    case pause
}

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case french = "fr"
    case russian = "ru"
    case spanish = "es"
    case portuguese = "pt"

    public var id: Self { self }

    public static let selectableCases: [Self] = [
        .system,
        .english,
        .simplifiedChinese,
        .traditionalChinese,
        .japanese,
        .french,
        .russian,
        .spanish,
        .portuguese,
    ]

    public var locale: Locale {
        self == .system ? .autoupdatingCurrent : Locale(identifier: rawValue)
    }

    public var nativeDisplayName: String {
        switch self {
        case .system: text(.systemDefault)
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        case .japanese: "日本語"
        case .french: "Français"
        case .russian: "Русский"
        case .spanish: "Español"
        case .portuguese: "Português"
        }
    }

    public func text(_ key: AppString) -> String {
        AppLocalization.text(key, language: resolvedLanguage)
    }

    private var resolvedLanguage: Self {
        guard self == .system else {
            return self
        }
        let identifier = Locale.autoupdatingCurrent.identifier.lowercased()
        if identifier.hasPrefix("zh") {
            return identifier.contains("hant")
                || identifier.contains("_tw")
                || identifier.contains("_hk")
                || identifier.contains("_mo")
                ? .traditionalChinese
                : .simplifiedChinese
        }
        if identifier.hasPrefix("ja") { return .japanese }
        if identifier.hasPrefix("fr") { return .french }
        if identifier.hasPrefix("ru") { return .russian }
        if identifier.hasPrefix("es") { return .spanish }
        if identifier.hasPrefix("pt") { return .portuguese }
        return .english
    }
}

enum AppLocalization {
    static func text(_ key: AppString, language: AppLanguage) -> String {
        translations[language]?[key] ?? translations[.english]![key]!
    }

    static func hasTranslation(_ key: AppString, language: AppLanguage) -> Bool {
        translations[language]?[key] != nil
    }

    private static let translations: [AppLanguage: [AppString: String]] = [
        .english: [
            .settings: "Settings",
            .settingsSubtitle: "Personalize Clash Glass and review application information.",
            .appearance: "Appearance",
            .colorScheme: "Color Scheme",
            .system: "System",
            .light: "Light",
            .dark: "Dark",
            .language: "Language",
            .systemDefault: "System Default",
            .about: "About",
            .version: "Version",
            .engine: "Engine",
            .legalNotice: "Legal Notice",
            .permittedUse: "Permitted Use",
            .yourResponsibility: "Your Responsibility",
            .noWarranty: "No Warranty and Limitation of Liability",
            .thirdPartyServices: "Third-Party Services",
            .indemnification: "Indemnification",
            .disclaimerPurpose: ApplicationDisclaimer.purpose,
            .disclaimerResponsibility: ApplicationDisclaimer.responsibility,
            .disclaimerLiability: ApplicationDisclaimer.liability,
            .disclaimerThirdParties: ApplicationDisclaimer.thirdParties,
            .disclaimerIndemnity: ApplicationDisclaimer.indemnity,
            .update: "Update",
            .dashboard: "Dashboard",
            .proxies: "Proxies",
            .routing: "Routing",
            .profiles: "Profiles",
            .requests: "Requests",
            .connections: "Connections",
            .resources: "Resources",
            .logs: "Logs",
            .coreStatus: "Core Status",
            .quickEdit: "Quick Edit",
            .cancel: "Cancel",
            .confirm: "Confirm",
            .restartCore: "Restart Core",
            .startCore: "Start Core",
            .renameProfile: "Rename Profile",
            .profileName: "Profile Name",
            .rename: "Rename",
            .systemProxy: "System Proxy",
            .networkSpeed: "Network Speed",
            .networkDetection: "Network Detection",
            .outboundMode: "Outbound Mode",
            .trafficUsage: "Traffic Usage",
            .intranetIP: "Intranet IP",
            .options: "Options",
            .rule: "Rule",
            .global: "Global",
            .direct: "Direct",
            .upload: "Upload",
            .download: "Download",
            .search: "Search", .closeAll: "Close All", .refresh: "Refresh",
            .noConnections: "No Connections", .host: "Host", .chain: "Chain",
            .closeConnection: "Close Connection", .stopAutoScroll: "Stop Auto Scroll",
            .scrollToTop: "Scroll to Top", .noRequests: "No Requests", .reload: "Reload",
            .openFolder: "Open Folder", .ready: "Ready", .clear: "Clear", .export: "Export",
            .noLogs: "No Logs", .stopped: "Stopped", .connected: "Connected",
            .coreRunning: "Core Running", .nodes: "nodes", .noProxyNodes: "No Proxy Nodes Available",
            .validateAll: "Validate All", .openManagedFolder: "Open Managed Folder",
            .importYAML: "Import YAML", .importConfiguration: "Import Configuration",
            .noMatchingProfiles: "No Matching Profiles", .deleteProfile: "Delete Profile",
            .managedYAML: "Managed YAML", .running: "Running", .current: "Current",
            .managed: "Managed", .selected: "Selected", .use: "Use", .validate: "Validate",
            .revealInFinder: "Reveal in Finder", .delete: "Delete", .delayTest: "Delay Test",
            .providers: "Providers", .automatic: "Automatic", .collapse: "Collapse",
            .expand: "Expand", .addRule: "Add Rule", .saving: "Saving",
            .domainRouting: "Domain Routing", .deleteRule: "Delete Rule",
            .noMatchingRoutingRules: "No Matching Routing Rules",
            .addDomainHint: "Add a domain to choose VPN or Direct routing",
            .start: "Start", .pause: "Pause",
        ],
        .simplifiedChinese: [
            .settings: "设置", .settingsSubtitle: "个性化 Clash Glass 并查看应用信息。",
            .appearance: "外观", .colorScheme: "配色方案", .system: "跟随系统",
            .light: "浅色", .dark: "深色", .language: "语言", .systemDefault: "系统默认",
            .about: "关于", .version: "版本", .engine: "核心", .legalNotice: "法律声明",
            .permittedUse: "允许用途", .yourResponsibility: "您的责任",
            .noWarranty: "无担保与责任限制", .thirdPartyServices: "第三方服务",
            .indemnification: "赔偿责任",
            .disclaimerPurpose: "Clash Glass 仅供合法的教育、学术、互操作性及安全研究用途。",
            .disclaimerResponsibility: "您有责任取得所有必要授权，并遵守适用的法律、法规、许可、网络政策及第三方条款。不得使用本软件进行未经授权的访问、干扰服务、规避合法限制、侵犯权利或协助违法活动。",
            .disclaimerLiability: "在适用法律允许的最大范围内，本软件按“现状”和“可用状态”提供，不作任何担保。开发者及贡献者不对因本软件或其使用产生的任何直接、间接、附带、特殊、惩罚性或后果性损失承担责任，包括数据、隐私、利润、服务、账户、设备或网络可用性的损失。",
            .disclaimerThirdParties: "Mihomo、网络服务商、订阅服务商、网站及其他第三方组件或服务均独立于 Clash Glass，其可用性、安全性、内容、行为及条款不受开发者控制。",
            .disclaimerIndemnity: "在适用法律允许的最大范围内，您同意就因您的使用、误用、分发、配置或违反法律及第三方权利而产生的索赔、损害、处罚、责任、费用及合理法律费用，为开发者及贡献者进行抗辩、赔偿并使其免受损害。",
            .update: "更新", .dashboard: "仪表盘", .proxies: "代理", .routing: "路由",
            .profiles: "配置", .requests: "请求", .connections: "连接", .resources: "资源",
            .logs: "日志", .coreStatus: "核心状态", .quickEdit: "快速编辑",
            .cancel: "取消", .confirm: "确认", .restartCore: "重启核心", .startCore: "启动核心",
            .renameProfile: "重命名配置", .profileName: "配置名称", .rename: "重命名",
            .systemProxy: "系统代理", .networkSpeed: "网络速度",
            .networkDetection: "网络检测", .outboundMode: "出站模式",
            .trafficUsage: "流量使用", .intranetIP: "内网 IP", .options: "选项",
            .rule: "规则", .global: "全局", .direct: "直连", .upload: "上传", .download: "下载",
            .search: "搜索", .closeAll: "全部关闭", .refresh: "刷新", .noConnections: "暂无连接",
            .host: "主机", .chain: "链路", .closeConnection: "关闭连接",
            .stopAutoScroll: "停止自动滚动", .scrollToTop: "滚动到顶部", .noRequests: "暂无请求",
            .reload: "重新加载", .openFolder: "打开文件夹", .ready: "就绪", .clear: "清空",
            .export: "导出", .noLogs: "暂无日志", .stopped: "已停止", .connected: "已连接",
            .coreRunning: "核心运行中", .nodes: "个节点", .noProxyNodes: "没有可用代理节点",
            .validateAll: "全部验证", .openManagedFolder: "打开托管文件夹", .importYAML: "导入 YAML",
            .importConfiguration: "导入配置", .noMatchingProfiles: "没有匹配的配置",
            .deleteProfile: "删除配置", .managedYAML: "托管 YAML", .running: "运行中",
            .current: "当前", .managed: "已托管", .selected: "已选择", .use: "使用",
            .validate: "验证", .revealInFinder: "在访达中显示", .delete: "删除",
            .delayTest: "延迟测试", .providers: "提供商", .automatic: "自动",
            .collapse: "收起", .expand: "展开", .addRule: "添加规则", .saving: "保存中",
            .domainRouting: "域名路由", .deleteRule: "删除规则",
            .noMatchingRoutingRules: "没有匹配的路由规则",
            .addDomainHint: "添加域名并选择通过 VPN 或直连",
            .start: "启动", .pause: "暂停",
        ],
        .traditionalChinese: [
            .settings: "設定", .settingsSubtitle: "個人化 Clash Glass 並檢視應用程式資訊。",
            .appearance: "外觀", .colorScheme: "配色方案", .system: "跟隨系統",
            .light: "淺色", .dark: "深色", .language: "語言", .systemDefault: "系統預設",
            .about: "關於", .version: "版本", .engine: "核心", .legalNotice: "法律聲明",
            .permittedUse: "允許用途", .yourResponsibility: "您的責任",
            .noWarranty: "無擔保與責任限制", .thirdPartyServices: "第三方服務",
            .indemnification: "賠償責任",
            .disclaimerPurpose: "Clash Glass 僅供合法的教育、學術、互通性及安全研究用途。",
            .disclaimerResponsibility: "您有責任取得所有必要授權，並遵守適用的法律、法規、授權、網路政策及第三方條款。不得使用本軟體進行未經授權的存取、干擾服務、規避合法限制、侵犯權利或協助違法活動。",
            .disclaimerLiability: "在適用法律允許的最大範圍內，本軟體按「現狀」及「可用狀態」提供，不作任何擔保。開發者及貢獻者不對因本軟體或其使用所產生的任何直接、間接、附帶、特殊、懲罰性或後果性損失承擔責任。",
            .disclaimerThirdParties: "Mihomo、網路供應商、訂閱供應商、網站及其他第三方元件或服務均獨立於 Clash Glass，其可用性、安全性、內容、行為及條款不受開發者控制。",
            .disclaimerIndemnity: "在適用法律允許的最大範圍內，您同意就因您的使用、誤用、散佈、設定或違反法律及第三方權利而產生的索賠、損害、處罰、責任、費用及合理法律費用，為開發者及貢獻者進行抗辯、賠償並使其免受損害。",
            .update: "更新", .dashboard: "儀表板", .proxies: "代理", .routing: "路由",
            .profiles: "設定檔", .requests: "請求", .connections: "連線", .resources: "資源",
            .logs: "日誌", .coreStatus: "核心狀態", .quickEdit: "快速編輯",
            .cancel: "取消", .confirm: "確認", .restartCore: "重新啟動核心", .startCore: "啟動核心",
            .renameProfile: "重新命名設定檔", .profileName: "設定檔名稱", .rename: "重新命名",
            .systemProxy: "系統代理", .networkSpeed: "網路速度",
            .networkDetection: "網路偵測", .outboundMode: "出站模式",
            .trafficUsage: "流量使用", .intranetIP: "內網 IP", .options: "選項",
            .rule: "規則", .global: "全域", .direct: "直連", .upload: "上傳", .download: "下載",
            .search: "搜尋", .closeAll: "全部關閉", .refresh: "重新整理", .noConnections: "暫無連線",
            .host: "主機", .chain: "鏈路", .closeConnection: "關閉連線",
            .stopAutoScroll: "停止自動捲動", .scrollToTop: "捲動到頂端", .noRequests: "暫無請求",
            .reload: "重新載入", .openFolder: "開啟資料夾", .ready: "就緒", .clear: "清除",
            .export: "匯出", .noLogs: "暫無日誌", .stopped: "已停止", .connected: "已連線",
            .coreRunning: "核心執行中", .nodes: "個節點", .noProxyNodes: "沒有可用代理節點",
            .validateAll: "全部驗證", .openManagedFolder: "開啟託管資料夾", .importYAML: "匯入 YAML",
            .importConfiguration: "匯入設定", .noMatchingProfiles: "沒有符合的設定檔",
            .deleteProfile: "刪除設定檔", .managedYAML: "託管 YAML", .running: "執行中",
            .current: "目前", .managed: "已託管", .selected: "已選取", .use: "使用",
            .validate: "驗證", .revealInFinder: "在 Finder 中顯示", .delete: "刪除",
            .delayTest: "延遲測試", .providers: "供應商", .automatic: "自動",
            .collapse: "收合", .expand: "展開", .addRule: "新增規則", .saving: "儲存中",
            .domainRouting: "網域路由", .deleteRule: "刪除規則",
            .noMatchingRoutingRules: "沒有符合的路由規則",
            .addDomainHint: "新增網域並選擇透過 VPN 或直接連線",
            .start: "啟動", .pause: "暫停",
        ],
        .japanese: [
            .settings: "設定", .settingsSubtitle: "Clash Glass の外観と言語、アプリ情報を管理します。",
            .appearance: "外観", .colorScheme: "カラースキーム", .system: "システム",
            .light: "ライト", .dark: "ダーク", .language: "言語", .systemDefault: "システム設定",
            .about: "このアプリについて", .version: "バージョン", .engine: "エンジン",
            .legalNotice: "法的通知", .permittedUse: "許可された用途",
            .yourResponsibility: "利用者の責任", .noWarranty: "無保証および責任制限",
            .thirdPartyServices: "第三者サービス", .indemnification: "補償",
            .disclaimerPurpose: "Clash Glass は、合法的な教育、学術、相互運用性、およびセキュリティ研究のみを目的として提供されます。",
            .disclaimerResponsibility: "必要な許可を取得し、適用される法律、規制、ライセンス、ネットワークポリシー、第三者の規約を遵守する責任は利用者にあります。不正アクセス、サービス妨害、合法的制限の回避、権利侵害、違法行為への利用は禁止されています。",
            .disclaimerLiability: "適用法で認められる最大限の範囲で、本ソフトウェアは現状有姿かつ提供可能な状態で、いかなる保証もなく提供されます。開発者および貢献者は、本ソフトウェアまたはその利用に起因する直接的・間接的・付随的・特別・懲罰的・結果的損害について責任を負いません。",
            .disclaimerThirdParties: "Mihomo、ネットワーク事業者、購読事業者、ウェブサイト、その他の第三者コンポーネントやサービスは Clash Glass とは独立しており、その可用性、安全性、内容、行為、規約は開発者の管理外です。",
            .disclaimerIndemnity: "適用法で認められる最大限の範囲で、利用、誤用、配布、設定、法令または第三者の権利の違反に起因する請求、損害、罰則、責任、費用および合理的な弁護士費用から、開発者および貢献者を防御・補償することに同意します。",
            .update: "アップデート", .dashboard: "ダッシュボード", .proxies: "プロキシ",
            .routing: "ルーティング", .profiles: "プロファイル", .requests: "リクエスト",
            .connections: "接続", .resources: "リソース", .logs: "ログ",
            .coreStatus: "コア状態", .quickEdit: "クイック編集", .cancel: "キャンセル",
            .confirm: "確認", .restartCore: "コアを再起動", .startCore: "コアを起動",
            .renameProfile: "プロファイル名を変更", .profileName: "プロファイル名", .rename: "名前を変更",
            .systemProxy: "システムプロキシ", .networkSpeed: "ネットワーク速度",
            .networkDetection: "ネットワーク検出", .outboundMode: "送信モード",
            .trafficUsage: "通信量", .intranetIP: "ローカル IP", .options: "オプション",
            .rule: "ルール", .global: "グローバル", .direct: "直接", .upload: "アップロード", .download: "ダウンロード",
            .search: "検索", .closeAll: "すべて閉じる", .refresh: "更新", .noConnections: "接続なし",
            .host: "ホスト", .chain: "チェーン", .closeConnection: "接続を閉じる",
            .stopAutoScroll: "自動スクロールを停止", .scrollToTop: "先頭へ移動", .noRequests: "リクエストなし",
            .reload: "再読み込み", .openFolder: "フォルダを開く", .ready: "準備完了", .clear: "消去",
            .export: "書き出す", .noLogs: "ログなし", .stopped: "停止中", .connected: "接続済み",
            .coreRunning: "コア実行中", .nodes: "ノード", .noProxyNodes: "利用可能なプロキシノードがありません",
            .validateAll: "すべて検証", .openManagedFolder: "管理フォルダを開く", .importYAML: "YAML を読み込む",
            .importConfiguration: "設定を読み込む", .noMatchingProfiles: "一致するプロファイルがありません",
            .deleteProfile: "プロファイルを削除", .managedYAML: "管理対象 YAML", .running: "実行中",
            .current: "現在", .managed: "管理対象", .selected: "選択済み", .use: "使用",
            .validate: "検証", .revealInFinder: "Finder に表示", .delete: "削除",
            .delayTest: "遅延テスト", .providers: "プロバイダ", .automatic: "自動",
            .collapse: "折りたたむ", .expand: "展開", .addRule: "ルールを追加", .saving: "保存中",
            .domainRouting: "ドメインルーティング", .deleteRule: "ルールを削除",
            .noMatchingRoutingRules: "一致するルーティングルールがありません",
            .addDomainHint: "ドメインを追加して VPN または直接接続を選択",
            .start: "開始", .pause: "一時停止",
        ],
        .french: [
            .settings: "Réglages", .settingsSubtitle: "Personnalisez Clash Glass et consultez les informations de l’application.",
            .appearance: "Apparence", .colorScheme: "Thème", .system: "Système",
            .light: "Clair", .dark: "Sombre", .language: "Langue", .systemDefault: "Langue du système",
            .about: "À propos", .version: "Version", .engine: "Moteur", .legalNotice: "Mentions légales",
            .permittedUse: "Usage autorisé", .yourResponsibility: "Votre responsabilité",
            .noWarranty: "Absence de garantie et limitation de responsabilité",
            .thirdPartyServices: "Services tiers", .indemnification: "Indemnisation",
            .disclaimerPurpose: "Clash Glass est fourni uniquement à des fins légales d’éducation, de recherche universitaire, d’interopérabilité et de sécurité.",
            .disclaimerResponsibility: "Vous êtes seul responsable de l’obtention des autorisations requises et du respect des lois, règlements, licences, politiques réseau et conditions de tiers applicables. Toute utilisation pour un accès non autorisé, une perturbation de service, un contournement illégal, une atteinte aux droits ou une activité illicite est interdite.",
            .disclaimerLiability: "Dans toute la mesure permise par la loi, le logiciel est fourni « en l’état » et « selon disponibilité », sans aucune garantie. Le développeur et les contributeurs ne répondent d’aucune perte directe, indirecte, accessoire, spéciale, punitive ou consécutive liée au logiciel ou à son utilisation.",
            .disclaimerThirdParties: "Mihomo, les fournisseurs de réseau ou d’abonnement, les sites web et les autres composants ou services tiers sont indépendants de Clash Glass. Leur disponibilité, sécurité, contenu, conduite et conditions échappent au contrôle du développeur.",
            .disclaimerIndemnity: "Dans toute la mesure permise par la loi, vous acceptez de défendre, indemniser et garantir le développeur et les contributeurs contre les réclamations, dommages, sanctions, responsabilités, frais et honoraires juridiques raisonnables résultant de votre utilisation, mauvaise utilisation, distribution, configuration ou violation de la loi ou des droits de tiers.",
            .update: "Mise à jour", .dashboard: "Tableau de bord", .proxies: "Proxy",
            .routing: "Routage", .profiles: "Profils", .requests: "Requêtes", .connections: "Connexions",
            .resources: "Ressources", .logs: "Journaux", .coreStatus: "État du moteur",
            .quickEdit: "Modification rapide", .cancel: "Annuler", .confirm: "Confirmer",
            .restartCore: "Redémarrer le moteur", .startCore: "Démarrer le moteur",
            .renameProfile: "Renommer le profil", .profileName: "Nom du profil", .rename: "Renommer",
            .systemProxy: "Proxy système", .networkSpeed: "Vitesse du réseau",
            .networkDetection: "Détection du réseau", .outboundMode: "Mode de sortie",
            .trafficUsage: "Utilisation des données", .intranetIP: "IP locale", .options: "Options",
            .rule: "Règles", .global: "Global", .direct: "Direct", .upload: "Envoi", .download: "Réception",
            .search: "Rechercher", .closeAll: "Tout fermer", .refresh: "Actualiser",
            .noConnections: "Aucune connexion", .host: "Hôte", .chain: "Chaîne",
            .closeConnection: "Fermer la connexion", .stopAutoScroll: "Arrêter le défilement automatique",
            .scrollToTop: "Aller en haut", .noRequests: "Aucune requête", .reload: "Recharger",
            .openFolder: "Ouvrir le dossier", .ready: "Prêt", .clear: "Effacer", .export: "Exporter",
            .noLogs: "Aucun journal", .stopped: "Arrêté", .connected: "Connecté",
            .coreRunning: "Moteur actif", .nodes: "nœuds", .noProxyNodes: "Aucun nœud proxy disponible",
            .validateAll: "Tout valider", .openManagedFolder: "Ouvrir le dossier géré",
            .importYAML: "Importer YAML", .importConfiguration: "Importer une configuration",
            .noMatchingProfiles: "Aucun profil correspondant", .deleteProfile: "Supprimer le profil",
            .managedYAML: "YAML géré", .running: "Actif", .current: "Actuel", .managed: "Géré",
            .selected: "Sélectionné", .use: "Utiliser", .validate: "Valider",
            .revealInFinder: "Afficher dans le Finder", .delete: "Supprimer",
            .delayTest: "Test de latence", .providers: "Fournisseurs", .automatic: "Automatique",
            .collapse: "Réduire", .expand: "Développer", .addRule: "Ajouter une règle",
            .saving: "Enregistrement", .domainRouting: "Routage de domaine",
            .deleteRule: "Supprimer la règle", .noMatchingRoutingRules: "Aucune règle correspondante",
            .addDomainHint: "Ajoutez un domaine et choisissez VPN ou Direct",
            .start: "Démarrer", .pause: "Pause",
        ],
        .russian: [
            .settings: "Настройки", .settingsSubtitle: "Настройте Clash Glass и просмотрите сведения о приложении.",
            .appearance: "Оформление", .colorScheme: "Цветовая схема", .system: "Системная",
            .light: "Светлая", .dark: "Тёмная", .language: "Язык", .systemDefault: "Системный язык",
            .about: "О программе", .version: "Версия", .engine: "Ядро", .legalNotice: "Правовая информация",
            .permittedUse: "Разрешённое использование", .yourResponsibility: "Ваша ответственность",
            .noWarranty: "Отказ от гарантий и ограничение ответственности",
            .thirdPartyServices: "Сторонние сервисы", .indemnification: "Возмещение убытков",
            .disclaimerPurpose: "Clash Glass предоставляется исключительно для законных образовательных, академических, исследовательских и связанных с совместимостью и безопасностью целей.",
            .disclaimerResponsibility: "Вы несёте исключительную ответственность за получение необходимых разрешений и соблюдение применимых законов, правил, лицензий, сетевых политик и условий третьих лиц. Запрещено использовать программу для несанкционированного доступа, вмешательства в работу сервисов, незаконного обхода ограничений, нарушения прав или содействия незаконной деятельности.",
            .disclaimerLiability: "В максимально допустимой законом степени программа предоставляется «как есть» и «по мере доступности» без каких-либо гарантий. Разработчик и участники не несут ответственности за прямые, косвенные, случайные, специальные, штрафные или последующие убытки, связанные с программой или её использованием.",
            .disclaimerThirdParties: "Mihomo, сетевые и подписочные провайдеры, веб-сайты и другие сторонние компоненты или сервисы независимы от Clash Glass. Их доступность, безопасность, содержимое, поведение и условия не контролируются разработчиком.",
            .disclaimerIndemnity: "В максимально допустимой законом степени вы соглашаетесь защищать разработчика и участников и возмещать им претензии, ущерб, штрафы, обязательства, расходы и разумные юридические издержки, возникшие из-за использования, неправильного использования, распространения, настройки или нарушения закона либо прав третьих лиц.",
            .update: "Обновить", .dashboard: "Панель", .proxies: "Прокси", .routing: "Маршрутизация",
            .profiles: "Профили", .requests: "Запросы", .connections: "Соединения",
            .resources: "Ресурсы", .logs: "Журналы", .coreStatus: "Состояние ядра",
            .quickEdit: "Быстрое редактирование", .cancel: "Отмена", .confirm: "Подтвердить",
            .restartCore: "Перезапустить ядро", .startCore: "Запустить ядро",
            .renameProfile: "Переименовать профиль", .profileName: "Имя профиля", .rename: "Переименовать",
            .systemProxy: "Системный прокси", .networkSpeed: "Скорость сети",
            .networkDetection: "Определение сети", .outboundMode: "Режим выхода",
            .trafficUsage: "Трафик", .intranetIP: "Локальный IP", .options: "Параметры",
            .rule: "Правила", .global: "Глобальный", .direct: "Напрямую", .upload: "Отправка", .download: "Загрузка",
            .search: "Поиск", .closeAll: "Закрыть все", .refresh: "Обновить",
            .noConnections: "Нет соединений", .host: "Хост", .chain: "Цепочка",
            .closeConnection: "Закрыть соединение", .stopAutoScroll: "Остановить автопрокрутку",
            .scrollToTop: "Наверх", .noRequests: "Нет запросов", .reload: "Перезагрузить",
            .openFolder: "Открыть папку", .ready: "Готово", .clear: "Очистить", .export: "Экспорт",
            .noLogs: "Нет журналов", .stopped: "Остановлено", .connected: "Подключено",
            .coreRunning: "Ядро работает", .nodes: "узлов", .noProxyNodes: "Нет доступных прокси-узлов",
            .validateAll: "Проверить все", .openManagedFolder: "Открыть папку профилей",
            .importYAML: "Импорт YAML", .importConfiguration: "Импортировать конфигурацию",
            .noMatchingProfiles: "Нет подходящих профилей", .deleteProfile: "Удалить профиль",
            .managedYAML: "Управляемый YAML", .running: "Работает", .current: "Текущий",
            .managed: "Управляемый", .selected: "Выбран", .use: "Использовать",
            .validate: "Проверить", .revealInFinder: "Показать в Finder", .delete: "Удалить",
            .delayTest: "Тест задержки", .providers: "Провайдеры", .automatic: "Автоматически",
            .collapse: "Свернуть", .expand: "Развернуть", .addRule: "Добавить правило",
            .saving: "Сохранение", .domainRouting: "Маршрутизация доменов",
            .deleteRule: "Удалить правило", .noMatchingRoutingRules: "Нет подходящих правил",
            .addDomainHint: "Добавьте домен и выберите VPN или прямой маршрут",
            .start: "Запустить", .pause: "Пауза",
        ],
        .spanish: [
            .settings: "Ajustes", .settingsSubtitle: "Personaliza Clash Glass y consulta la información de la aplicación.",
            .appearance: "Apariencia", .colorScheme: "Esquema de color", .system: "Sistema",
            .light: "Claro", .dark: "Oscuro", .language: "Idioma", .systemDefault: "Idioma del sistema",
            .about: "Acerca de", .version: "Versión", .engine: "Motor", .legalNotice: "Aviso legal",
            .permittedUse: "Uso permitido", .yourResponsibility: "Tu responsabilidad",
            .noWarranty: "Sin garantía y limitación de responsabilidad",
            .thirdPartyServices: "Servicios de terceros", .indemnification: "Indemnización",
            .disclaimerPurpose: "Clash Glass se proporciona únicamente para fines legales educativos, académicos, de interoperabilidad y de investigación de seguridad.",
            .disclaimerResponsibility: "Eres el único responsable de obtener las autorizaciones necesarias y cumplir las leyes, reglamentos, licencias, políticas de red y condiciones de terceros aplicables. No debes utilizar el software para acceso no autorizado, interferencia con servicios, elusión ilegal, infracción de derechos o actividades ilícitas.",
            .disclaimerLiability: "En la máxima medida permitida por la ley, el software se proporciona «tal cual» y «según disponibilidad», sin garantías de ningún tipo. El desarrollador y los colaboradores no serán responsables de pérdidas directas, indirectas, incidentales, especiales, punitivas o consecuentes relacionadas con el software o su uso.",
            .disclaimerThirdParties: "Mihomo, los proveedores de red o suscripción, los sitios web y otros componentes o servicios de terceros son independientes de Clash Glass. Su disponibilidad, seguridad, contenido, conducta y condiciones quedan fuera del control del desarrollador.",
            .disclaimerIndemnity: "En la máxima medida permitida por la ley, aceptas defender, indemnizar y mantener indemnes al desarrollador y a los colaboradores frente a reclamaciones, daños, sanciones, responsabilidades, costes y honorarios legales razonables derivados de tu uso, uso indebido, distribución, configuración o infracción de la ley o de derechos de terceros.",
            .update: "Actualizar", .dashboard: "Panel", .proxies: "Proxies", .routing: "Enrutamiento",
            .profiles: "Perfiles", .requests: "Solicitudes", .connections: "Conexiones",
            .resources: "Recursos", .logs: "Registros", .coreStatus: "Estado del núcleo",
            .quickEdit: "Edición rápida", .cancel: "Cancelar", .confirm: "Confirmar",
            .restartCore: "Reiniciar núcleo", .startCore: "Iniciar núcleo",
            .renameProfile: "Renombrar perfil", .profileName: "Nombre del perfil", .rename: "Renombrar",
            .systemProxy: "Proxy del sistema", .networkSpeed: "Velocidad de red",
            .networkDetection: "Detección de red", .outboundMode: "Modo de salida",
            .trafficUsage: "Uso de datos", .intranetIP: "IP local", .options: "Opciones",
            .rule: "Reglas", .global: "Global", .direct: "Directo", .upload: "Subida", .download: "Descarga",
            .search: "Buscar", .closeAll: "Cerrar todo", .refresh: "Actualizar",
            .noConnections: "Sin conexiones", .host: "Host", .chain: "Cadena",
            .closeConnection: "Cerrar conexión", .stopAutoScroll: "Detener desplazamiento automático",
            .scrollToTop: "Ir arriba", .noRequests: "Sin solicitudes", .reload: "Recargar",
            .openFolder: "Abrir carpeta", .ready: "Listo", .clear: "Borrar", .export: "Exportar",
            .noLogs: "Sin registros", .stopped: "Detenido", .connected: "Conectado",
            .coreRunning: "Núcleo activo", .nodes: "nodos", .noProxyNodes: "No hay nodos proxy disponibles",
            .validateAll: "Validar todo", .openManagedFolder: "Abrir carpeta gestionada",
            .importYAML: "Importar YAML", .importConfiguration: "Importar configuración",
            .noMatchingProfiles: "No hay perfiles coincidentes", .deleteProfile: "Eliminar perfil",
            .managedYAML: "YAML gestionado", .running: "En ejecución", .current: "Actual",
            .managed: "Gestionado", .selected: "Seleccionado", .use: "Usar",
            .validate: "Validar", .revealInFinder: "Mostrar en Finder", .delete: "Eliminar",
            .delayTest: "Prueba de latencia", .providers: "Proveedores", .automatic: "Automático",
            .collapse: "Contraer", .expand: "Expandir", .addRule: "Añadir regla",
            .saving: "Guardando", .domainRouting: "Enrutamiento de dominios",
            .deleteRule: "Eliminar regla", .noMatchingRoutingRules: "No hay reglas coincidentes",
            .addDomainHint: "Añade un dominio y elige VPN o conexión directa",
            .start: "Iniciar", .pause: "Pausar",
        ],
        .portuguese: [
            .settings: "Definições", .settingsSubtitle: "Personalize o Clash Glass e consulte as informações da aplicação.",
            .appearance: "Aparência", .colorScheme: "Esquema de cores", .system: "Sistema",
            .light: "Claro", .dark: "Escuro", .language: "Idioma", .systemDefault: "Idioma do sistema",
            .about: "Acerca de", .version: "Versão", .engine: "Motor", .legalNotice: "Aviso legal",
            .permittedUse: "Utilização permitida", .yourResponsibility: "A sua responsabilidade",
            .noWarranty: "Sem garantia e limitação de responsabilidade",
            .thirdPartyServices: "Serviços de terceiros", .indemnification: "Indemnização",
            .disclaimerPurpose: "O Clash Glass é fornecido exclusivamente para fins legais de educação, investigação académica, interoperabilidade e segurança.",
            .disclaimerResponsibility: "É o único responsável por obter todas as autorizações necessárias e cumprir as leis, regulamentos, licenças, políticas de rede e termos de terceiros aplicáveis. Não deve utilizar o software para acesso não autorizado, interferência em serviços, contorno ilegal, violação de direitos ou atividades ilícitas.",
            .disclaimerLiability: "Na máxima medida permitida por lei, o software é fornecido «tal como está» e «conforme disponível», sem garantias de qualquer tipo. O programador e os colaboradores não são responsáveis por perdas diretas, indiretas, incidentais, especiais, punitivas ou consequenciais relacionadas com o software ou a sua utilização.",
            .disclaimerThirdParties: "Mihomo, fornecedores de rede ou subscrição, sites e outros componentes ou serviços de terceiros são independentes do Clash Glass. A sua disponibilidade, segurança, conteúdo, conduta e termos estão fora do controlo do programador.",
            .disclaimerIndemnity: "Na máxima medida permitida por lei, concorda em defender, indemnizar e isentar o programador e os colaboradores de reclamações, danos, penalizações, responsabilidades, custos e honorários jurídicos razoáveis decorrentes da sua utilização, utilização indevida, distribuição, configuração ou violação da lei ou de direitos de terceiros.",
            .update: "Atualizar", .dashboard: "Painel", .proxies: "Proxies", .routing: "Encaminhamento",
            .profiles: "Perfis", .requests: "Pedidos", .connections: "Ligações",
            .resources: "Recursos", .logs: "Registos", .coreStatus: "Estado do núcleo",
            .quickEdit: "Edição rápida", .cancel: "Cancelar", .confirm: "Confirmar",
            .restartCore: "Reiniciar núcleo", .startCore: "Iniciar núcleo",
            .renameProfile: "Mudar nome do perfil", .profileName: "Nome do perfil", .rename: "Mudar nome",
            .systemProxy: "Proxy do sistema", .networkSpeed: "Velocidade da rede",
            .networkDetection: "Deteção de rede", .outboundMode: "Modo de saída",
            .trafficUsage: "Utilização de dados", .intranetIP: "IP local", .options: "Opções",
            .rule: "Regras", .global: "Global", .direct: "Direto", .upload: "Envio", .download: "Receção",
            .search: "Pesquisar", .closeAll: "Fechar tudo", .refresh: "Atualizar",
            .noConnections: "Sem ligações", .host: "Anfitrião", .chain: "Cadeia",
            .closeConnection: "Fechar ligação", .stopAutoScroll: "Parar deslocamento automático",
            .scrollToTop: "Ir para o topo", .noRequests: "Sem pedidos", .reload: "Recarregar",
            .openFolder: "Abrir pasta", .ready: "Pronto", .clear: "Limpar", .export: "Exportar",
            .noLogs: "Sem registos", .stopped: "Parado", .connected: "Ligado",
            .coreRunning: "Núcleo ativo", .nodes: "nós", .noProxyNodes: "Sem nós proxy disponíveis",
            .validateAll: "Validar tudo", .openManagedFolder: "Abrir pasta gerida",
            .importYAML: "Importar YAML", .importConfiguration: "Importar configuração",
            .noMatchingProfiles: "Sem perfis correspondentes", .deleteProfile: "Eliminar perfil",
            .managedYAML: "YAML gerido", .running: "Em execução", .current: "Atual",
            .managed: "Gerido", .selected: "Selecionado", .use: "Usar",
            .validate: "Validar", .revealInFinder: "Mostrar no Finder", .delete: "Eliminar",
            .delayTest: "Teste de latência", .providers: "Fornecedores", .automatic: "Automático",
            .collapse: "Recolher", .expand: "Expandir", .addRule: "Adicionar regra",
            .saving: "A guardar", .domainRouting: "Encaminhamento de domínios",
            .deleteRule: "Eliminar regra", .noMatchingRoutingRules: "Sem regras correspondentes",
            .addDomainHint: "Adicione um domínio e escolha VPN ou ligação direta",
            .start: "Iniciar", .pause: "Pausar",
        ],
    ]
}
