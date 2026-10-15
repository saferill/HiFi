# HiFi 2.3.1

Pembaruan HiFi v2.3.1 berfokus pada efisiensi memori, perbaikan siklus hidup aplikasi (lifecycle), kontrol penyimpanan data, dan penyederhanaan saluran pembaruan.

### 🚀 Sorotan Pembaruan:
- **Pembersihan Proses Keluar di Windows:** Saat tombol tutup (X) ditekan, engine audio libmpv dan thread latar belakang langsung dihentikan secara bersih. Tidak ada lagi musik yang tetap berbunyi atau proses hantu tertinggal di Task Manager.
- **Pengurangan Penggunaan RAM Desktop:** Penyetelan alokasi memori JVM (`-Xms48m -Xmx128m`) serta batas cache Skiko dan Coil (dikurangi dari 512 MB menjadi 32 MB) memangkas penggunaan RAM dari semula ~600 MB menjadi rata-rata 120–150 MB.
- **Manajemen Penyimpanan & Kuota Cache:** Cache audio default kini dibatasi ke 100 MB (dari sebelumnya tanpa batas) agar memori internal HP tidak cepat membengkak seiring pemakaian. Cache video Canvas Spotify juga dibatasi maksimal 25 MB.
- **Saluran Pembaruan Eksklusif GitHub Releases:** Opsi F-Droid yang tidak relevan telah dihapus dari Pengaturan, sehingga pengecekan update otomatis maupun manual langsung terhubung ke rilis resmi GitHub.
- **Dokumentasi Lengkap:** Penambahan struktur arsitektur proyek dan panduan FAQ / Troubleshooting pada README.md.
