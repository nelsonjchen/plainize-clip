import AppKit

enum PasteboardPlainizer {
    @discardableResult
    static func clean(_ pasteboard: NSPasteboard, options: PlainizeOptions) -> Bool {
        guard pasteboard.availableType(from: [.string]) == .string,
              let string = pasteboard.string(forType: .string) else {
            return false
        }

        let plain = Plainizer.plainized(string, options: options)
        pasteboard.clearContents()
        pasteboard.setString(plain, forType: .string)
        return true
    }
}
