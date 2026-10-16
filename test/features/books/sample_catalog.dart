import 'package:sabusaku/features/books/domain/catalog_book.dart';

/// A small catalog shared by the book tests.
const sampleEntries = [
  CatalogEntry(
    id: 'bk_laskar',
    title: 'Laskar Pelangi',
    authors: 'Andrea Hirata',
    pageCount: 529,
    year: 2005,
    categories: ['Novel'],
    readerCount: 12,
  ),
  CatalogEntry(
    id: 'bk_pemimpi',
    title: 'Sang Pemimpi',
    authors: 'Andrea Hirata',
    pageCount: 292,
    year: 2006,
    categories: ['Novel'],
    readerCount: 4,
  ),
  CatalogEntry(
    id: 'bk_bumi',
    title: 'Bumi Manusia',
    authors: 'Pramoedya Ananta Toer',
    pageCount: 535,
    year: 1980,
    categories: ['Sastra Klasik', 'Novel'],
    readerCount: 30,
  ),
  CatalogEntry(
    id: 'bk_cantik',
    title: 'Cantik Itu Luka',
    authors: 'Eka Kurniawan',
    pageCount: 505,
    year: 2002,
    categories: ['Novel'],
    readerCount: 2,
  ),
  CatalogEntry(
    id: 'bk_filosofi',
    title: 'Filosofi Teras',
    authors: 'Henry Manampiring',
    pageCount: 346,
    year: 2018,
    categories: ['Pengembangan Diri'],
    readerCount: 9,
  ),
  CatalogEntry(
    id: 'bk_siti',
    title: 'Siti Nurbaya: Kasih Tak Sampai',
    authors: 'Marah Rusli',
    pageCount: 271,
    year: 1922,
    categories: ['Sastra Klasik'],
  ),
  CatalogEntry(
    id: 'bk_aku',
    title: 'Aku',
    authors: 'Sjuman Djaya',
    pageCount: 154,
    year: 1987,
    categories: ['Puisi', 'Biografi'],
  ),
];

const sampleBook = CatalogBook(
  id: 'bk_laskar',
  title: 'Laskar Pelangi',
  authors: ['Andrea Hirata'],
  publisher: 'Bentang Pustaka',
  publishedYear: 2005,
  isbn13: '9789793062792',
  pageCount: 529,
  categories: ['Novel'],
  description:
      'Kisah sepuluh anak Belitong yang bersekolah di SD Muhammadiyah yang '
      'nyaris ditutup. Dipimpin Bu Mus dan Pak Harfan, mereka menamai diri '
      'Laskar Pelangi dan belajar bahwa pendidikan adalah jalan untuk '
      'mengubah nasib. Ikal, Lintang, dan Mahar menjalani persahabatan, '
      'lomba, dan mimpi besar di tengah keterbatasan pulau timah itu. Novel '
      'ini menjadi salah satu buku Indonesia paling banyak dibaca dan '
      'diadaptasi menjadi film dan drama musikal.',
  readerCount: 12,
);
