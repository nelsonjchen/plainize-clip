# Release Notes

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
