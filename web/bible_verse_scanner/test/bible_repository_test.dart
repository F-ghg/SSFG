import 'package:bible_verse_scanner/models/verse_reference.dart';
import 'package:bible_verse_scanner/services/bible_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibleRepository bible;

  setUpAll(() async {
    bible = await BibleRepository.load();
  });

  test('resolves a well-known verse', () {
    final result = bible.resolve(
      const VerseReference(book: 'John', chapter: 3, verseStart: 16),
    );
    expect(result, isNotNull);
    expect(result!.combinedText, contains('For God so loved the world'));
  });

  test('resolves a verse range', () {
    final result = bible.resolve(
      const VerseReference(book: '1 Corinthians', chapter: 13, verseStart: 4, verseEnd: 7),
    );
    expect(result, isNotNull);
    expect(result!.verses, hasLength(4));
    expect(result.verses.first, contains('Charity suffereth long'));
  });

  test('returns null for an out-of-range verse', () {
    final result = bible.resolve(
      const VerseReference(book: 'John', chapter: 3, verseStart: 9999),
    );
    expect(result, isNull);
  });

  test('returns null for an unknown book', () {
    final result = bible.resolve(
      const VerseReference(book: 'NotABook', chapter: 1, verseStart: 1),
    );
    expect(result, isNull);
  });

  test('all 66 canonical books are present', () {
    expect(bible.bookNames, hasLength(66));
  });
}
