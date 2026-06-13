import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var preferencesWindowController: PreferencesWindowController?

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
            }
        )
        preferencesWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
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
