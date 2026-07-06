import 'package:bible_verse_scanner/services/reference_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ReferenceParser();

  test('parses a simple reference', () {
    final refs = parser.parse('For God so loved the world... John 3:16 says it all.');
    expect(refs, hasLength(1));
    expect(refs.single.book, 'John');
    expect(refs.single.chapter, 3);
    expect(refs.single.verseStart, 16);
    expect(refs.single.verseEnd, 16);
  });

  test('parses a verse range', () {
    final refs = parser.parse('Love is patient. 1 Corinthians 13:4-7');
    expect(refs, hasLength(1));
    expect(refs.single.book, '1 Corinthians');
    expect(refs.single.chapter, 13);
    expect(refs.single.verseStart, 4);
    expect(refs.single.verseEnd, 7);
  });

  test('parses common abbreviations', () {
    final refs = parser.parse('Ps 23:1 and Rom. 8:28 and Jn 1:1');
    expect(refs.map((r) => r.book), ['Psalms', 'Romans', 'John']);
  });

  test('parses numeral-prefixed books with word variants', () {
    expect(parser.parse('1 John 1:9').single.book, '1 John');
    expect(parser.parse('I John 1:9').single.book, '1 John');
    expect(parser.parse('First John 1:9').single.book, '1 John');
    expect(parser.parse('2 Cor 5:17').single.book, '2 Corinthians');
  });

  test('dedupes repeated references', () {
    final refs = parser.parse('John 3:16 ... later again John 3:16');
    expect(refs, hasLength(1));
  });

  test('returns nothing for plain text', () {
    expect(parser.parse('There is no reference in this sentence.'), isEmpty);
  });

  test('does not false-positive on ordinary numbers', () {
    expect(parser.parse('The meeting is at 3:16 today.'), isEmpty);
  });
}
