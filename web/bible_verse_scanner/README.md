# Bible Verse Scanner

A Flutter mobile app that scans printed Bible verse references with the
camera and displays the verse text, fully offline.

## How it works

1. **Camera capture** (`camera` package) — live preview, user taps the
   shutter to take a photo of a printed reference (e.g. a page, bulletin,
   or sign showing "John 3:16").
2. **On-device OCR** (`google_mlkit_text_recognition`) — the captured photo
   is run through ML Kit's text recognizer entirely on-device; no image or
   text ever leaves the phone.
3. **Reference parsing** (`lib/services/reference_parser.dart`) — a regex
   built from ~570 book-name aliases (full names, standard abbreviations,
   and numeral variants like "1"/"I"/"First Corinthians") finds every verse
   reference in the recognized text.
4. **Offline lookup** (`lib/services/bible_repository.dart`) — references
   are resolved against a bundled King James Version dataset
   (`assets/bible/kjv.json`, public domain, ~4MB) with no network call.
5. **Results** are shown in a bottom sheet listing each detected reference
   and its verse text.

## Project layout

```
lib/
  models/verse_reference.dart      Parsed reference + resolved verse data classes
  data/book_aliases.dart           Generated alias -> canonical book name table
  services/reference_parser.dart   Regex-based reference extraction
  services/bible_repository.dart   Loads assets/bible/kjv.json, resolves verses
  screens/scanner_screen.dart      Camera preview + capture + OCR flow
  widgets/verse_result_sheet.dart  Bottom sheet UI for scan results
  main.dart                        Permission request + startup
assets/bible/kjv.json              Bundled public-domain KJV text
test/                              Unit tests for parsing + lookup
```

## Running

```
flutter pub get
flutter run   # needs a connected device/emulator with a camera
```

Camera permission is requested on startup (`Permission.camera` via
`permission_handler`); Android's `CAMERA` permission and iOS's
`NSCameraUsageDescription` are already declared.

## Verified in this environment

- `flutter analyze` — no issues.
- `flutter test` — parsing and offline-lookup unit tests pass, including a
  test that loads the real bundled 4MB asset and resolves real verses.

Camera/OCR behavior itself could not be exercised here since that requires
a physical device or emulator with camera hardware, and this build was
validated with the Flutter/Dart toolchain only (no Android SDK or Xcode
available in this sandbox to produce a signed APK/IPA). Before shipping,
build and test on a real device: `flutter run` on Android/iOS hardware.

## Known limitations

- Bundled translation is KJV only (public domain, offline-friendly).
  Adding other translations would mean bundling more data or adding an
  online lookup fallback.
- Reference parsing is regex-based; unusual formatting (e.g. verse lists
  like "John 3:16, 18" or non-Latin scripts) is not yet handled.
- Very short book abbreviations (e.g. "is", "am") only match when directly
  followed by a chapter:verse pattern, but could rarely false-positive on
  coincidental text like "is 3:16".
