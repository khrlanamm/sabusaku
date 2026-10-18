# 04 — Cloud Functions dan Alat Developer

Bahasa: TypeScript, Cloud Functions generasi ke-2, wilayah `asia-southeast2`. Gunakan versi Node.js LTS yang didukung Firebase saat proyek dibuat (cek dokumentasi). Semua logika turunan ditulis sebagai **fungsi murni yang bisa diuji tanpa Firebase** (folder `domain/`), lalu dipanggil dari trigger.

## 1. Callable (dipanggil aplikasi)

Semua callable: wajib login, periksa `role` dan `schoolId` dari token, validasi input dengan skema (mis. zod), kembalikan galat berkode (`permission-denied`, `invalid-argument`, `already-exists`) dengan pesan yang bisa diterjemahkan klien.

| Callable | Peran | Fungsi |
|---|---|---|
| `claimAccount` | siapa pun yang login | Mensyaratkan `email_verified`. Mencari `members/{email}`: tidak ada → `not-found` (`details.reason = not-registered`). Ada → pasang claims `{role, schoolId}`, buat/perbarui `users/{uid}` (profil baru diisi nama, kelas, ekskul dari `members`; profil lama dipertahankan, `status` kembali `active`; bila `photoUrl` kosong dan akun masuk dengan Google, diisi foto Google ukuran 400 px, foto yang sudah ada tidak pernah ditimpa), isi `members.uid` (pindahkan bila sebelumnya menunjuk UID lain), hitung ulang `studentStats` untuk siswa. Idempoten. Aplikasi memanggilnya setelah setiap login Google |
| `addStudents` | guru | 1–100 baris `{email, name?, classId?, extracurriculars?}`. Email dinormalkan dan divalidasi; kelas dinormalkan dengan `normalizeClassLabel` (label valid yang belum ada ditambahkan ke `schools.classes`); ekskul harus ada di daftar sekolah. `members` dibuat dengan `create()`, sehingga email yang sudah terdaftar di mana pun ditolak per baris ("Email sudah terdaftar.") tanpa menyebut sekolahnya |
| `addTeacher` | guru | Satu guru lain `{email, name, homeroomClass?, extracurriculars?}` untuk sekolah pemanggil. Nama wajib (≥ 2 karakter); wali kelas harus label yang sudah ada (tidak ditambahkan otomatis); ekskul harus ada di daftar sekolah. Email yang sudah terdaftar di mana pun → `already-exists`. Bila email itu sudah punya akun terverifikasi, langsung diklaim (`joined: true`) |
| `removeTeacher` | guru | Mengeluarkan guru lain dari sekolahnya, atau membatalkan undangan guru yang belum masuk: hapus `members`, cabut claims, `status = removed`. Menolak mengeluarkan diri sendiri (`failed-precondition`), sehingga sekolah selalu punya penanggung jawab |
| `removeStudent` | guru | Mengeluarkan siswa sekolahnya: hapus `members`, cabut claims, `revokeRefreshTokens`, `users.status = removed` (trigger menghapus `studentStats`). Jurnal tetap ada; menambahkan lagi memulihkannya |
| `eraseStudent` | guru | Menghapus `members`, profil, `studentStats`, `activePrograms`, semua program beserta jurnal dan komentar, dan foto profil siswa; mencabut claims. **Tidak** menghapus akun Auth. Konfirmasi dua langkah di UI |
| `deleteMyAccount` | siapa pun yang login | Hapus akun dari aplikasi (kebijakan Google Play). Siswa: data sama seperti `eraseStudent`. Guru: profil dan `members`. Lalu foto profil dan akun Auth |

Dihapus dari v1: `createUsers`, `resetPassword`, `setUserActive`, `setTeacherClasses`, `moveStudentClass`. Ganti kelas kini ditulis langsung ke `users.classId` (dijaga rules) dan diteruskan oleh `onUserUpdated`.

## 2. Trigger Firestore

### 2.1 `onJournalWritten` — `programs/{pid}/journals/{date}` (create/update/delete)
1. Muat semua jurnal program (≤ sekitar 60 dokumen) dan data sekolah (`settings`).
2. Hitung: `currentPage` (maks `pageEnd`), `journalCount`, `lastJournalDate`, `streakCurrent`, `streakBest` (fungsi `computeStreak`).
3. Tulis ke `programs/{pid}` (field turunan saja) dan panggil `refreshStudentStats(studentId)`.

