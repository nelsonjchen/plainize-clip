import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    private static let contentSize = NSSize(width: 520, height: 520)
    private let onCancel: () -> Void

    init(options: PlainizeOptions, onSave: @escaping (PlainizeOptions) -> Void, onCancel: @escaping () -> Void) {
        self.onCancel = onCancel

        let view = PreferencesView(
            initialOptions: options,
            onSave: onSave,
            onCancel: onCancel
        )
        let hostingView = NSHostingView(rootView: view)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.contentSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Plainize Clip Preferences"
        window.titleVisibility = .hidden
        window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: Self.contentSize)).size
        window.maxSize = window.minSize
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

    @State private var options: PlainizeOptions

    let onSave: (PlainizeOptions) -> Void
    let onCancel: () -> Void

    init(initialOptions: PlainizeOptions, onSave: @escaping (PlainizeOptions) -> Void, onCancel: @escaping () -> Void) {
        _options = State(initialValue: initialOptions)
        self.onSave = onSave
        self.onCancel = onCancel
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
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            PreviewPanel(
                before: Self.sampleInput,
                after: Plainizer.plainized(Self.sampleInput, options: options)
            )

            Spacer(minLength: 0)

            HStack {
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
        .padding(EdgeInsets(top: 26, leading: 32, bottom: 34, trailing: 32))
        .frame(width: 520, height: 520)
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
        update(&options)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
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
    let before: String
    let after: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Preview")
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

    private func previewRow(_ label: String, text: String) -> some View {
        GridRow(alignment: .top) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 45, alignment: .trailing)

            Text(visible(text))
                .font(.system(size: 12, design: .monospaced))
                .lineLimit(2)
                .textSelection(.enabled)
        }
    }

    private func visible(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
