# Play Console answer sheet — Sabu Saku 1.2.1

Everything Play Console asks, in the order it asks it, with the answer to
enter and the reason (so a later change in the app shows which answer it
breaks). Prepared on 17 Oct 2026 from the official Play Console Help pages
and an audit of the 1.2.1 code and merged release manifest.

- Store listing text: [`listing.md`](listing.md) (single source; paste from there).
- Images: [`out/`](out) (regenerate with `python3 -I store/make_assets.py`).
- Reviewer password: `secret/play-reviewer.txt` (gitignored). Never paste it
  anywhere but the Play Console field.
- Closed-test tester list: `secret/closed-testers.csv` (gitignored, 22 emails:
  the 20 Masis-KIR students, both penanggung jawab and Alan).

Labels are given as `English UI label` / *Indonesian UI label* where the
Indonesian one is known; the Console follows the account language.

---

## 0. Order of work and status

| # | Where | What | Status |
|---|---|---|---|
| 1 | Home | Android developer verification: `com.sabu.saku` registered | done (all apps registered) |
| 2 | Policy and programs → App content | Privacy policy, Sign-in details (App access), Ads, Content rating, Target audience, News, COVID-19, Data safety, Government, Financial, Health, Advertising ID | done 17 Oct 2026 |
| 3 | Grow users → Store presence → Store settings | Category, tags, contact | done (tags: Pendidikan, Buku & referensi) |
| 4 | Grow users → Store presence → Main store listing | Text, icon, feature graphic, screenshots (no alt-text field in the Console) | done |
| 5 | Test and release → Testing → Closed testing | Countries, testers, feedback, release 1.2.1 (4) | done (AAB uploaded by the user) |
| 6 | Test and release → Pre-launch report → Settings | Test account | not needed: uses the App access login |
| 7 | Publishing overview | Send changes for review | sent by the user, 17 Oct 2026 |
| 8 | Dashboard → Apply for production | After 12 testers × 14 days | later (§8) |

Target API (36 ✓), 16 KB page size (all `.so` aligned 16 KB ✓), Play App
Signing (on ✓, SHA-1/SHA-256 registered in Firebase ✓) need no action.

---

## 1. Account and app checks (Home / Dashboard)

| Check | Expected | Why |
|---|---|---|
| Android developer verification card → Package names | `com.sabu.saku` registered | Enforced in Indonesia since 30 Sep 2026; apps created in Play Console are registered automatically, but confirm. |
| Identity verification, contact email/phone verified | Done | Blocks publishing otherwise. |
| Managed Google Play (Advanced settings) | **Off** | Turning it on makes the app private; reverting needs a new package. |
| App or game / Free or paid | App / **Free** | Free is permanent (cannot become paid). |
| Countries/regions (closed testing and later production) | **Indonesia** only | Users are Indonesian schools. Testers count only if their Play country is Indonesia. |
| Device catalog | No exclusions | minSdk 24 decides eligibility. |
| Catalog settings (third-party US stores) | Leave default | Indonesia-only app; no effect. |

---

## 2. App content (*Konten aplikasi*)

### 2.1 Privacy policy / *Kebijakan privasi*

- URL: `https://sabusaku.web.app/privasi`
- The page names the app, the developer (Kertas Kosong), contact
  (komunitaskertaskosong9@gmail.com), data collected, use, sharing,
  retention and deletion; it is linked inside the app (Profil →
  Pengaturan → Kebijakan privasi). Public, not a PDF.

### 2.2 Sign-in details (App access) / *Akses aplikasi*

- Choice: **All or some functionality is restricted** / *Semua atau
  beberapa fungsi dibatasi*.
- **+ Add new instructions** (one set):

| Field | Value |
|---|---|
| Name | `Penanggung jawab (teacher) account` |
| Username | `benevology@gmail.com` |
| Password | from `secret/play-reviewer.txt` |
| Any other instructions | text below |
| "No other information is required" checkbox | leave unticked (the instructions explain the flow) |

```text
Sign in on the first screen with the email and password above (tap "Masuk"; do NOT use "Masuk dengan Google"). No OTP, 2-step verification, school code or location is needed, and the account works from any country. It does not expire.

This is a "penanggung jawab" (teacher) account of SMA Negeri 1 Sukodadi. On first sign-in the app shows the terms of use: tap "Saya setuju". You then see the teacher area: Dashboard, Siswa (students and their reading journals; you can comment), Buku (the shared book catalog: search, add, edit, recommend, review student suggestions, deleted books), Sekolah (class and extracurricular labels, reports "Laporan", settings) and Profil.

The student area (start a book from the catalog, daily journal, teacher comments, explore the catalog) is shown in the store screenshots; student accounts are created only for e-mails a school registers.

Reporting: the "Laporkan" menu is on comments, journals, books, suggestions and student pages. Account deletion: Profil > Hapus akun (please do not delete this review account).
```

