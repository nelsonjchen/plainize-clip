# Release Notes

## 0.3.3

- Fixed ASCII conversion emptying unsupported content separated by whitespace,
  and ensured space collapsing also handles spaces left by conversion.
- Made blank-line removal recognize whitespace-only lines independently of
  line trimming.
- Fixed the parent line-trimming checkbox to show a mixed state when only one
  direction is enabled, and kept both child controls available.
- Expanded the preferences preview to demonstrate smart punctuation and joined
  wrapped lines, and clarified the English smart-quotes label to mention dashes.
- Isolated clipboard tests from the user's clipboard and added regression tests.

## 0.3.2

- Fixed the Preferences info dialog so the whole OK button responds to clicks,
  not just the text inside it.

## 0.3.1

- Fixed the welcome dialog shown from Preferences so OK closes it reliably.
- Normalized the app bundle identifier to `com.mindflakes.plainize-clip`.
- Trimmed README maintenance details so the project page stays focused on
  downloading, using, and understanding the app.

## 0.3.0

- Added a first-run welcome dialog that explains Plainize Clip's launch, clean,
  and quit model.
- Added a preferences button to show the welcome dialog again.
- Localized the welcome dialog and its controls across the existing Tier 3
  language set.
- Moved release notes into this standalone document and added a GitHub Releases
  download link to the README.

## 0.2.0

- Added draft localizations for the preferences window across Tier 3 languages.
- Made ASCII conversion safer for non-Latin text by romanizing before filtering
  to ASCII.
- Added regression coverage for RTL, CJK, Korean, Cyrillic, and mixed-script
  pasteboard text.
