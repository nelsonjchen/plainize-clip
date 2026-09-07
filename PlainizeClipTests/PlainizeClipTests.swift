import AppKit
import XCTest

final class PlainizeClipTests: XCTestCase {
    func testParserSupportsNormalizationOption() {
        let parser = ArgumentParser(arguments: ["plainize-clip", "-t", "-n", "-p"], recognizedOptions: "tvwlirbspamqn")
        XCTAssertTrue(parser.hasOption("t"))
        XCTAssertTrue(parser.hasOption("n"))
        XCTAssertTrue(parser.hasOption("p"))
    }

    func testWhitespaceFixture() {
        let output = Plainizer.plainized(
            "  a  \n\tb\t  ",
            options: PlainizeOptions(
                trimTrailingWhitespace: true,
                trimLeadingWhitespace: true,
                removeInvisibleControls: false,
                removeHardWraps: false,
                removeBlankLines: false,
                removeSmartQuotes: false,
                removeConsecutiveSpaces: true,
                replaceTabs: true,
                convertToASCII: false,
                normalizeUnicode: false,
                trimWholeString: true
            )
        )

        XCTAssertEqual(output, "a\nb")
    }

    func testSmartQuotesAndASCIIFixture() {
        let output = Plainizer.plainized(
            "\u{201C}Ärger\u{201D}\u{2014}ß",
            options: PlainizeOptions(
                trimTrailingWhitespace: false,
                trimLeadingWhitespace: false,
                removeInvisibleControls: false,
                removeHardWraps: false,
                removeBlankLines: false,
                removeSmartQuotes: true,
                removeConsecutiveSpaces: false,
                replaceTabs: false,
                convertToASCII: true,
                normalizeUnicode: false,
                trimWholeString: false
            )
        )

        XCTAssertEqual(output, "\"Aerger\"-ss")
    }

    func testModernNormalizationOptionWorks() {
        let decomposed = "Cafe\u{0301}"
        let output = Plainizer.plainized(
            decomposed,
            options: PlainizeOptions(
                trimTrailingWhitespace: false,
                trimLeadingWhitespace: false,
                removeInvisibleControls: false,
                removeHardWraps: false,
                removeBlankLines: false,
                removeSmartQuotes: false,
                removeConsecutiveSpaces: false,
                replaceTabs: false,
                convertToASCII: false,
                normalizeUnicode: true,
                trimWholeString: false
            )
        )

        XCTAssertEqual(output, "Caf\u{00E9}")
    }

    func testASCIIConversionRomanizesLatinAccents() {
        let output = Plainizer.plainized(
            "\u{201C}Ärger\u{201D} café Ångström œ ß \u{2014} done\u{2026}",
            options: asciiOptions()
        )

        XCTAssertEqual(output, "\"Aerger\" cafe Angstroem oe ss - done...")
        XCTAssertASCIIOnly(output)
    }

    func testASCIIConversionRomanizesCJKAndKorean() {
        let samples = [
            "日本語\t中文",
            "한국어 中文",
            "abc 日本語 xyz"
        ]

        for sample in samples {
            let output = Plainizer.plainized(sample, options: asciiOptions())
            XCTAssertFalse(output.isEmpty, sample)
            XCTAssertASCIIOnly(output, sample)
        }
    }

    func testASCIIConversionRomanizesRTLText() {
        let samples = [
            " العربية\tالنص ",
            " עברית\tטקסט "
        ]

        for sample in samples {
            let output = Plainizer.plainized(sample, options: asciiOptions())
            XCTAssertFalse(output.isEmpty, sample)
            XCTAssertASCIIOnly(output, sample)
        }
    }

    func testASCIIConversionRomanizesCyrillicAndMixedText() {
        let output = Plainizer.plainized(
            "Україна Россия abc 日本語 xyz",
            options: asciiOptions()
        )

        XCTAssertFalse(output.isEmpty)
        XCTAssertTrue(output.contains("Ukraina"))
        XCTAssertTrue(output.contains("Rossia"))
        XCTAssertTrue(output.contains("abc"))
        XCTAssertTrue(output.contains("xyz"))
        XCTAssertASCIIOnly(output)
    }

