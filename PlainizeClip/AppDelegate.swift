import AppKit
import SwiftUI

private enum WelcomeChoice {
    case cleanClipboard
    case openPreferences
    case openProjectPage
    case dismiss
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var preferencesWindowController: PreferencesWindowController?
    private var welcomeDialogController: WelcomeDialogController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        PlainizeOptions.registerDefaults()

        let arguments = ProcessInfo.processInfo.arguments
        let parser = ArgumentParser(arguments: arguments, recognizedOptions: "tvwlirbspamqn")

        if parser.hasOption("t") {
            let options = PlainizeOptions(
                trimTrailingWhitespace: parser.hasOption("w"),
                trimLeadingWhitespace: parser.hasOption("l"),
                removeInvisibleControls: parser.hasOption("i"),
                removeHardWraps: parser.hasOption("r"),
                removeBlankLines: parser.hasOption("b"),
                removeSmartQuotes: parser.hasOption("q"),
                removeConsecutiveSpaces: parser.hasOption("s"),
                replaceTabs: parser.hasOption("p"),
                convertToASCII: parser.hasOption("a"),
                normalizeUnicode: parser.hasOption("n"),
                trimWholeString: parser.hasOption("m")
            )
            runCleaner(with: options)
            NSApp.terminate(nil)
            return
        }

        if shouldOpenPreferences(arguments: arguments) {
            showPreferences()
            return
        }

        if shouldShowWelcome() {
            switch showFirstRunDialog() {
            case .cleanClipboard:
                markWelcomeShown()
                runCleaner(with: PlainizeOptions.load())
                NSApp.terminate(nil)
            case .openPreferences:
                markWelcomeShown()
                showPreferences()
            case .openProjectPage:
                markWelcomeShown()
                openProjectPage()
                NSApp.terminate(nil)
            case .dismiss:
                markWelcomeShown()
                NSApp.terminate(nil)
            }
            return
        }

        runCleaner(with: PlainizeOptions.load())
        NSApp.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func shouldOpenPreferences(arguments: [String]) -> Bool {
        if arguments.contains("--preferences") || arguments.contains("--prefs") {
            return true
        }
        return NSEvent.modifierFlags.contains(.shift)
    }

    private func shouldShowWelcome(_ defaults: UserDefaults = .standard) -> Bool {
        let value = defaults.string(forKey: "highestVersionUsed") ?? ""
        return value.isEmpty
    }

    private func markWelcomeShown(_ defaults: UserDefaults = .standard) {
        defaults.set(currentBuildVersion, forKey: "highestVersionUsed")
    }

    private var currentBuildVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }

    private func showFirstRunDialog() -> WelcomeChoice {
        WelcomeDialogController.run(buttons: [
            WelcomeDialogButton(title: String(localized: "Clean Clipboard"), choice: .cleanClipboard),
            WelcomeDialogButton(title: String(localized: "Open Preferences"), choice: .openPreferences),
            WelcomeDialogButton(title: String(localized: "GitHub"), choice: .openProjectPage),
            WelcomeDialogButton(title: String(localized: "Quit"), choice: .dismiss, isDefault: true)
        ])
    }

    private func showWelcomeInfoDialog(attachedTo parentWindow: NSWindow?) {
        let buttons = [
            WelcomeDialogButton(title: String(localized: "OK"), choice: .dismiss, isDefault: true),
            WelcomeDialogButton(title: String(localized: "GitHub"), choice: .openProjectPage)
        ]

        guard let parentWindow else {
            if WelcomeDialogController.run(buttons: buttons) == .openProjectPage {
                openProjectPage()
            }
            return
        }

        welcomeDialogController = WelcomeDialogController.presentSheet(buttons: buttons, modalFor: parentWindow) { [weak self] choice in
            self?.welcomeDialogController = nil
            if choice == .openProjectPage {
                self?.openProjectPage()
            }
        }
    }

    private func showPreferences() {
        let controller = PreferencesWindowController(
            options: PlainizeOptions.load(),
            onSave: { [weak self] options in
                options.save()
                self?.runCleaner(with: options)
                NSApp.terminate(nil)
            },
            onCancel: {
                NSApp.terminate(nil)
            },
            onShowWelcome: { [weak self] in
                self?.showWelcomeInfoDialog(attachedTo: self?.preferencesWindowController?.window)
            }
        )
        preferencesWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openProjectPage() {
        NSWorkspace.shared.open(URL(string: "https://github.com/nelsonjchen/plainize-clip")!)
    }

    @discardableResult
    private func runCleaner(with options: PlainizeOptions) -> Bool {
        let changed = PasteboardPlainizer.clean(.general, options: options)
        if !changed {
            NSSound.beep()
        }
        return changed
    }
}

