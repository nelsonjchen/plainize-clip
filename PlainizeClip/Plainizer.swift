import Foundation

enum Plainizer {
    static func plainized(_ input: String, options: PlainizeOptions) -> String {
        var text = input.normalizingLineEndings()

        if options.trimLeadingWhitespace || options.trimTrailingWhitespace {
            text = text
                .components(separatedBy: "\n")
                .map {
                    $0.trimmingLineWhitespace(
                        leading: options.trimLeadingWhitespace,
                        trailing: options.trimTrailingWhitespace
                    )
                }
                .joined(separator: "\n")
        }

        if options.removeInvisibleControls {
            text = text.removingInvisibleControls()
        }

        if options.removeHardWraps {
            text = text.removingHardWraps()
        }

        if options.normalizeUnicode {
            text = text.precomposedStringWithCanonicalMapping
        }

        if options.replaceTabs {
            text = text.replacingOccurrences(of: "\t", with: " ")
        }

        if options.removeConsecutiveSpaces {
            text.replaceRepeatedOccurrences(of: "  ", with: " ")
        }

        if options.removeBlankLines {
            text.replaceRepeatedOccurrences(of: "\n\n", with: "\n")
        }

        if options.removeSmartQuotes {
            text = text.replacingCharacters(using: [
                "\u{201C}": "\"",
                "\u{201D}": "\"",
                "\u{00AB}": "\"",
                "\u{00BB}": "\"",
                "\u{2018}": "'",
                "\u{2019}": "'",
                "\u{2013}": "-",
                "\u{2014}": "-"
            ])
        }

        if options.convertToASCII {
            text = text.convertingToPlainASCII()
        }

        if options.trimWholeString {
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return text
    }
}

private extension String {
    func normalizingLineEndings() -> String {
        replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    func trimmingLineWhitespace(leading: Bool, trailing: Bool) -> String {
        let scalars = Array(unicodeScalars)
        let whitespace = CharacterSet.whitespaces
        var start = scalars.startIndex
        var end = scalars.endIndex

        if leading {
            while start < end, whitespace.contains(scalars[start]) {
                start += 1
            }
        }

        if trailing {
            while end > start, whitespace.contains(scalars[end - 1]) {
                end -= 1
            }
        }

        return String(String.UnicodeScalarView(scalars[start..<end]))
    }

    func removingInvisibleControls() -> String {
        let replacements: [UnicodeScalar: String] = [
            "\u{00A0}": " ",
            "\u{2000}": " ",
            "\u{2001}": " ",
            "\u{2002}": " ",
            "\u{2003}": " ",
            "\u{2004}": " ",
            "\u{2005}": " ",
            "\u{2006}": " ",
            "\u{2007}": " ",
            "\u{2008}": " ",
            "\u{2009}": " ",
            "\u{200A}": " ",
            "\u{00AD}": "",
            "\u{200B}": "",
            "\u{FEFF}": ""
        ]

        var output = ""
        output.reserveCapacity(count)

        for scalar in unicodeScalars {
            if let replacement = replacements[scalar] {
                output += replacement
            } else if (scalar.value < 32 && scalar.value != 9 && scalar.value != 10) || scalar.value == 127 {
                continue
            } else {
                output.unicodeScalars.append(scalar)
            }
        }

        return output
    }

    func removingHardWraps() -> String {
        let lines = components(separatedBy: "\n")
        var joined = ""
        let whitespace = CharacterSet.whitespaces

        for index in lines.indices {
            let line = lines[index]
            joined += line

            let nextIndex = lines.index(after: index)
            if nextIndex < lines.endIndex {
                let currentTrimmed = line.trimmingCharacters(in: whitespace)
                let nextTrimmed = lines[nextIndex].trimmingCharacters(in: whitespace)
                joined += currentTrimmed.isEmpty || nextTrimmed.isEmpty ? "\n" : " "
            }
        }

        return joined
    }

    mutating func replaceRepeatedOccurrences(of target: String, with replacement: String) {
        while contains(target) {
            self = replacingOccurrences(of: target, with: replacement)
        }
    }

    func replacingCharacters(using replacements: [String: String]) -> String {
        var text = self
        for (target, replacement) in replacements {
            text = text.replacingOccurrences(of: target, with: replacement)
        }
        return text
    }

    func convertingToPlainASCII() -> String {
        var text = replacingCharacters(usingOrdered: [
            ("Ä", "Ae"),
            ("Ö", "Oe"),
            ("Ü", "Ue"),
            ("ä", "ae"),
            ("ö", "oe"),
            ("ü", "ue"),
            ("ß", "ss"),
            ("æ", "ae"),
            ("Š", "S"),
            ("œ", "oe")
        ])

        text = text.applyingTransform(.toLatin, reverse: false) ?? text
        text = text.applyingTransform(.stripDiacritics, reverse: false) ?? text
        text = text.replacingCharacters(usingOrdered: [
            ("\u{2018}", "'"),
            ("\u{2019}", "'"),
            ("\u{201A}", "'"),
            ("\u{201B}", "'"),
            ("\u{2032}", "'"),
            ("\u{02BB}", "'"),
            ("\u{02BC}", "'"),
            ("\u{02BE}", "'"),
            ("\u{02BF}", "'"),
            ("\u{201C}", "\""),
            ("\u{201D}", "\""),
            ("\u{201E}", "\""),
            ("\u{201F}", "\""),
            ("\u{00AB}", "\""),
            ("\u{00BB}", "\""),
            ("\u{2033}", "\""),
            ("\u{2010}", "-"),
            ("\u{2011}", "-"),
            ("\u{2012}", "-"),
            ("\u{2013}", "-"),
            ("\u{2014}", "-"),
            ("\u{2015}", "-"),
            ("\u{2212}", "-"),
            ("\u{2026}", "..."),
            ("\u{00A0}", " "),
            ("\u{2000}", " "),
            ("\u{2001}", " "),
            ("\u{2002}", " "),
            ("\u{2003}", " "),
            ("\u{2004}", " "),
            ("\u{2005}", " "),
            ("\u{2006}", " "),
            ("\u{2007}", " "),
            ("\u{2008}", " "),
            ("\u{2009}", " "),
            ("\u{200A}", " ")
        ])

        var output = ""
        output.reserveCapacity(text.count)

        for scalar in text.unicodeScalars {
            if scalar.value <= 127 {
                output.unicodeScalars.append(scalar)
            } else if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                output += " "
            }
        }

        if output.isEmpty && !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "?"
        }

        return output
    }

    func replacingCharacters(usingOrdered replacements: [(String, String)]) -> String {
        var text = self
        for (target, replacement) in replacements {
            text = text.replacingOccurrences(of: target, with: replacement)
        }
        return text
    }
}
