import AppKit
import SwiftUI

private enum PreferencesLayout {
    static let width: CGFloat = 520
    static let height: CGFloat = 700
    static let contentSize = NSSize(width: width, height: height)
}

final class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    private let onCancel: () -> Void

    init(
        options: PlainizeOptions,
        onSave: @escaping (PlainizeOptions) -> Void,
        onCancel: @escaping () -> Void,
        onShowWelcome: @escaping () -> Void
    ) {
        self.onCancel = onCancel

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: PreferencesLayout.contentSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        let view = PreferencesView(
            initialOptions: options,
            onSave: onSave,
            onCancel: onCancel,
            onShowWelcome: onShowWelcome
        )
        let hostingView = NSHostingView(rootView: view)
        window.title = String(localized: "Plainize Clip Preferences")
        window.titleVisibility = .hidden
        Self.lock(window, to: PreferencesLayout.contentSize)
        window.contentView = hostingView
        Self.installCenteredTitle(in: window)
        window.center()

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        nil
    }

    func windowWillClose(_ notification: Notification) {
        onCancel()
    }

    private static func lock(_ window: NSWindow, to contentSize: NSSize) {
        let frameSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize)).size
        window.minSize = frameSize
        window.maxSize = frameSize
    }

    private static func installCenteredTitle(in window: NSWindow) {
        guard let closeButton = window.standardWindowButton(.closeButton),
              let titlebarView = closeButton.superview else {
            return
        }

        let titleLabel = NSTextField(labelWithString: window.title)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titlebarView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: titlebarView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titlebarView.leadingAnchor, constant: 110),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: titlebarView.trailingAnchor, constant: -110)
        ])
    }
}

private struct PreferencesView: View {
    private static let sampleInput = "  \u{201C}Hello\u{201D}\t   world\u{2026}  \n\n  caf\u{00E9}\u{200B} text  "
    private static let unicodeSampleInput = String(String.UnicodeScalarView([
        UnicodeScalar(0x4E2D)!, UnicodeScalar(0x6587)!, UnicodeScalar(0x20)!,
        UnicodeScalar(0xD55C)!, UnicodeScalar(0xAD6D)!, UnicodeScalar(0xC5B4)!, UnicodeScalar(0x20)!,
        UnicodeScalar(0x0627)!, UnicodeScalar(0x0644)!, UnicodeScalar(0x0639)!, UnicodeScalar(0x0631)!,
        UnicodeScalar(0x0628)!, UnicodeScalar(0x064A)!, UnicodeScalar(0x0629)!, UnicodeScalar(0x20)!,
        UnicodeScalar(0x63)!, UnicodeScalar(0x61)!, UnicodeScalar(0x66)!, UnicodeScalar(0x65)!,
        UnicodeScalar(0x0301)!
    ]))

    @State private var options: PlainizeOptions

    let onSave: (PlainizeOptions) -> Void
    let onCancel: () -> Void
    let onShowWelcome: () -> Void

