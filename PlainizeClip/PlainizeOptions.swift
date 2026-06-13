import Foundation

struct PlainizeOptions: Equatable {
    var trimTrailingWhitespace: Bool
    var trimLeadingWhitespace: Bool
    var removeInvisibleControls: Bool
    var removeHardWraps: Bool
    var removeBlankLines: Bool
    var removeSmartQuotes: Bool
    var removeConsecutiveSpaces: Bool
    var replaceTabs: Bool
    var convertToASCII: Bool
    var normalizeUnicode: Bool
    var trimWholeString: Bool

    static let standard = PlainizeOptions(
        trimTrailingWhitespace: true,
        trimLeadingWhitespace: true,
        removeInvisibleControls: true,
        removeHardWraps: true,
        removeBlankLines: true,
        removeSmartQuotes: true,
        removeConsecutiveSpaces: true,
        replaceTabs: true,
        convertToASCII: false,
        normalizeUnicode: false,
        trimWholeString: true
    )

    static func registerDefaults(_ defaults: UserDefaults = .standard) {
        defaults.register(defaults: standard.dictionary)
    }

    static func load(from defaults: UserDefaults = .standard) -> PlainizeOptions {
        registerDefaults(defaults)
        return PlainizeOptions(
            trimTrailingWhitespace: defaults.bool(forKey: Keys.trimTrailingWhitespace),
            trimLeadingWhitespace: defaults.bool(forKey: Keys.trimLeadingWhitespace),
            removeInvisibleControls: defaults.bool(forKey: Keys.removeInvisibleControls),
            removeHardWraps: defaults.bool(forKey: Keys.removeHardWraps),
            removeBlankLines: defaults.bool(forKey: Keys.removeBlankLines),
            removeSmartQuotes: defaults.bool(forKey: Keys.removeSmartQuotes),
            removeConsecutiveSpaces: defaults.bool(forKey: Keys.removeConsecutiveSpaces),
            replaceTabs: defaults.bool(forKey: Keys.replaceTabs),
            convertToASCII: defaults.bool(forKey: Keys.convertToASCII),
            normalizeUnicode: defaults.bool(forKey: Keys.normalizeUnicode),
            trimWholeString: defaults.bool(forKey: Keys.trimWholeString)
        )
    }

    func save(to defaults: UserDefaults = .standard) {
        for (key, value) in dictionary {
            defaults.set(value, forKey: key)
        }
    }

    private var dictionary: [String: Bool] {
        [
            Keys.trimTrailingWhitespace: trimTrailingWhitespace,
            Keys.trimLeadingWhitespace: trimLeadingWhitespace,
            Keys.removeInvisibleControls: removeInvisibleControls,
            Keys.removeHardWraps: removeHardWraps,
            Keys.removeBlankLines: removeBlankLines,
            Keys.removeSmartQuotes: removeSmartQuotes,
            Keys.removeConsecutiveSpaces: removeConsecutiveSpaces,
            Keys.replaceTabs: replaceTabs,
            Keys.convertToASCII: convertToASCII,
            Keys.normalizeUnicode: normalizeUnicode,
            Keys.trimWholeString: trimWholeString
        ]
    }

    enum Keys {
        static let trimTrailingWhitespace = "trimTrailingWhitespace"
        static let trimLeadingWhitespace = "trimLeadingWhitespace"
        static let removeInvisibleControls = "zapGremlins"
        static let removeHardWraps = "zapHardWraps"
        static let removeBlankLines = "zapBlankLines"
        static let removeSmartQuotes = "removeSmartQuotes"
        static let removeConsecutiveSpaces = "zapConsecutiveSpaces"
        static let replaceTabs = "replaceTabs"
        static let convertToASCII = "toAscii"
        static let normalizeUnicode = "normalize"
        static let trimWholeString = "trimString"
    }
}
