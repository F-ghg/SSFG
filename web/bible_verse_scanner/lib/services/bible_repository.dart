import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/verse_reference.dart';

/// Loads the bundled public-domain KJV text (assets/bible/kjv.json) and
/// answers verse lookups fully offline.
class BibleRepository {
  BibleRepository._(this._chaptersByBook, this.translation);

  final Map<String, List<List<String>>> _chaptersByBook;
  final String translation;

  static BibleRepository? _instance;

  /// Loads and caches the bundled Bible data. Safe to call repeatedly.
  static Future<BibleRepository> load() async {
    if (_instance != null) return _instance!;
    final raw = await rootBundle.loadString('assets/bible/kjv.json');
    final Map<String, dynamic> decoded = json.decode(raw) as Map<String, dynamic>;
    final books = decoded['books'] as List<dynamic>;
    final map = <String, List<List<String>>>{};
    for (final b in books) {
      final book = b as Map<String, dynamic>;
      final name = book['name'] as String;
      final chapters = (book['chapters'] as List<dynamic>)
          .map((c) => (c as List<dynamic>).cast<String>())
          .toList();
      map[name] = chapters;
    }
    _instance = BibleRepository._(map, decoded['translation'] as String? ?? 'KJV');
    return _instance!;
  }

  /// All canonical book names, in Bible order.
  List<String> get bookNames => _chaptersByBook.keys.toList(growable: false);

  bool hasBook(String canonicalName) => _chaptersByBook.containsKey(canonicalName);

  /// Resolves a [VerseReference] to its verse text(s), or null if the
  /// book/chapter/verse is out of range (e.g. OCR misread a number).
  ScannedVerse? resolve(VerseReference ref) {
    final chapters = _chaptersByBook[ref.book];
    if (chapters == null) return null;
    if (ref.chapter < 1 || ref.chapter > chapters.length) return null;
    final verses = chapters[ref.chapter - 1];
    final start = ref.verseStart;
    final end = ref.verseEnd;
    if (start < 1 || start > verses.length) return null;
    final clampedEnd = end > verses.length ? verses.length : end;
    final text = verses.sublist(start - 1, clampedEnd);
    return ScannedVerse(reference: ref, verses: text);
  }
}
