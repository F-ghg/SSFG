/// A parsed Bible reference, e.g. "John 3:16" or "Romans 8:28-30".
class VerseReference {
  final String book;
  final int chapter;
  final int verseStart;
  final int verseEnd;

  const VerseReference({
    required this.book,
    required this.chapter,
    required this.verseStart,
    int? verseEnd,
  }) : verseEnd = verseEnd ?? verseStart;

  bool get isRange => verseEnd > verseStart;

  /// Canonical display form, e.g. "John 3:16" or "Romans 8:28-30".
  String get display =>
      isRange ? '$book $chapter:$verseStart-$verseEnd' : '$book $chapter:$verseStart';

  @override
  bool operator ==(Object other) =>
      other is VerseReference &&
      other.book == book &&
      other.chapter == chapter &&
      other.verseStart == verseStart &&
      other.verseEnd == verseEnd;

  @override
  int get hashCode => Object.hash(book, chapter, verseStart, verseEnd);
}

/// A resolved reference paired with the looked-up verse text(s).
class ScannedVerse {
  final VerseReference reference;
  final List<String> verses;

  const ScannedVerse({required this.reference, required this.verses});

  String get combinedText => verses.join(' ');
}