- Also enter the same login under **Test and release → Pre-launch report →
  Settings** (§7.3).
- Credentials rules met: reusable, no expiry, no 2FA, valid worldwide,
  English instructions. Data visible to the reviewer: real school data of
  SMA Negeri 1 Sukodadi (the user chose this account, 16–17 Oct 2026).

### 2.3 Ads / *Iklan*

- **No, my app does not contain ads** / *Tidak, aplikasi saya tidak berisi iklan*.
- Proof: no ad SDKs in `pubspec.lock`; AD_ID and AdServices permissions
  removed in `android/app/src/main/AndroidManifest.xml`.

### 2.4 Content rating / *Rating konten* (IARC questionnaire)

- Email for IARC: `komunitaskertaskosong9@gmail.com`.
- Category: **Reference, News, or Educational** if offered; in the newer menu
  choose **All other app types** (*Semua jenis aplikasi lainnya*). Not
  "Social or communication": communication is not the main purpose.
- Answers (every section that appears; anything not listed → No):

| Topic | Answer | Reason |
|---|---|---|
| Violence, blood, gore, scary elements | No | No such content; book covers are standard published covers. |
| Sexuality, nudity, suggestive references, provocative outfits | No | |
| Potentially offensive language, crude humour | No | |
| Controlled substances (drugs, alcohol, tobacco) | No | |
| Gambling (real, simulated), casinos, cash payouts | No | |
| Nazi symbols / extremist content (if asked) | No | |
| **Users can interact or exchange content** (*Pengguna dapat berinteraksi*) | **Yes** | Teachers write comments on students' journals; teachers see book suggestions and catalog edits across schools. |
| All user content fully moderated before it is shown | **No** | Reported content is reviewed after the fact (PJ + developer), not pre-moderated. |
| Shares user-provided personal information with third parties | No | Firebase is a service provider; other users are not third parties. |
| Shares the user's physical location with other users | No | No location at all. |
| Digital purchases | No | Free, no in-app purchases. |
| Unrestricted internet / web browser or search engine | No | Only one external link (daftar-sekolah page) in the system browser. |
| Primarily an educational or news product (if asked) | Yes | Reading journal for schools. |

- Expected result: IARC 3+ / PEGI 3 / ESRB Everyone / USK may show 12 for
  unmoderated UGC — with the interactive element **Users Interact**.
- Retake the questionnaire if a feature changes one of these answers.

### 2.5 Target audience and content / *Target audiens dan konten*

