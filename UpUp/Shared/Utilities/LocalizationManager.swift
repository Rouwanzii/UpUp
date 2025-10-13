import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }

    enum Language: String, CaseIterable {
        case system = "system"
        case english = "en"
        case chinese = "zh-Hans"

        var displayName: String {
            switch self {
            case .system:
                return "System"
            case .english:
                return "English"
            case .chinese:
                return "简体中文"
            }
        }
    }

    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .system
        }
    }

    func localizedString(_ key: String) -> String {
        let language = currentLanguage == .system ? getSystemLanguage() : currentLanguage

        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }

        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    func getSystemLanguage() -> Language {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"

        if preferredLanguage.hasPrefix("zh") {
            return .chinese
        } else {
            return .english
        }
    }
}

// Helper for easy access in SwiftUI views
extension String {
    var localized: String {
        LocalizationManager.shared.localizedString(self)
    }
}

// Helper for localized date formatting
extension LocalizationManager {
    func localizedDateFormatter(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .none) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle

        // Use the app's selected language, or system language if set to .system
        let language = currentLanguage == .system ? getSystemLanguage() : currentLanguage

        switch language {
        case .chinese:
            formatter.locale = Locale(identifier: "zh_Hans_CN")
        case .english:
            formatter.locale = Locale(identifier: "en_US")
        case .system:
            formatter.locale = Locale.current
        }

        return formatter
    }
}

// Extension for Date to format with localization
extension Date {
    func localizedFormat(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .none) -> String {
        let formatter = LocalizationManager.shared.localizedDateFormatter(dateStyle: dateStyle, timeStyle: timeStyle)
        return formatter.string(from: self)
    }

    func localizedFormatCustom(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format

        let language = LocalizationManager.shared.currentLanguage == .system ?
            LocalizationManager.shared.getSystemLanguage() :
            LocalizationManager.shared.currentLanguage

        switch language {
        case .chinese:
            formatter.locale = Locale(identifier: "zh_Hans_CN")
        case .english:
            formatter.locale = Locale(identifier: "en_US")
        case .system:
            formatter.locale = Locale.current
        }

        return formatter.string(from: self)
    }
}