private struct WelcomeDialogButton: Identifiable {
    let id = UUID()
    let title: String
    let choice: WelcomeChoice
    let isDefault: Bool

    init(title: String, choice: WelcomeChoice, isDefault: Bool = false) {
        self.title = title
        self.choice = choice
        self.isDefault = isDefault
    }
}

private final class WelcomeDialogController: NSWindowController {
    private var choice: WelcomeChoice = .dismiss

    init(buttons: [WelcomeDialogButton]) {
        let contentSize = NSSize(width: 380, height: 610)
        let window = NSPanel(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.transient]

        super.init(window: window)

        let view = WelcomeDialogView(buttons: buttons) { [weak self] choice in
            self?.finish(with: choice)
        }
        window.contentView = NSHostingView(rootView: view)
        window.center()
    }

    required init?(coder: NSCoder) {
        nil
    }

    static func run(buttons: [WelcomeDialogButton]) -> WelcomeChoice {
        let controller = WelcomeDialogController(buttons: buttons)
        guard let window = controller.window else {
            return .dismiss
        }

        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.runModal(for: window)
        return controller.choice
    }

    static func presentSheet(
        buttons: [WelcomeDialogButton],
        modalFor parentWindow: NSWindow,
        completion: @escaping (WelcomeChoice) -> Void
    ) -> WelcomeDialogController {
        let controller = WelcomeDialogController(buttons: buttons)
        guard let window = controller.window else {
            completion(.dismiss)
            return controller
        }

        parentWindow.beginSheet(window) { _ in
            window.orderOut(nil)
            controller.close()
            completion(controller.choice)
        }
        return controller
    }

    private func finish(with choice: WelcomeChoice) {
        self.choice = choice
        if let window, let sheetParent = window.sheetParent {
            sheetParent.endSheet(window)
            return
        }

        NSApp.stopModal()
        window?.orderOut(nil)
        close()
    }
}

private struct WelcomeDialogView: View {
    let buttons: [WelcomeDialogButton]
    let onSelect: (WelcomeChoice) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 82, height: 82)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                .accessibilityHidden(true)

            VStack(spacing: 16) {
                Text("Welcome to Plainize Clip")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text("Plainize Clip cleans copied text, then quits. It does not stay in the Dock or menu bar.\n\nTo change cleanup options later, hold Shift while opening Plainize Clip.\n\nThis welcome is shown once. You can show it again from Preferences.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                ForEach(buttons) { button in
                    if button.isDefault {
                        welcomeButton(button)
                            .keyboardShortcut(.defaultAction)
                    } else {
                        welcomeButton(button)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 44, leading: 34, bottom: 32, trailing: 34))
        .frame(width: 380, height: 610)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    @ViewBuilder
    private func welcomeButton(_ button: WelcomeDialogButton) -> some View {
        let buttonView = Button {
            onSelect(button.choice)
        } label: {
            Text(button.title)
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity, minHeight: 38)
        }
        .controlSize(.large)

        if button.isDefault {
            buttonView
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(Color.accentColor, in: Capsule())
                .contentShape(Capsule())
        } else {
            buttonView
                .buttonStyle(.bordered)
        }
    }
}
