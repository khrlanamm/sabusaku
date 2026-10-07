import 'package:flutter_test/flutter_test.dart';
import 'package:sabusaku/core/widgets/book_cover.dart';

void main() {
  test('initials come from the first two words', () {
    expect(BookCover.initialsOf('Laskar Pelangi'), 'LP');
    expect(BookCover.initialsOf('  bumi  manusia  jilid 1 '), 'BM');
    expect(BookCover.initialsOf('Negeri'), 'N');
    expect(BookCover.initialsOf(''), '');
  });

  test('colour index is stable and ignores case and spacing', () {
    final index = BookCover.paletteIndexOf('Laskar Pelangi');
    expect(BookCover.paletteIndexOf(' laskar pelangi '), index);
    expect(index, inInclusiveRange(0, 6));
  });
}