Idempoten: menghitung ulang dari seluruh jurnal, sehingga jurnal offline yang datang tidak berurutan tetap menghasilkan angka benar. Abaikan perubahan yang hanya mengubah `hasUnreadTeacherComment` agar tidak memicu hitung ulang yang sia-sia.

### 2.2 `onProgramWritten` — `programs/{pid}`
Saat dibuat, selesai, atau dihentikan: `refreshStudentStats(studentId)` (buku aktif, `booksCompleted`, `status`).

### 2.3 `onCommentCreated` — `.../comments/{cid}`
1. Pada dokumen jurnal: `hasUnreadTeacherComment = true`, `lastCommentAt = now`.
2. Kirim FCM ke semua token siswa (`users/{uid}/devices`). Isi notifikasi: judul "Komentar dari {nama guru}", isi dipotong 80 karakter; **tanpa data sensitif tambahan**. Data payload: `type=comment`, `programId`, `date` untuk deep link. Token tidak valid dihapus.

### 2.4 `onUserUpdated` — `users/{uid}`
Bila `classId` berubah (siswa): sinkronkan ke `programs`. Bila `name`, `classId`, `extracurriculars`, `photoUrl`, `email`, atau `status` berubah: bangun ulang `studentStats` (siswa berstatus `removed` tidak punya ringkasan).

`onClassUpdated` dihapus bersama koleksi `classes`.

### 2.5 `onTeacherWritten` — `users/{uid}` (create/update/delete)
Hanya untuk guru. Bila guru bergabung, keluar, atau `name`, `homeroomClass`, `extracurriculars`, `status` berubah: bangun ulang `schools/{schoolId}.staff` (nama wali kelas per kelas dan pembina per ekskul, dari semua guru aktif) agar profil siswa bisa menampilkannya. `onSchoolUpdated` hanya bereaksi pada `settings`, jadi tidak ada putaran.

## 3. Terjadwal

| Fungsi | Jadwal | Isi |
|---|---|---|
| `dailyRefresh` | Setiap hari 00:10 WIB | Untuk semua sekolah aktif: hitung ulang `status`, `daysSinceLastJournal`, `streakCurrent` (streak bisa putus tanpa ada penulisan jurnal), `journalCountMonth` (reset awal bulan), `overdue`. Diproses per sekolah/per kelas dengan `BulkWriter` agar tahan skala |
| `teacherDigest` | Setiap hari 06:30 WIB | Untuk tiap sekolah aktif: siswa yang `statusChangedAt` dalam 24 jam terakhir dan kini `perlu_perhatian`/`tidak_aktif`. Tiap guru dengan siswa binaan (kelas perwalian atau ekskul yang dibina) di antaranya menerima satu notifikasi "N siswa binaan perlu perhatian" (kanal Android `siswa_binaan`, payload `type=attention`, membuka dashboard pada Binaan saya). Tanpa retry agar tidak terkirim dua kali |

Dijalankan juga satu kali sehari setelah tengah malam saja pada V1; pengingat harian ke siswa masuk daftar *Could*.

## 4. Logika domain (murni, diuji unit)

```
effectiveDay(d, settings) = d.weekday ∉ settings.neutralWeekdays  &&  d ∉ settings.holidays

effectiveDaysBetween(a, b]  = jumlah hari efektif setelah a sampai b (inklusif b)

computeStreak(journalDates, today, settings):
    ada  = set(journalDates)
    # streak hidup bila tidak ada hari efektif tanpa jurnal setelah tanggal terakhir sampai kemarin
    last = max(journalDates)
    bila effectiveDaysBetween(last, today - 1) > 0: current = 0
    selain itu: mundur dari `last`, hitung beruntun
        - hari efektif ada jurnal   → +1
        - hari netral               → lewati (tidak menambah, tidak memutus), kecuali ada jurnal → +1
        - hari efektif tanpa jurnal → berhenti
    best = beruntun terpanjang dalam seluruh riwayat (algoritma yang sama, dijalankan maju)

computeStatus(program, lastJournalDate, today, settings):
    tanpa program aktif                      → belum_mulai
    d = effectiveDaysBetween(lastJournalDate ?? program.startDate - 1, today)
    d ≤ activeMaxDays (3)                    → aktif
    d ≤ attentionMaxDays (7)                 → perlu_perhatian
    selain itu                               → tidak_aktif
```