    func testASCIIConversionDoesNotBlankUnsupportedSymbols() {
        let output = Plainizer.plainized("😀", options: asciiOptions())

        XCTAssertEqual(output, "?")
        XCTAssertASCIIOnly(output)
    }

    func testASCIIConversionFallsBackForUnsupportedContentSeparatedByWhitespace() {
        for input in ["😀 😀", "😀\n😀", " \t😀 \t"] {
            XCTAssertEqual(Plainizer.plainized(input, options: asciiOptions()), "?", input)
        }
        XCTAssertEqual(Plainizer.plainized(" \t\n ", options: asciiOptions()), "")
    }

    func testSpaceCollapsingRunsAfterASCIIConversionAndRemainsOptional() {
        var options = asciiOptions()
        XCTAssertEqual(Plainizer.plainized("a 😀 b", options: options), "a b")
        options.removeConsecutiveSpaces = false
        XCTAssertEqual(Plainizer.plainized("a 😀 b", options: options), "a  b")
    }

    func testBlankLineRemovalPreservesIndentationWithoutLineTrimming() {
        var options = PlainizeOptions.standard
        options.trimLeadingWhitespace = false
        options.trimTrailingWhitespace = false
        options.trimWholeString = false
        options.removeHardWraps = false
        options.replaceTabs = false
        options.removeConsecutiveSpaces = false
        let input = "\n  a  \n \t\n\n\tb\t\n  "
        XCTAssertEqual(Plainizer.plainized(input, options: options), "  a  \n\tb\t")
        options.removeBlankLines = false
        XCTAssertEqual(Plainizer.plainized(input, options: options), input)
    }

    func testJoiningWrappedLinesPreservesParagraphBoundaries() {
        var options = PlainizeOptions.standard
        options.removeBlankLines = false
        XCTAssertEqual(Plainizer.plainized("one\ntwo\n\nthree", options: options), "one two\n\nthree")
        options.removeBlankLines = true
        XCTAssertEqual(Plainizer.plainized("one\ntwo\n\nthree", options: options), "one two\nthree")
        options.removeHardWraps = false
        XCTAssertEqual(Plainizer.plainized("one\ntwo\n\nthree", options: options), "one\ntwo\nthree")
    }

    func testSmartPunctuationReplacementWithoutASCIIConversion() {
        var options = PlainizeOptions.standard
        let input = "“Hi” it’s—«ok» ‘yes’–done"
        XCTAssertEqual(Plainizer.plainized(input, options: options), "\"Hi\" it's-\"ok\" 'yes'-done")
        options.removeSmartQuotes = false
        XCTAssertEqual(Plainizer.plainized(input, options: options), input)
    }

    func testUnicodeExamplePreviewSampleIsCompactAndASCIIOnly() {
        let output = Plainizer.plainized("中文 한국어 العربية cafe\u{0301}", options: asciiOptions())

        XCTAssertEqual(output, "zhong wen hangug-eo al'rbyt cafe")
        XCTAssertASCIIOnly(output)
    }

    func testUnicodeExamplePreviewSampleShowsNormalizationChange() {
        let output = Plainizer.plainized(
            "中文 한국어 العربية cafe\u{0301}",
            options: PlainizeOptions(
                trimTrailingWhitespace: false,
                trimLeadingWhitespace: false,
                removeInvisibleControls: false,
                removeHardWraps: false,
                removeBlankLines: false,
                removeSmartQuotes: false,
                removeConsecutiveSpaces: false,
                replaceTabs: false,
                convertToASCII: false,
                normalizeUnicode: true,
                trimWholeString: false
            )
        )

        XCTAssertTrue(output.contains("café"))
        XCTAssertTrue(output.unicodeScalars.contains("\u{00E9}"))
        XCTAssertFalse(output.unicodeScalars.contains("\u{0301}"))
    }

    func testUnicodeExamplePreviewSamplePreservesDecomposedAccentWhenNormalizationIsDisabled() {
        let output = Plainizer.plainized(
            "中文 한국어 العربية cafe\u{0301}",
            options: .standard
        )

        XCTAssertTrue(output.unicodeScalars.contains("\u{0301}"))
        XCTAssertFalse(output.unicodeScalars.contains("\u{00E9}"))
    }