    init(
        initialOptions: PlainizeOptions,
        onSave: @escaping (PlainizeOptions) -> Void,
        onCancel: @escaping () -> Void,
        onShowWelcome: @escaping () -> Void
    ) {
        _options = State(initialValue: initialOptions)
        self.onSave = onSave
        self.onCancel = onCancel
        self.onShowWelcome = onShowWelcome
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Cleanup")
                    .font(.headline)
                Text("Choose how Plainize Clip rewrites copied text.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                SettingsSection("Whitespace") {
                    Toggle("Trim each line", isOn: lineTrimBinding)
                    HStack(spacing: 18) {
                        Toggle("Leading", isOn: optionBinding(\.trimLeadingWhitespace))
                        Toggle("Trailing", isOn: optionBinding(\.trimTrailingWhitespace))
                    }
                    .padding(.leading, 21)
                    .disabled(!options.trimLeadingWhitespace && !options.trimTrailingWhitespace)

                    Toggle("Trim whole clipboard", isOn: optionBinding(\.trimWholeString))
                    Toggle("Remove blank lines", isOn: optionBinding(\.removeBlankLines))
                    Toggle("Join wrapped lines", isOn: optionBinding(\.removeHardWraps))
                }

                SettingsSection("Characters") {
                    Toggle("Replace tabs with spaces", isOn: optionBinding(\.replaceTabs))
                    Toggle("Collapse repeated spaces", isOn: optionBinding(\.removeConsecutiveSpaces))
                    Toggle("Remove invisible control characters", isOn: optionBinding(\.removeInvisibleControls))
                    Toggle("Replace smart quotes", isOn: optionBinding(\.removeSmartQuotes))
                }

                SettingsSection("Unicode") {
                    Toggle("Normalize Unicode", isOn: optionBinding(\.normalizeUnicode))
                    Toggle("Convert to ASCII", isOn: optionBinding(\.convertToASCII))
                        .help("Non-Latin scripts are romanized best-effort.")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            PreviewPanel(
                before: Self.sampleInput,
                after: Plainizer.plainized(Self.sampleInput, options: options)
            )

            PreviewPanel(
                title: "Unicode example",
                before: PreviewTextFormatter.visible(Self.unicodeSampleInput),
                after: PreviewTextFormatter.visible(unicodeSampleOutput),
                textIsEscaped: true
            )

            Spacer(minLength: 0)

            HStack {
                Button {
                    onShowWelcome()
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
                .font(.system(size: 19))
                .foregroundStyle(.secondary)
                .help("Show welcome")

                Button {
                    NSWorkspace.shared.open(URL(string: "https://github.com/nelsonjchen/plainize-clip")!)
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(.plain)
                .font(.system(size: 19))
                .foregroundStyle(.secondary)
                .help("Open project notes")

                Spacer()

                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    onSave(options)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .toggleStyle(.checkbox)
        .padding(EdgeInsets(top: 34, leading: 32, bottom: 34, trailing: 32))
        .frame(width: PreferencesLayout.width, height: PreferencesLayout.height)
    }

    private var lineTrimBinding: Binding<Bool> {
        Binding(
            get: {
                options.trimLeadingWhitespace && options.trimTrailingWhitespace
            },
            set: { isOn in
                updateOptions {
                    $0.trimLeadingWhitespace = isOn
                    $0.trimTrailingWhitespace = isOn
                }
            }
        )
    }

    private func optionBinding(_ keyPath: WritableKeyPath<PlainizeOptions, Bool>) -> Binding<Bool> {
        Binding(
            get: {
                options[keyPath: keyPath]
            },
            set: { value in
                updateOptions {
                    $0[keyPath: keyPath] = value
                }
            }
        )
    }

    private func updateOptions(_ update: (inout PlainizeOptions) -> Void) {
        var updatedOptions = options
        update(&updatedOptions)
        options = updatedOptions
    }

    private var unicodeSampleOutput: String {
        if options.convertToASCII {
            return Plainizer.plainized(Self.unicodeSampleInput, options: options)
        }

        if options.normalizeUnicode {
            return Self.unicodeSampleInput.precomposedStringWithCanonicalMapping
        }

        return Self.unicodeSampleInput
    }
}

private enum PreviewTextFormatter {
    static func visible(_ text: String) -> String {
        var output = ""

        for scalar in text.unicodeScalars {
            if scalar == "\t" {
                output += "\\t"
            } else if scalar == "\n" {
                output += "\\n"
            } else if CharacterSet.nonBaseCharacters.contains(scalar) {
                let hex = String(scalar.value, radix: 16, uppercase: true)
                output += "\\u{" + String(repeating: "0", count: max(0, 4 - hex.count)) + hex + "}"
            } else {
                output.unicodeScalars.append(scalar)
            }
        }

        return output
    }
}

private struct SettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 5) {
                content
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PreviewPanel: View {
    let title: LocalizedStringKey
    let before: String
    let after: String
    let textIsEscaped: Bool

    init(title: LocalizedStringKey = "Preview", before: String, after: String, textIsEscaped: Bool = false) {
        self.title = title
        self.before = before
        self.after = after
        self.textIsEscaped = textIsEscaped
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                previewRow("Before", text: before)
                previewRow("After", text: after)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func previewRow(_ label: LocalizedStringKey, text: String) -> some View {
        GridRow(alignment: .top) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 45, alignment: .trailing)

            Text(displayText(for: text))
                .font(.system(size: 12, design: .monospaced))
                .lineLimit(2)
                .truncationMode(.tail)
                .textSelection(.enabled)
                .id(displayText(for: text))
        }
    }

    private func displayText(for text: String) -> String {
        textIsEscaped ? text : PreviewTextFormatter.visible(text)
    }
}
