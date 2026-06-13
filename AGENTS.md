# AGENTS.md

This is a standalone macOS/Xcode project for Plainize Clip.

- Prefer standard Swift, SwiftUI, AppKit, and XCTest tooling already present in the project.
- Keep the app faceless: no Dock icon, no menu bar resident item, and no background daemon behavior.
- Preserve the normal launch model: launch, clean the pasteboard, quit.
- Use `xcodebuild` for verification before committing behavior or project changes.
