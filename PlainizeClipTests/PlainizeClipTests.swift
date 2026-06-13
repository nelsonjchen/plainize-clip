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

    func testPasteboardRoundTrip() {
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot.capture(from: pasteboard)
        defer { snapshot.restore(to: pasteboard) }

        pasteboard.clearContents()
        pasteboard.setString(" a\t ", forType: .string)

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
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot.capture(from: pasteboard)
        defer { snapshot.restore(to: pasteboard) }

        let type = NSPasteboard.PasteboardType("com.mindflakes.plainize-clip.test")
        let data = Data([1, 2, 3])
        pasteboard.clearContents()
        pasteboard.setData(data, forType: type)

        XCTAssertFalse(PasteboardPlainizer.clean(pasteboard, options: .standard))
        XCTAssertEqual(pasteboard.data(forType: type), data)
        XCTAssertNil(pasteboard.string(forType: .string))
    }
}

private struct PasteboardSnapshot {
    let values: [(NSPasteboard.PasteboardType, Data)]

    static func capture(from pasteboard: NSPasteboard) -> PasteboardSnapshot {
        let values = (pasteboard.types ?? []).compactMap { type -> (NSPasteboard.PasteboardType, Data)? in
            guard let data = pasteboard.data(forType: type) else {
                return nil
            }
            return (type, data)
        }
        return PasteboardSnapshot(values: values)
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        for (type, data) in values {
            pasteboard.setData(data, forType: type)
        }
    }
}
