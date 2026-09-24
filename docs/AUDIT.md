# Audit HiFi terhadap SimpMusic

Dokumen ini mencatat apa yang belum sempurna di repo ini, apa yang sudah
diperbaiki, dan referensi SimpMusic yang dipakai untuk tiap perbaikan.

**Referensi:** [`maxrave-dev/SimpMusic`](https://github.com/maxrave-dev/SimpMusic)
(branch `dev`) beserta submodule-nya
[`maxrave-dev/core`](https://github.com/maxrave-dev/core).

Aplikasi SimpMusic adalah Compose Multiplatform; HiFi adalah Flutter. Jadi yang
diport bukan kodenya, melainkan **kontrak API dan struktur datanya** — endpoint
InnerTube, matriks client, bentuk body request, dan pohon renderer yang harus
di-parse.

---

## 1. Yang sudah diperbaiki

### 1.1 Lapisan jaringan

| Masalah di HiFi | Referensi SimpMusic | Perbaikan |
| --- | --- | --- |
| `clientVersion` dipaku ke `1.20240101.01.00` (kedaluwarsa ~2 tahun) | `models/YouTubeClient.kt` | Matriks client lengkap: `WEB_REMIX` `1.20260304.03.00`, `ANDROID_MUSIC` `7.27.52`, `IOS`, `MWEB`, `WEB` |
| Hanya satu client, tanpa cadangan | `Ytmusic.kt` (tiap endpoint menerima `client`) | `InnertubeClient` mencoba `YouTubeClient.fallbacks` berurutan, lalu melempar `InnertubeException` |
| `hl: 'en'`, `gl: 'US'` dipaku di kode | `Context.kt` + `YouTubeLocale` | `YouTubeLocale` dapat disuntik; dipakai per request |
| Header `X-Goog-Visitor-Id: ''` (kosong, tidak berguna) | `Ytmusic.kt` (`visitorData`) | `visitorData` ditangkap dari `responseContext` lalu dikirim ulang sebagai header **dan** field context |
| Endpoint hanya `search`, `next`, `player` | `Ytmusic.kt` | Ditambah `browse`, `music/get_search_suggestions`, `music/get_queue` |
| Dua file `innertube_client.dart` berdampingan (`lib/data/network/` dan `lib/core/network/`) | — | Yang lama dihapus; yang baru di `lib/core/network/` |
| `dioProvider` dideklarasikan tapi tidak pernah dibaca | — | `innertubeClientProvider` sekarang membangun client dari `dioProvider` |

### 1.2 Fitur yang belum ada, sekarang ada

| Fitur | Referensi SimpMusic | Implementasi HiFi |
| --- | --- | --- |
| Saran pencarian (typeahead) | `pages/SearchSuggestionPage.kt`, `music/get_search_suggestions` | `search_suggestion_parser.dart`, `SearchScreen` dengan debounce 250 ms |
| Halaman Home berisi carousel | `data/parser/HomeParser.kt`, `FEmusic_home` | `browse_parser.dart`, `BrowseScreen` |
| Moods & Genres | `pages/MoodAndGenres.kt`, `FEmusic_moods_and_genres_category` | Grid `MoodGenre` dengan stripe color dan tombol browse |
| Halaman album/playlist | `pages/AlbumPage.kt` | `album_parser.dart`, `AlbumScreen` (play all + shuffle) |
| Repeat mode | — | `PlaybackRepeat` (off/all/one) di `player_controller.dart` dan tombolnya di Now Playing |
| Delete gagal → tidak ada audio stream | — | Rantai fallback: extractor native dulu, lalu `StreamService` Dart. Sebelumnya `stream_service.dart` di-`ignore: unused_import` |

### 1.3 Build Android

Poin-poin ini baru ketahuan setelah CI **membangun APK**, bukan sekadar
menganalisis dan menguji `lib/` — dua pekerjaan yang berbeda.

| Masalah | Akibat | Perbaikan |
| --- | --- | --- |
| `org.jetbrains.kotlin.android` dideklarasikan `apply false` di `settings.gradle.kts` tetapi **tidak pernah di-apply** modul mana pun | `MainActivity.kt` dan `StreamExtractor.kt` tidak pernah dikompilasi. MethodChannel `com.hifi.app/stream` tidak punya handler, dan `MainActivity` — yang ditunjuk manifest — tidak ada | Plugin di-apply di `android/app/build.gradle.kts` |
| Tidak ada aturan ProGuard sama sekali | `flutter build apk --release` gagal di `:app:minifyReleaseWithR8` → `Compilation failed to complete`. R8 full mode menganggap rujukan NewPipeExtractor ke `javax.script`, `jdk.dynalink`, `java.beans`, `org.mozilla.javascript.tools` sebagai error | `android/app/proguard-rules.pro` berisi aturan yang relevan untuk dependensi HiFi, diambil dari `androidApp/proguard-rules.pro` dan `service/kotlinYtmusicScraper/proguard-rules.pro` SimpMusic |

### 1.4 Kebersihan kode

- **17 panggilan `print()`** debug (beserta 17 `// ignore: avoid_print`) dihapus.
  Diagnostik tetap ada lewat `dart:developer` `log()`.
- **Bahasa campur**: UI seluruhnya Inggris kecuali dua string Indonesia
  (`'Gagal mendapatkan audio stream…'`, `'Tidak ada lagu yang sedang diputar'`).
  Sekarang konsisten Inggris.
- **7 file `.gitkeep`** placeholder; yang direktorinya sudah berisi kode dihapus.
- **Navigasi campur**: `MaterialApp.router` tapi halaman kedua dibuka dengan
  `Navigator.push`. Sekarang seluruhnya lewat `go_router`.
- **Balapan pemutaran**: menekan dua lagu berurutan bisa membuat `setUrl` yang
  lebih lama menimpa yang lebih baru. Sekarang dijaga token `_loadToken`.

### 1.5 Pengujian

Tes lama **memanggil YouTube secara langsung** di setiap run
(`innertube_client_test`, `search_parser_test`, `radio_parser_test`,
`stream_parser_test`) sehingga hasilnya tidak deterministik dan gagal di mesin
tanpa egress. Sekarang semuanya memakai fixture; HTTP diuji lewat
`FakeHttpAdapter` (memakai `HttpClientAdapter` milik dio, tanpa paket tambahan).

`test/widget_test.dart` sebelumnya menegaskan layar pencarian sebagai halaman
utama — hal itu tidak lagi benar setelah ada tab Home, jadi tesnya diganti
dengan pengujian shell lewat `FakeMusicRepository`.

---

## 2. Yang masih belum sempurna

Diurutkan berdasarkan dampak.

### 2.1 Dependensi dideklarasikan tapi tidak dipakai

`pubspec.yaml` menyebut `audio_service: ^0.18.18`, tetapi **nol** kemunculan di
`lib/`. Akibatnya tidak ada media session Android: tidak ada kontrol di layar
kunci, tidak ada notifikasi, dan pemutaran bisa terhenti saat aplikasi ke latar.

SimpMusic menangani ini lewat `core/media/media3` dan `media-jvm` dengan
`MediaSessionService`. Untuk Flutter, `audio_service` sudah tersedia di sini —
tinggal dibuat `AudioHandler`-nya.

`cupertino_icons` juga tidak terpakai (bawaan template).

### 2.2 Belum ada lapisan persistensi sama sekali

Tidak ada riwayat putar, playlist lokal, unduhan, atau cache. `Song` juga belum
serializable, jadi respons tidak bisa disimpan. Direktori
`lib/data/datasources/`, `lib/data/models/`, `lib/domain/repositories/`, dan
`lib/domain/usecases/` masih kosong.

SimpMusic punya basis data Room lengkap di `core/data` plus `DataStoreManager`
untuk pengaturan.

### 2.3 Android

- `android:usesCleartextTraffic="true"` di manifest. Semua trafik aplikasi ini
  HTTPS; flag ini hanya memperbesar permukaan serangan.
- Tidak ada `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, jadi
  pemutaran latar tidak akan selamat di Android 14+.
- Rilis ditandatangani dengan debug key (`signingConfig = debug`). Untuk
  distribusi perlu keystore sendiri.
- `minSdk` / `targetSdk` masih mengikuti bawaan Flutter.

### 2.4 Ekstraksi stream

`StreamExtractor.kt` memakai NewPipeExtractor, dan `stream_service.dart` memakai
`youtube_explode_dart`. Keduanya disusun berurutan, tetapi tidak ada penanganan
**cipher** maupun **PO token** di sisi Dart.

SimpMusic punya paket `cipher` tersendiri
(`FaradayCipherEngine`, `QuickJsEngine`, `RemotePlayerConfigParser`,
`models/PoToken.kt`) plus `extractor/ExtractSource.kt` yang mencatat sumber mana
yang berhasil. Kalau YouTube mulai mewajibkan PO token untuk sebagian video,
HiFi akan gagal total di video itu.

### 2.5 Fitur lain yang belum ada

| Fitur SimpMusic | Modul referensi |
| --- | --- |
| Lirik tersinkron + terjemahan AI | `service/lyricsService` (SimpMusic Lyrics, LRCLIB, Spotify, transkrip YouTube) |
| Login & sinkronisasi akun YouTube Music (SAPISIDHASH) | `service/loginSync`, `Ytmusic.kt` |
| Crossfade, sleep timer, equalizer/AutoEq | `service/autoEqService`, `media/` |
| SponsorBlock, Return YouTube Dislike | `Ytmusic.getSkipSegments`, `returnYouTubeDislike` |
| Charts, podcast, halaman artis penuh | `pages/*Page.kt` |
| Unduhan offline | `Ytmusic.download` |

Catatan: `BrowseIds.charts`, `newReleases`, dan `moodsAndGenres` sudah ada di
`music_repository.dart` dan `BrowseScreen` sudah bisa merender halaman mana pun,
tetapi belum ada tombol di UI yang mengarah ke sana selain grid Moods & Genres
di Home.

### 2.6 Lain-lain

- `README.md` masih template bawaan Flutter (`# app`, "A new Flutter project").
- `analysis_options.yaml` tidak mengaktifkan lint tambahan; hanya
  `flutter_lints` bawaan.
- `analysis_options.yaml` mengecualikan `android/`, `ios/`, dan seterusnya dari
  analyzer, sehingga Dart yang mungkin ada di sana tidak pernah diperiksa.
- `data/parser/stream_parser.dart` dan `InnertubeClient.getPlayerInfo` ditandai
  *deprecated* tetapi masih dikirim dan masih diuji. Sebaiknya diputuskan:
  dipakai sebagai fallback resmi, atau dihapus.
- `AppConstants` hanya berisi `appName`.
- Belum ada `LICENSE`, `CHANGELOG`, atau `CONTRIBUTING`.
- `dynamic_color: 1.7.0` dipaku ke satu versi persis. Kalau ada alasan
  kompatibilitas, sebaiknya ditulis sebagai komentar di `pubspec.yaml`.

---

## 3. Verifikasi

Sandbox pengembangan tidak bisa memasang Flutter: `storage.googleapis.com`
(tempat SDK) dan `pub.dev` tidak dapat dijangkau, sehingga `flutter pub get`
tidak mungkin dijalankan secara lokal. Karena itu verifikasi dilakukan lewat
GitHub Actions pada runner GitHub yang punya jaringan penuh.

`.github/workflows/ci.yml` menjalankan **dua job** pada setiap push:

1. `flutter pub get` dengan channel `master` (proyek ini dibuat di channel itu
   dan `pubspec.yaml` menuntut Dart `>=3.14.0-201.0.dev`, yang belum ada di
   channel stable).
2. `dart format` per file. CI adalah pemegang format: bila ada yang berubah, CI
   membuat commit `style: apply dart format`. File yang tidak bisa di-parse
   dilaporkan sebagai anotasi beserta nama file.
3. `dart analyze --format=machine`, tiap temuan diubah menjadi anotasi check-run.
4. `flutter test --reporter json`, kegagalan juga diubah menjadi anotasi.

Langkah 3 dan 4 memakai `if: always()` supaya satu kali jalan CI bisa melaporkan
semua masalah sekaligus. Anotasi dipakai karena log workflow dilayani dari host
yang tidak selalu bisa dijangkau dari sandbox, sedangkan API anotasi bisa.

Job kedua, `build-apk`, mengompilasi aplikasinya:

5. `flutter build apk --release` di JDK 17. Error Kotlin/Gradle diubah menjadi
   anotasi; blok penyebab lengkapnya ditulis ke **step summary**, yang bisa
   dibaca utuh lewat `gh api .../check-runs/<id> --jq .output.summary` — anotasi
   hanya memuat satu baris pendek.
6. Memeriksa isi APK: `com/hifi/app/MainActivity` dan `StreamExtractor` harus ada
   di dalam dex. Ini yang menahan regresi "build hijau tapi kode Kotlin tidak
   pernah ikut dikompilasi".
7. APK diunggah sebagai artefak `hifi-release-apk` (±28 MB), bisa diunduh dari
   tab Actions di GitHub.

Nomor 6 itu penting: tanpa pemeriksaan isi, menghapus plugin Kotlin lagi akan
tetap menghasilkan build yang "berhasil".

Baca hasilnya dengan:

```bash
gh run list --branch <branch> --limit 1
# anotasi
gh api repos/<owner>/<repo>/check-runs/<id>/annotations \
  --jq '.[] | "\(.annotation_level) \(.path):\(.start_line) \(.title)"'
# ringkasan, termasuk blok penyebab Gradle
gh api repos/<owner>/<repo>/check-runs/<id> --jq .output.summary
```
