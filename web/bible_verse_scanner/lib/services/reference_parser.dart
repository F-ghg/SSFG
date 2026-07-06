import '../data/book_aliases.dart';
import '../models/verse_reference.dart';

/// Finds Bible verse references (e.g. "John 3:16", "1 Cor 13:4-7") inside
/// arbitrary OCR text and resolves the book aliases to canonical book names.
class ReferenceParser {
  ReferenceParser._(this._regex, this._aliasToCanonical);

  final RegExp _regex;
  final Map<String, String> _aliasToCanonical;

  static ReferenceParser? _instance;

  factory ReferenceParser() {
    return _instance ??= ReferenceParser._build();
  }

  static ReferenceParser _build() {
    final aliasToCanonical = <String, String>{
      for (final entry in bookAliases) entry.key: entry.value,
    };

    // Longest alias first so e.g. "1 corinthians" is tried before "cor".
    final sortedAliases = bookAliases.map((e) => e.key).toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final aliasPattern = sortedAliases
        .map((alias) => RegExp.escape(alias).replaceAll(' ', r'\s+'))
        .join('|');

    // (<book>) <chapter>[:.]<verse>[-<verseEnd>]
    final pattern = r'\b(' +
        aliasPattern +
        r')\.?\s*(\d{1,3})\s*[:.]\s*(\d{1,3})(?:\s*[-–—]\s*(\d{1,3}))?\b';

    return ReferenceParser._(
      RegExp(pattern, caseSensitive: false),
      aliasToCanonical,
    );
  }

  /// Returns all distinct references found in [text], in order of
  /// first appearance.
  List<VerseReference> parse(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ');
    final results = <VerseReference>[];
    final seen = <String>{};

    for (final match in _regex.allMatches(normalized)) {
      final matchedAlias = match
          .group(1)!
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toLowerCase();
      final canonical = _aliasToCanonical[matchedAlias];
      if (canonical == null) continue;

      final chapter = int.tryParse(match.group(2)!);
      final verseStart = int.tryParse(match.group(3)!);
      final verseEnd = match.group(4) != null ? int.tryParse(match.group(4)!) : null;
      if (chapter == null || verseStart == null) continue;

      final ref = VerseReference(
        book: canonical,
        chapter: chapter,
        verseStart: verseStart,
        verseEnd: verseEnd,
      );
      if (seen.add(ref.display)) {
        results.add(ref);
      }
    }
    return results;
  }
}
