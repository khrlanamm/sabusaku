# 04 — Cloud Functions dan Alat Developer

Bahasa: TypeScript, Cloud Functions generasi ke-2, wilayah `asia-southeast2`. Gunakan versi Node.js LTS yang didukung Firebase saat proyek dibuat (cek dokumentasi). Semua logika turunan ditulis sebagai **fungsi murni yang bisa diuji tanpa Firebase** (folder `domain/`), lalu dipanggil dari trigger.

## 1. Callable (dipanggil aplikasi)

Semua callable: wajib login, periksa `role` dan `schoolId` dari token, validasi input dengan skema (mis. zod), kembalikan galat berkode (`permission-denied`, `invalid-argument`, `already-exists`) dengan pesan yang bisa diterjemahkan klien.

| Callable | Peran | Fungsi |
|---|---|---|
| `createUsers` | admin | Membuat 1–100 pengguna per panggilan (impor CSV dipecah per batch di klien). Input: `[{role, name, username, classId?/classIds?}]`. Membuat akun Auth (email semu), dokumen `users`, claims, dan `studentStats` awal untuk siswa. Mengembalikan `[{username, password}]` (password awal acak, **hanya dikembalikan sekali**). Menolak username kembar per baris dengan alasan |
| `resetPassword` | admin; guru (siswa di `classIds`-nya) | Membuat password sementara, set `mustChangePassword = true`, cabut sesi lama |
| `setUserActive` | admin | Aktif/nonaktif: `disabled` di Auth, `revokeRefreshTokens`, ubah `status` |
| `setTeacherClasses` | admin | Mengubah `users.classIds` guru, mencerminkan ke `classes.teacherIds`, memperbarui claim |
| `moveStudentClass` | admin | Mengubah `users.classId` siswa, lalu `programs.classId` dan `studentStats.classId/className` |
| `eraseStudent` | admin | Penghapusan data siswa menyeluruh (lihat dokumen 03). Disertai konfirmasi dua langkah di UI |

Batas yang diterapkan: maks 100 pengguna per `createUsers`, `classIds` ≤ 20, username `[a-z0-9._-]{3,30}`.

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
Bila `classId` berubah (siswa): sinkronkan ke `programs` dan `studentStats`. Bila nama berubah: perbarui `studentStats.name`.

## 3. Terjadwal

| Fungsi | Jadwal | Isi |
|---|---|---|
| `dailyRefresh` | Setiap hari 00:10 WIB | Untuk semua sekolah aktif: hitung ulang `status`, `daysSinceLastJournal`, `streakCurrent` (streak bisa putus tanpa ada penulisan jurnal), `journalCountMonth` (reset awal bulan), `overdue`. Diproses per sekolah/per kelas dengan `BulkWriter` agar tahan skala |

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
Satu fungsi yang membangun dokumen `studentStats` utuh dari: profil siswa, `activePrograms` → program aktif, hitungan program `completed`, 5 tanggal jurnal terakhir, `journalCountMonth`. Ditulis dengan `set` (menimpa penuh) agar tidak ada field basi.

## 6. Alat developer (skrip CLI, di luar aplikasi)

Folder `tools/` (Node/TypeScript, memakai Admin SDK dan service account lokal; tidak ikut ke klien).

| Skrip | Fungsi |
|---|---|
| `create-school --code sman1 --name "SMA Negeri 1 ..."` | Membuat `schools/sman1` dengan pengaturan default, membuat **admin pertama** (username + password awal acak, `mustChangePassword`), mencetak kredensial sekali |
| `set-school-status --code sman1 --status suspended` | Menangguhkan sekolah: menonaktifkan seluruh akun dan mencabut sesi |
| `seed-demo` | Mengisi proyek `dev` dengan sekolah demo: 2 kelas, 2 guru, 10 siswa, jurnal beberapa minggu (untuk pengembangan UI dan demo) |
| `export-school --code sman1` | Ekspor data sekolah (untuk permintaan sekolah/penghapusan) |

## 7. Struktur proyek Functions

```
functions/
  src/
    index.ts                 # ekspor semua fungsi
    callables/               # createUsers, resetPassword, ...
    triggers/                # onJournalWritten, onCommentCreated, ...
    scheduled/               # dailyRefresh
    domain/                  # computeStreak, computeStatus, dateUtils (WIB) — tanpa dependensi Firebase
    infra/                   # akses Firestore/Auth/FCM, auth guard, validasi
  test/                      # unit domain + integrasi dengan emulator
tools/                       # skrip developer
```

## 8. Pengujian dan operasi
- Unit test `domain/` (cepat, tanpa emulator) dengan tabel kasus di atas.
- Tes integrasi dengan Firebase Emulator Suite (Auth, Firestore, Functions): jalur `createUsers` → login → buat program → tulis jurnal → cek `studentStats` terisi.
- Alarm: galat Functions di Cloud Monitoring; log terstruktur dengan `schoolId` (bukan data siswa).
- Idempotensi dan percobaan ulang: trigger tidak boleh menggandakan efek (notifikasi komentar dikirim berdasarkan penanda `notifiedAt` pada dokumen komentar agar percobaan ulang tidak mengirim ganda).
