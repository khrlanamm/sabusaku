/// Student activity status computed by the server (PRD BR-13).
enum StudentStatus {
  aktif('aktif', 'Aktif'),
  perluPerhatian('perlu_perhatian', 'Perlu perhatian'),
  tidakAktif('tidak_aktif', 'Tidak aktif'),
  belumMulai('belum_mulai', 'Belum ada buku');

  const StudentStatus(this.wire, this.label);

  /// Value stored in Firestore.
  final String wire;
  final String label;

  static StudentStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => StudentStatus.belumMulai,
  );
}