Tanggal selalu diproses sebagai string `yyyy-MM-dd` dalam WIB (tanpa konversi zona waktu di dalam logika). "Hari ini" = `now + 7 jam`.

**Tabel uji unit minimal:** streak melewati Minggu; streak melewati hari libur; streak putus karena Rabu kosong; jurnal diisi mundur mengisi celah; jurnal di hari Minggu; awal bulan; siswa tanpa jurnal sama sekali; program baru dimulai hari ini; hari ini belum menulis tetapi kemarin menulis (streak tetap hidup); batas `d = 3/4/7/8`.

## 5. `refreshStudentStats(studentId)`
Satu fungsi yang membangun dokumen `studentStats` utuh dari: profil siswa, `activePrograms` → program aktif, hitungan program `completed`, 5 tanggal jurnal terakhir, `journalCountMonth`. Ditulis dengan `set` (menimpa penuh) agar tidak ada field basi. Satu pengecualian: `statusChangedAt` dibaca dari dokumen lama dalam transaksi yang sama dan dipertahankan selama `status` tidak berubah; bila berubah, diisi waktu server.

## 6. Alat developer (skrip CLI, di luar aplikasi)

Folder `functions/tools/` (Node/TypeScript, Admin SDK, service account lokal di `secret/`). Tanpa `--emulator`, skrip bekerja langsung di **produksi**; tidak ada project dev dan tidak ada sekolah demo.

| Skrip | Fungsi |
|---|---|
| `create-school --code sman1 --name "SMA Negeri 1 ..."` | Membuat `schools/sman1` dengan pengaturan default, `classes` kosong (atau dari `--classes`), dan ekstrakurikuler awal Masis-KIR, Paskibra, Pala, PMR |
| `add-guru --school sman1 --email … --name "…" [--ekskul Masis-KIR] [--wali XII-A1]` | Mendaftarkan penanggung jawab (`members`, role `guru`). Dipakai untuk penanggung jawab pertama sekolah; selanjutnya guru bisa menambah guru lain di aplikasi (`addTeacher`) |
| `remove-guru --email …` | Mengeluarkan penanggung jawab: hapus `members`, cabut claims, `status = removed` |
| `refresh-staff [--school sman1]` | Membangun ulang `schools.staff` (nama wali kelas dan pembina). Trigger `onTeacherWritten` menjaganya; skrip ini untuk guru yang sudah ada sebelum trigger dipasang |
| `import-students --school sman1 --file secret/….csv` | Impor massal siswa dari CSV `email,nama,kelas,ekskul` (ekskul dipisah `;`); kelas dinormalkan dan ditambahkan ke label sekolah |
| `set-school-status --code sman1 --status suspended` | Menangguhkan sekolah: menonaktifkan seluruh akun anggotanya dan mencabut sesi |
| `export-school --code sman1` | Ekspor data sekolah (untuk permintaan sekolah/penghapusan) |
| `delete-school --code sman1 --confirm sman1` | Menghapus sekolah, data, dan keanggotaannya |

## 7. Struktur proyek Functions

```
functions/
  src/
    index.ts                 # ekspor semua fungsi
    callables/               # claimAccount, addStudents, removeStudent, addTeacher, ...
    triggers/                # onJournalWritten, onCommentCreated, onTeacherWritten, ...
    scheduled/               # dailyRefresh, teacherDigest
    domain/                  # computeStreak, computeStatus, dateUtils (WIB), labels — tanpa dependensi Firebase
    infra/                   # akses Firestore/Auth/FCM, auth guard, validasi
  test/                      # unit domain + integrasi dengan emulator
  tools/                     # skrip developer
```

## 8. Pengujian dan operasi
- Unit test `domain/` (cepat, tanpa emulator) dengan tabel kasus di atas.
- Tes integrasi dengan Firebase Emulator Suite (Auth, Firestore, Functions), dijalankan lokal dan di CI: `addStudents` → daftar + verifikasi → `claimAccount` → buat program → tulis jurnal → cek `studentStats` terisi; `removeStudent` dan `eraseStudent` mempertahankan akun Auth.
- Alarm: galat Functions di Cloud Monitoring; log terstruktur dengan `schoolId` (bukan data siswa).
- Idempotensi dan percobaan ulang: trigger tidak boleh menggandakan efek (notifikasi komentar dikirim berdasarkan penanda `notifiedAt` pada dokumen komentar agar percobaan ulang tidak mengirim ganda).