    func testNonASCIITextIsPreservedWhenASCIIConversionIsDisabled() {
        let input = " العربية\tעברית 日本語 中文 한국어 "
        let output = Plainizer.plainized(
            input,
            options: PlainizeOptions(
                trimTrailingWhitespace: false,
                trimLeadingWhitespace: false,
                removeInvisibleControls: false,
                removeHardWraps: false,
                removeBlankLines: false,
                removeSmartQuotes: false,
                removeConsecutiveSpaces: false,
                replaceTabs: false,
                convertToASCII: false,
                normalizeUnicode: false,
                trimWholeString: true
            )
        )

        XCTAssertEqual(output, "العربية\tעברית 日本語 中文 한국어")
    }

    func testPasteboardRoundTrip() {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }

        pasteboard.clearContents()
        pasteboard.setString(" a\t ", forType: .string)
        pasteboard.setData(Data([1, 2, 3]), forType: NSPasteboard.PasteboardType("com.mindflakes.plainize-clip.test"))

        let changed = PasteboardPlainizer.clean(
            pasteboard,
            options: PlainizeOptions(
                trimTrailingWhitespace: false,
                trimLeadingWhitespace: false,
                removeInvisibleControls: false,
                removeHardWraps: false,
                removeBlankLines: false,
                removeSmartQuotes: false,
                removeConsecutiveSpaces: false,
                replaceTabs: true,
                convertToASCII: false,
                normalizeUnicode: false,
                trimWholeString: true
            )
        )

        XCTAssertTrue(changed)
        XCTAssertEqual(pasteboard.string(forType: .string), "a")
        XCTAssertTrue(pasteboard.types?.contains(.string) == true)
        XCTAssertNil(pasteboard.data(forType: NSPasteboard.PasteboardType("com.mindflakes.plainize-clip.test")))
    }

    func testNonTextPasteboardIsLeftUnchanged() {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }

        let type = NSPasteboard.PasteboardType("com.mindflakes.plainize-clip.test")
        let data = Data([1, 2, 3])
        pasteboard.clearContents()
        pasteboard.setData(data, forType: type)

        XCTAssertFalse(PasteboardPlainizer.clean(pasteboard, options: .standard))
        XCTAssertEqual(pasteboard.data(forType: type), data)
        XCTAssertNil(pasteboard.string(forType: .string))
    }

    func testPasteboardRoundTripWithRTLASCIIConversion() {
        let output = cleanPasteboardString(" العربية\tעברית ", options: asciiOptions())

        XCTAssertFalse(output.isEmpty)
        XCTAssertASCIIOnly(output)
    }

    func testPasteboardRoundTripWithCJKASCIIConversion() {
        let output = cleanPasteboardString(" 日本語\t中文 한국어 ", options: asciiOptions())

        XCTAssertFalse(output.isEmpty)
        XCTAssertASCIIOnly(output)
    }

    private func asciiOptions() -> PlainizeOptions {
        PlainizeOptions(
            trimTrailingWhitespace: true,
            trimLeadingWhitespace: true,
            removeInvisibleControls: true,
            removeHardWraps: false,
            removeBlankLines: false,
            removeSmartQuotes: true,
            removeConsecutiveSpaces: true,
            replaceTabs: true,
            convertToASCII: true,
            normalizeUnicode: false,
            trimWholeString: true
        )
    }

    private func cleanPasteboardString(_ input: String, options: PlainizeOptions) -> String {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }

        pasteboard.clearContents()
        pasteboard.setString(input, forType: .string)

        XCTAssertTrue(PasteboardPlainizer.clean(pasteboard, options: options))
        let output = pasteboard.string(forType: .string) ?? ""
        XCTAssertTrue(pasteboard.types?.contains(.string) == true)
        return output
    }

    private func XCTAssertASCIIOnly(_ string: String, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            string.unicodeScalars.allSatisfy { $0.value <= 127 },
            message.isEmpty ? string : message,
            file: file,
            line: line
        )
    }
}