| Step | Answer |
|---|---|
| Target age groups | **13–15**, **16–17**, **18 and over** (not 5 and under, 6–8, 9–12) |
| Why | SMA students are about 15–18 (class X can be 15); teachers are adults. Nothing is aimed at under-13s. |
| Could the store listing unintentionally appeal to children? (*appeal to children*) | **No** — school reading journal, plain education graphics, no cartoon characters or games. |
| Ads to children | Not applicable (no ads). |
| Store presence / Teacher Approved | Do not opt in (not a children's app). |

Notes for the review: 13–15 and 16–17 "may be considered children in some
locales"; Families-policy-style rules we already meet: no ads, no
advertising ID (AD_ID removed), no location, no hardware IDs, data
collected is declared in Data safety, terms of use accepted before any UGC,
in-app reporting, account deletion in app and on the web.

### 2.6 News and magazine apps

- **No** — not a news or magazine app.

### 2.7 COVID-19 contact tracing and status apps (if the card appears)

- Select the statement that the app is **not** a publicly available COVID-19
  contact tracing or status app.

### 2.8 Data safety / *Keamanan data*

Fill it in the order of the form. Basis: the 1.2.1 code (Firebase Auth,
Firestore, Storage, Functions, Messaging, Crashlytics; Analytics removed)
and Firebase's own data-disclosure page.

**Data collection and security**

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (every Firebase SDK uses TLS; no cleartext) |
| Which methods of account creation does your app support? | **Username and password** (email + password) **and OAuth** (Sign in with Google). Pick the matching labels in the live list (e.g. "Username and password", "OAuth"). |
| Delete account URL | `https://sabusaku.web.app/hapus-data` |
| Do you provide a way for users to request that some or all of their data is deleted, without requiring them to delete their account? | **Yes** (students delete journals and photos in the app; any data on request by email, see /hapus-data) |
| Committed to follow the Play Families Policy | Not applicable (no under-13 target) |
| Independent security review (MASA) | No |

**Data types** — everything not listed here is **not collected**:
Location (approximate, precise), Address, Phone number, Race and ethnicity,
Political or religious beliefs, Sexual orientation, all Financial info,
Health and fitness, Emails, SMS or MMS, Videos, all Audio, Files and docs,
Calendar, Contacts, App interactions, In-app search history, Installed apps,
Other actions, Web browsing history, Other app performance data.

For each type below: **Collected = Yes, Shared = No, Processed
ephemerally = No.**

| Category → type | Required or optional | Purposes (collected) | What it is in Sabu Saku |
|---|---|---|---|
| Personal info → **Name** | Required | App functionality, Account management | Profile name (from the school, the user, or the Google account) |
| Personal info → **Email address** | Required | App functionality, Account management | Sign-in and school roster |
| Personal info → **User IDs** | Required | App functionality, Account management | Firebase Auth UID |
| Personal info → **Other info** | Required | App functionality | Class and extracurricular labels, role, school |
| Photos and videos → **Photos** | **Optional** | App functionality | Profile photo; book cover photos (camera or gallery, cropped and compressed on the device) |
| Messages → **Other in-app messages** | Required | App functionality | Teachers' comments on student journals |
| App activity → **Other user-generated content** | Required | App functionality; Fraud prevention, security, and compliance | Reading journals and final reviews, book suggestions, catalog edits and their history, reports ("Laporkan") |
| App info and performance → **Crash logs** | Required | Analytics | Firebase Crashlytics |
| App info and performance → **Diagnostics** | Required | Analytics | Crashlytics device state (OS, model, memory) |
| Device or other IDs → **Device or other IDs** | Required | App functionality, Analytics | FCM registration token and Firebase installation ID (comment notifications); Crashlytics installation UUID (crash reports) |

Required vs optional: "optional" only where the user can use the app
without it (photos). Purposes "Analytics" for crash data = understanding
how the app performs; not shared, no advertising.

**Preview check**: the listing should show "No data shared with third
parties", "Data is encrypted in transit", "You can request that data be
deleted", and the collected categories Personal info, Photos, Messages, App
activity, App info and performance, Device or other IDs.

### 2.9 Government apps

- **No** — not developed by or on behalf of a government.

### 2.10 Financial features

- **My app doesn't provide any financial features.**

### 2.11 Health apps

- **My app doesn't provide any health features.** (Do not tick "Medical
  Reference and Education".)

### 2.12 Advertising ID

- **No**, the app does not use an advertising ID.
- Proof (must agree, Play blocks mismatches): `AD_ID`,
  `ACCESS_ADSERVICES_AD_ID`, `ACCESS_ADSERVICES_ATTRIBUTION` are removed with
  `tools:node="remove"`; Analytics is removed in 1.2.1; targetSdk 36.

### 2.13 Permission declarations

- None needed. 1.2.1 merged manifest permissions: INTERNET,
  ACCESS_NETWORK_STATE, POST_NOTIFICATIONS, WAKE_LOCK, C2DM RECEIVE (FCM),
  READ_GSERVICES (reCAPTCHA for Auth), USE_BIOMETRIC/USE_FINGERPRINT
  (androidx.biometric, unused), the app's own signature permission. No
  READ_MEDIA_*, CAMERA, FOREGROUND_SERVICE*, exact alarm, full-screen intent,
  QUERY_ALL_PACKAGES, accessibility. Confirmed in the merged manifest of the
  1.2.1 (4) release build on 17 Oct 2026; no AppMeasurement/Analytics
  component, no install-referrer service, no AD_ID.
- Photos: gallery via the system picker (ACTION_GET_CONTENT / Photo Picker),
  camera via the system camera intent — no permission requested.

### 2.14 Child safety standards (CSAE)

- **Not in scope**: the declaration applies to apps in the Social or Dating
  categories and anonymous/random chat apps. Sabu Saku is Education, has no
  chat and no anonymous users. If Play Console still shows the card, answer
  with: standards page `https://sabusaku.web.app/ketentuan` (prohibited
  content, reporting, moderation), in-app reporting = Yes ("Laporkan"),
  point of contact komunitaskertaskosong9@gmail.com.

### 2.15 Other declarations

| Item | Answer |
|---|---|
| AI-generated store-listing assets label | Not labelled (the graphics are real app screens) |
| Real-money gambling, VPN, medical device, election ads, consumer loans | Not applicable |
| Prominent disclosure | Not needed (no data use beyond what users expect) |

---

## 3. Store settings (*Setelan Play Store*)

| Field | Value |
|---|---|
| App or game | App |
| Category | **Education** / *Pendidikan* |
| Tags (up to 5, from Google's list) | Choose the closest of: Education, Reading, Books, Study tools/Student, Teacher tools. Pick only tags shown in the Console list. |
| Contact email | komunitaskertaskosong9@gmail.com |
| Phone | (leave empty) |
| Website | https://sabusaku.web.app |
| External marketing | Leave on (default) |

---

## 4. Main store listing (*Listingan Play Store utama*)

Default language: **Indonesian – id**. Paste from [`listing.md`](listing.md).

| Field | Limit | Value |
|---|---|---|
| App name | 30 | `Sabu Saku: Jurnal Membaca` (25) |
| Short description | 80 | from listing.md (count in §9) |
| Full description | 4000 | from listing.md (count in §9) |
| App icon | 512×512 PNG ≤1 MB | `out/icon-512.png` |
| Feature graphic | 1024×500 PNG/JPEG, no alpha | `out/feature-graphic.png` |
| Phone screenshots (2–8) | ≤ 2:1, 320–3840 px | `out/phone-1.png` … `phone-8.png` |
| 7-inch tablet | 16:9, 1920x1080 | `out/tablet7-1.png` … `tablet7-6.png` |
| 10-inch tablet | 16:9, 2560x1440 | `out/tablet10-1.png` … `tablet10-6.png` |
| Video | — | none |

Alt text (≤140 characters, no "photo of"/"image of"):

| Image | Alt text |
|---|---|
| feature-graphic | Logo Sabu Saku dan dua layar aplikasi: katalog buku dan beranda siswa dengan komentar guru. |
| phone-1 | Beranda siswa: buku yang sedang dibaca, progres halaman, streak, dan komentar baru dari guru. |
| phone-2 | Memulai buku dengan mencari judul di katalog buku bercover. |
| phone-3 | Jelajahi katalog: buku populer di sekolah dan daftar semua buku. |
| phone-4 | Formulir jurnal harian: halaman, lama membaca, dan isi bacaan. |
| phone-5 | Jurnal siswa dengan komentar dari penanggung jawab. |
| phone-6 | Dashboard penanggung jawab dalam tema gelap: status keaktifan siswa. |
| phone-7 | Detail buku katalog dengan tombol rekomendasi dan riwayat perubahan. |
| phone-8 | Menambah siswa ke sekolah cukup dengan email. |
| tablet7-1 / tablet10-1 | Beranda siswa di tablet. |
| tablet7-2 / tablet10-2 | Jelajahi katalog buku di tablet. |
| tablet7-3 / tablet10-3 | Detail buku dengan sinopsis di tablet. |
| tablet7-4 / tablet10-4 | Dashboard penanggung jawab dalam tema gelap di tablet. |
| tablet7-5 / tablet10-5 | Katalog buku untuk penanggung jawab di tablet. |
| tablet7-6 / tablet10-6 | Jurnal siswa dan komentar guru di tablet. |

(The lead re-checks this table against the regenerated images.)

Listing policy check: no "terbaik/#1/top/baru/gratis/diskon" claims, no
emoji, no calls to action in graphics, no testimonials, every described
feature exists in 1.2.1.

---

## 5. Closed testing (*Pengujian tertutup*) — track "Alpha"

| Setting | Value |
|---|---|
| Countries/regions | Indonesia |
| Testers | Account-wide email list "masis-kir" (34 emails since 17 Oct 2026: its 20 earlier ones plus the 14 school accounts from `secret/closed-testers.csv` it lacked). The list is shared with the account's other apps. Production needs ≥12 opted in for 14 days in a row. |
| Feedback URL or email | komunitaskertaskosong9@gmail.com |
| Opt-in link | Copy after saving; share with the testers (WhatsApp group) together with the guide `https://sabusaku.web.app/panduan.pdf`. |

**Release** (Create new release):

| Field | Value |
|---|---|
| App bundle | `build/app/outputs/bundle/release/app-release.aab` of **1.2.1 (4)** |
| Release name | `1.2.1 (4)` |
| Release notes | `<id>` … `</id>` with the 1.2.1 text from listing.md (≤500) |

Tell testers: open the opt-in link with the Google account of their
registered email, tap "Become a tester", install from Play, keep the app
installed and use it (journal) during the 14 days.

---

## 6. Release notes

Use the 1.2.1 block in [`listing.md`](listing.md). Tag line the Console
pre-fills (`<id>` or `<id-ID>`); keep it as given.

---

## 7. Other Console settings

### 7.1 Managed publishing
Optional. Off is fine for the closed test.

### 7.2 App signing
Already Play App Signing. Nothing to do. (SHA-1 3F:DA:54:2A:…:46:E9 and its
SHA-256 are registered in Firebase.)

### 7.3 Pre-launch report → Settings
Add the same reviewer login (username/password) so the robot can sign in.
Expect it to stop at the terms screen if it does not tap "Saya setuju";
that is fine.

---

## 8. Apply for production (after 12 testers × 14 consecutive days)

Draft — update the numbers on the day of applying.

**Part 1 — About your closed test**

- How easy was it to recruit testers? → "Easy. The testers are the students
  and teachers (penanggung jawab) of the school that uses the app, SMA
  Negeri 1 Sukodadi (Masis-KIR extracurricular, about 20 students and 2
  teachers). We shared the opt-in link and the illustrated guide in the
  school's group."
- How engaged were testers? → "[N] testers used the app during the test.
  Students started a book from the catalog and wrote daily reading
  journals ([N] journals in 14 days); teachers reviewed journals and wrote
  [N] comments, curated the shared catalog and reviewed book suggestions.
  This is the same usage we expect in production: one book per month per
  student, daily journals, teacher feedback."
- Feedback summary → "[fill from WhatsApp/email feedback: e.g. requests
  about …]. Collected through the school group, the feedback email in the
  listing, and in-app reports."

**Part 2 — About your app**

- Intended audience → "Indonesian senior high school students (15–18) and
  their teachers; schools are registered by the developer."
- Value → "A one-book-a-month reading programme: students keep a daily
  reading journal; teachers follow progress and give feedback; a shared
  catalog of about 1,200 Indonesian books."
- Expected installs in the first year → "100–1,000 (one school now, a few
  more schools during the year)."

