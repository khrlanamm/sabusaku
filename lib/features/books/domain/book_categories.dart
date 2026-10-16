/// Fixed book categories, in display order. Must match BOOK_CATEGORIES in
/// functions/src/domain/search.ts.
const bookCategories = [
  'Novel',
  'Sastra Klasik',
  'Remaja',
  'Puisi',
  'Kumpulan Cerpen',
  'Sejarah',
  'Biografi',
  'Agama',
  'Pengembangan Diri',
  'Sains',
  'Bisnis',
  'Komik',
  'Anak',
  'Nonfiksi Umum',
  'Lainnya',
];

/// Number of `catalog/shard-{n}` index documents.
const catalogShards = 4;