**Part 3 — Production readiness**

- Changes made after the test → "[list fixes/changes from feedback]".
- How you decided it is ready → "Crash-free usage in Android vitals, all
  automated tests (unit, widget, golden, rules, functions integration,
  end-to-end on an Android emulator) pass, teachers and students completed
  the main flows (start a book, journal, comment, catalog, reports)."

---

## 9. Pre-submission checks (lead runs before filling the Console)

- [x] 1.2.1 AAB built (66.8 MB, 17 Oct 2026); merged manifest permissions
      match §2.13; no AppMeasurement/Analytics component; no AD_ID.
- [x] Character counts: name 25/30, short 74/80, full 2738/4000, release
      notes 1.2.1 386/500 (script below); no banned words.
- [ ] Live pages 200: /privasi, /ketentuan, /hapus-data, /panduan.pdf.
- [ ] `secret/play-reviewer.txt` login works in the release build (custom
      token not needed; sign in with email + password once on an emulator).
- [ ] No password in git: `git grep -n "$(sed -n 's/^password: //p' secret/play-reviewer.txt)"` returns nothing.

```sh
python3 - <<'EOF'
import re
s = open('store/listing.md').read()
name = s.split('## App name (30 characters max)')[1].strip().splitlines()[0]
short = s.split('## Short description (80 characters max)')[1].strip().splitlines()[0]
full = re.search(r'## Full description.*?```text\n(.*?)```', s, re.S).group(1).strip()
print(len(name), len(short), len(full))
for m in re.finditer(r'## Release notes of ([\d.]+).*?```text\n(.*?)```', s, re.S):
    print(m.group(1), len(m.group(2).strip()))
EOF
```

---

## 10. Open items and risks

| Item | Status / decision |
|---|---|
| Blocking users | Not implemented, by decision (17 Oct 2026): the UGC policy asks school-only apps for reporting (done); blocking is left out and handled by school moderation (PJ can remove a student; developer acts on reports). |
| Reviewer sees real school data | Accepted by the user (benevology account). |
| 12 testers / 14 days | Testers must use Play accounts registered in Indonesia and stay opted in for 14 consecutive days. |
| IARC category labels | Match the live menu (§2.4). |
| Komdigi PSE registration | The developer registers Sabu Saku as PSE (decided 17 Oct 2026); Play does not check it. |
| PP Tunas (PP 17/2025) | Left as is for now (decided 17 Oct 2026). |
| Contact email | One address everywhere: komunitaskertaskosong9@gmail.com (app, site, guide, Play listing), since 17 Oct 2026. |
| Store screenshots | Regenerated without device frames, taglines ≤20% (1.2.1). |
