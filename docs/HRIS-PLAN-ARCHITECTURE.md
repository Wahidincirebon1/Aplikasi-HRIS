# Rencana dan Arsitektur HRIS Kantor

**Status:** Blueprint berjalan; keputusan yang disepakati diperbarui selama implementasi  
**Skala awal:** Sekitar 150 karyawan  
**Cabang awal:** Bandung dan Surabaya  
**Zona waktu operasional:** WIB (`Asia/Jakarta`)

## 1. Ringkasan keputusan dan kebutuhan

- HRIS dibuat untuk kebutuhan kantor sendiri; tidak ada integrasi mesin absensi.
- Karyawan, atasan, HR, finance, dan superadmin adalah kelompok pengguna.
- HR membuat akun karyawan setelah memeriksa data dan identitasnya.
- Atasan cabang mengelola proses tim/cabangnya; HR pusat mengelola seluruh cabang.
- Absensi dilakukan melalui aplikasi HRIS dan memakai lokasi saat tindakan absensi.
- Geofence awal beradius 50 meter per lokasi kantor; radius dan koordinat perlu dapat diatur.
- Jadwal awal Senin–Jumat, pukul 08.30–18.00 WIB, istirahat 12.00–13.00 WIB. Sabtu dan Minggu libur.
- Jadwal dan kebijakan harus memiliki tanggal mulai berlaku agar perubahan tidak mengubah catatan historis.
- Setelah 08.30 WIB dihitung terlambat tanpa masa tenggang; menit keterlambatan dibulatkan ke menit penuh. HR menghitung potongan secara manual; HRIS tidak mengubah gaji.
- Akurasi GPS harus 30 meter atau lebih baik. Koordinat GPS karyawan tidak disimpan; hasil geofence, jarak, dan akurasi dicatat.
- Koordinat resmi Bandung dan Surabaya belum tersedia. Absensi lokasi cabang tetap nonaktif sampai HR mengonfigurasi titik kantornya.
- Koreksi absensi hanya dilakukan HR dengan alasan wajib dan jejak audit.
- Cuti bersama berlaku untuk seluruh kantor. Cuti bersama mengurangi saldo; jika hari tersebut diubah menjadi hari kerja untuk seluruh kantor, pengurangan yang sama dikembalikan.
- Hak cuti tahunan sama untuk semua karyawan pada tahun yang sama, diberikan penuh tanpa prorata sebagai hari penuh, serta ditetapkan HR setiap tahun. Instalasi awal memberi default 12 hari pada tahun kalender Jakarta saat migrasi jika kebijakan tahun itu belum dibuat; HR dapat menyesuaikan jumlahnya dan wajib menetapkan tahun-tahun berikutnya.
- Pengajuan cuti mengikuti alur karyawan → atasan → HR. Pengajuan yang masih menunggu dapat ditarik karyawan; cuti yang sudah disetujui hanya dapat dibatalkan HR dengan alasan dan audit.
- KPI memakai target tahunan dan dinilai atasan.
- Payroll otomatis dan integrasi mesin absensi tidak termasuk rilis awal.
- Aplikasi direncanakan dapat diakses melalui internet publik. Server tersedia, domain belum tersedia.
- Docker dan PostgreSQL tetap menjadi pilihan teknologi.
- Data dari aplikasi berjalan tidak perlu dimigrasikan ke aplikasi rancangan baru. Ini bukan izin untuk menghapus database atau volume yang sedang berjalan.

## 2. Sasaran produk

### Sasaran rilis awal

1. Menyediakan data karyawan terpusat—identitas/kontak, cabang, departemen, jabatan, grade, status, atasan, dan foto opsional—yang mengikuti struktur organisasi dan akses peran.
2. Mencatat absensi masuk/pulang dengan jadwal, zona waktu, dan lokasi yang jelas.
3. Menangani pengajuan koreksi absensi, cuti, izin, dan lembur melalui alur persetujuan yang dapat diaudit.
4. Mengelola hak cuti tahunan, cuti bersama, pemakaian cuti, dan pengembalian saldo dengan buku besar transaksi.
5. Memberi atasan alur untuk menyusun dan menilai KPI tahunan.
6. Menyediakan rekap bagi HR dan laporan terbatas bagi finance tanpa melakukan payroll otomatis.
7. Melindungi data pribadi melalui akses berbasis peran dan cabang.

### Di luar cakupan rilis awal

- Perhitungan atau pembayaran gaji otomatis.
- Integrasi mesin absensi fisik.
- Pelacakan GPS terus-menerus.
- Integrasi pajak, bank, akuntansi, atau manfaat karyawan sebelum kebutuhannya dikonfirmasi.

## 3. Peran dan batas akses

| Peran | Cakupan akses yang direncanakan |
|---|---|
| Karyawan | Melihat profil sendiri, melakukan absensi, melihat riwayat absensi dan saldo cuti, serta membuat pengajuan cuti/izin/lembur. |
| Atasan cabang | Melihat tim yang ditugaskan kepadanya; mengajukan layanan mandiri pribadi, menilai KPI, dan menyetujui pengajuan bawahan pada tahap manager. Tidak otomatis melihat data cabang lain. |
| HR | Mengelola seluruh cabang, menggunakan layanan mandiri pribadi, membuat akun, memperbarui data karyawan, memproses koreksi absensi dan kalender/saldo cuti, serta melihat laporan HR. Pengajuan pribadi HR ditinjau superadmin. |
| Finance | Mengakses rekap yang diperlukan untuk proses manual finance, bukan otomatis seluruh catatan pribadi atau dokumen HR. |
| Superadmin/IT | Mengelola konfigurasi sistem, role, dan akses teknis. Akses ke data HR dibatasi dan diaudit; role ini bukan pengganti HR. |

Penentuan atasan tidak boleh berasal dari pilihan bebas pada form karyawan. Hubungan atasan-karyawan ditetapkan HR dan diberi tanggal berlaku. Semua endpoint API harus memverifikasi izin di server; menyembunyikan tombol di UI saja tidak cukup.

## 4. Modul dan alur utama

### 4.1 Organisasi dan data karyawan

- Data cabang, divisi, jabatan, status kerja, tanggal mulai/akhir, dan atasan.
- Profil karyawan dengan akses minimum sesuai tugas.
- HR membuat akun; aktivasi menggunakan proses undangan atau kredensial sementara yang aman, lalu karyawan diminta mengganti password.
- Perubahan profil, cabang, jabatan, status, atasan, dan pengarsipan disimpan dalam riwayat audit.
- Pengarsipan menonaktifkan login tanpa menghapus catatan transaksi historis.

### 4.2 Absensi

- Karyawan melakukan absen masuk dan pulang melalui aplikasi.
- Waktu disimpan sebagai timestamp yang konsisten (UTC) dan ditampilkan dalam WIB.
- Setiap cabang memiliki titik kantor dan aturan geofence yang dapat diubah HR dengan tanggal berlaku.
- Aplikasi meminta lokasi hanya ketika karyawan melakukan absensi; tidak melakukan pelacakan latar belakang.
- Simpan hasil keputusan lokasi dan metadata minimum yang diperlukan, termasuk jarak serta akurasi GPS; jangan menyimpan koordinat GPS karyawan.
- Keterlambatan dihitung terhadap jam masuk yang berlaku saat itu (awal: 08.30 WIB), tanpa toleransi dan dalam menit penuh. Tidak ada pemotongan gaji otomatis.
- HR dapat mengoreksi waktu absensi dengan alasan wajib; nilai sebelum/sesudah tercatat di audit. Alur pengajuan pengecualian oleh karyawan dan persetujuan atasan/HR direncanakan pada tahap persetujuan berikutnya.
- Hindari menganggap kegagalan GPS sebagai pelanggaran otomatis; berikan pesan yang jelas dan jalur koreksi.

### 4.3 Jadwal dan kalender

- Jadwal awal: Senin–Jumat, 08.30–18.00 WIB, istirahat 12.00–13.00 WIB; akhir pekan libur.
- Simpan jadwal sebagai konfigurasi bertanggal efektif, sekurangnya menurut kantor/cabang jika kebijakan berbeda.
- Simpan kalender hari libur nasional dan cuti bersama sebagai data yang dikelola HR per tahun.
- Hari libur dan cuti bersama menutup absensi; hari yang diubah menjadi hari kerja khusus membuka absensi kembali.
- Perubahan jadwal atau kalender berlaku ke depan kecuali HR secara eksplisit membuat koreksi historis yang diaudit.

### 4.4 Cuti dan saldo cuti

Gunakan buku besar (ledger) transaksi, bukan satu angka saldo yang bisa ditimpa.

Jenis transaksi yang direncanakan:

- Hak cuti tahunan yang ditetapkan HR untuk seluruh karyawan dalam tahun tersebut.
- Hak tahunan diberikan penuh tanpa prorata dan ditetapkan dengan alasan oleh HR; perubahan kebijakan dicatat sebagai penyesuaian ledger.
- Pemakaian cuti yang telah disetujui.
- Pengurangan cuti bersama yang diterapkan secara massal.
- Pengembalian pengurangan cuti bersama bila tanggal tersebut diubah menjadi hari kerja untuk seluruh kantor.
- Penyesuaian manual HR dengan alasan dan jejak audit.

Saldo yang ditampilkan dihitung dari transaksi. Menetapkan hak cuti baru atau mengubah kalender tidak boleh diam-diam menulis ulang saldo atau menghapus riwayat.

Alur pengajuan cuti: **karyawan → atasan → HR**. Pengajuan hanya menggunakan hari kerja penuh; akhir pekan, hari libur, dan cuti bersama tidak dihitung sebagai hari yang diminta. Cuti bersama merupakan kalender perusahaan yang dibedakan dari cuti individual. Karyawan dapat menarik pengajuan yang masih menunggu; pembatalan cuti yang disetujui hanya dapat dilakukan HR dengan alasan wajib dan audit.

### 4.5 Izin, lembur, dan koreksi

- Karyawan mengajukan izin/lembur; manager/atasan menjadi tahap pertama dan HR tahap akhir. Pengajuan pribadi manager/atasan langsung ke HR; pengajuan pribadi HR ditinjau superadmin agar tidak menyetujui pengajuan sendiri.
- Karyawan, manager/atasan, dan HR dapat melihat data mandiri (profil, absensi, cuti) serta mengirim pengajuan pribadi. Persetujuan izin/lembur hanya mencatat keputusan administratif; bukan perhitungan atau persetujuan pembayaran payroll.
- Koreksi absensi diajukan langsung ke HR; tugas luar/kendala lokasi menggunakan persetujuan atasan dan pencatatan HR.
- Setiap keputusan mencatat pemohon, approver, waktu, status, alasan, dan perubahan.
- Status tidak boleh berubah tanpa validasi transisi di backend.

### 4.6 KPI tahunan

- Siklus tahunan bergerak satu arah: `planning → open → closed`; siklus yang ditutup tidak dapat dibuka kembali.
- Manager menyusun target untuk bawahan langsung dan mencatat indikator terukur dengan bobot maksimal dua angka desimal yang berjumlah tepat 100%.
- HR menyetujui dan mengunci target atau mengembalikannya untuk revisi dengan catatan; target yang telah dikunci tidak dapat diubah.
- Karyawan dan manager dapat mencatat progres selama target terkunci dan siklus masih terbuka.
- Setelah siklus ditutup, manager menilai tiap indikator pada skala 0–100 dan memberi catatan; nilai gabungan dihitung berdasarkan bobot.
- HR meninjau dan memfinalisasi nilai. Karyawan dapat mengajukan satu keberatan dalam lima hari kerja setelah finalisasi; HR memutuskan untuk mempertahankan atau menyesuaikan nilai dengan catatan.
- Keputusan target, penilaian, finalisasi, dan keberatan dicatat pada audit. Ekspor KPI dibatasi ke HR dan manager sesuai cakupan akses.

### 4.7 Laporan

Rilis awal menyediakan laporan daftar karyawan, absensi/keterlambatan, koreksi, pengajuan, saldo dan transaksi cuti, serta progres/hasil KPI dalam format CSV dan PDF. Ekspor harus mengikuti hak akses, menyertakan periode dan zona waktu, dan tidak membocorkan kolom sensitif yang tidak diperlukan. Antarmuka HR/superadmin memisahkan kalender/hak cuti, KPI, persetujuan, absensi, jadwal/lokasi, direktori, dan provisioning; antarmuka karyawan memisahkan absensi, cuti, KPI, dan profil.

## 5. Arsitektur aplikasi target

Untuk skala sekitar 150 karyawan, gunakan **modular monolith**: satu backend Go dengan batas modul yang jelas. Hindari microservices pada tahap awal agar operasi, transaksi, audit, dan backup tetap sederhana.

```text
Browser desktop/mobile
          |
        HTTPS
          |
Reverse proxy / ingress (TLS, rate limit, security headers)
          |
React web app  <---->  Go API modular
                         |
                 jaringan privat aplikasi
                         |
                    PostgreSQL

Storage privat untuk foto/dokumen
Backup terenkripsi di luar host aplikasi
```

### Komponen

- **Frontend:** React responsif untuk desktop dan browser ponsel.
- **API:** Go, dipisah secara logis menjadi auth/access, organization/employee, attendance, leave/calendar, approvals, KPI, reports, audit.
- **Database:** PostgreSQL; constraint dan transaksi untuk mencegah saldo cuti ganda atau perubahan persetujuan yang bersaing.
- **Reverse proxy:** Nginx atau ingress setara; satu-satunya layanan yang menerima trafik publik.
- **Deployment:** Docker; environment pengembangan dan produksi dipisah. Database tidak dipublikasikan ke internet.
- **Penyimpanan file:** privat, dengan validasi tipe/ukuran dan kontrol akses; hindari menyajikan file HR sebagai berkas publik.
- **Backup:** dump terenkripsi dan salinan terpisah dari server utama; uji pemulihan berkala.

Kode aplikasi yang terlihat saat ini sudah menggunakan React, Go, PostgreSQL, Docker Compose, dan Nginx. Karena tidak ada migrasi data yang diminta, skema aplikasi baru dapat dirancang bersih; komponen atau kode lama hanya digunakan kembali setelah ditinjau dan diuji. Akses lokal yang telah dikonfigurasi pada Compose saat ini tidak sama dengan deployment internet publik.

## 6. Model data inti (konseptual)

- `branches`, `departments`, `positions`
- `employees` dan riwayat penempatan/atasan yang bertanggal efektif
- `users`, `roles`, dan pemetaan izin
- `work_schedules`, `schedule_assignments`, `branch_locations`
- `holidays` dan `company_leave_days`
- `attendance_events`, `attendance_daily_records`, `attendance_correction_requests`
- `leave_policies`, `annual_leave_entitlements`, `leave_ledger_entries`, `leave_requests`
- `permission_requests`, `overtime_requests`, `approval_steps`
- `kpi_periods`, `kpi_targets`, `kpi_progress`, `kpi_reviews`
- `audit_logs`

Entitas yang mengubah saldo atau status harus menyimpan aktor, waktu, alasan, sumber/peristiwa terkait, dan status sebelum/sesudah bila sesuai. Untuk persetujuan dan saldo, gunakan transaksi database agar perubahan dan audit tercatat secara konsisten.

## 7. Keamanan dan privasi untuk akses internet

Sebelum membuka akses publik:

1. Sediakan domain dan HTTPS yang diperbarui otomatis; jangan mengirim kredensial melalui HTTP.
2. Batasi firewall ke port ingress yang diperlukan; jangan publikasikan port PostgreSQL atau API internal.
3. Simpan secret di pengelola secret/environment server yang terlindungi, bukan di repository atau image.
4. Terapkan password kuat, pembatasan percobaan login, sesi/token dengan masa berlaku yang sesuai, dan autentikasi tambahan untuk admin bila memungkinkan.
5. Verifikasi role, cabang, status akun, dan kepemilikan data pada setiap endpoint.
6. Catat perubahan HR/admin dan ekspor data; jangan pernah mencatat password, token, atau koordinat lebih lama dari kebutuhan.
7. Terapkan validasi upload, batas ukuran, perlindungan CSRF bila memakai cookie, dan kebijakan CORS minimal.
8. Enkripsi backup, batasi aksesnya, tetapkan retensi, dan lakukan uji restore.
9. Tetapkan kebijakan retensi/penghapusan data dan pemberitahuan penggunaan lokasi.
10. Jalankan review keamanan dan uji penerimaan sebelum akses internet dibuka.

Lokasi absensi merupakan data pribadi yang sensitif. Simpan dan tampilkan hanya untuk tujuan absensi, dengan akses terbatas dan periode retensi yang disepakati.

## 8. Tahapan pelaksanaan

### Tahap 0 — Finalisasi kebijakan

- Setujui pemilik proses HR, atasan cabang, dan administrator sistem.
- Tentukan koordinat dan radius final tiap kantor (50 meter adalah nilai awal).
- Tetapkan cara aktivasi akun dan pengiriman undangan/password sementara.
- Tetapkan skala/bobot KPI tahunan.
- Konfirmasi kebijakan retensi data dan lokasi.

**Hasil:** spesifikasi aturan bisnis dan matriks akses yang ditandatangani pemilik proses.

### Tahap 1 — Fondasi aman dan organisasi

- Siapkan lingkungan development/staging/production, Docker, domain/TLS, secret, backup, logging, dan monitoring.
- Bangun autentikasi, role/cakupan cabang, audit, cabang/divisi, struktur atasan, dan pembuatan akun oleh HR.

**Kriteria keluar:** uji izin lintas role/cabang lolos; backup dapat dipulihkan; endpoint internal tidak terbuka publik.

### Tahap 2 — Data karyawan dan absensi

- Profil/riwayat karyawan, pengaturan jadwal bertanggal efektif, geofence cabang, absensi masuk/pulang, rekap keterlambatan, dan koreksi HR beralasan yang diaudit.

**Kriteria keluar:** uji WIB, pergantian tanggal, akhir pekan, geofence, akurasi GPS, GPS tidak tersedia, role/cakupan cabang, dan koreksi dengan audit lolos. Koordinat kantor resmi harus diisi sebelum pilot absensi di cabang terkait.

### Tahap 3 — Cuti, izin, lembur, persetujuan

- Pengajuan dan alur karyawan → atasan → HR.
- Hak cuti tahunan penuh tanpa prorata, kalender hari libur/cuti bersama, dan ledger saldo; perubahan cuti bersama menjadi hari kerja mengembalikan debit secara otomatis.

**Kriteria keluar:** tidak ada saldo ganda saat persetujuan bersamaan; pembatalan/penyesuaian meninggalkan jejak lengkap.

### Tahap 4 — KPI dan laporan

- Siklus tahunan, target berbobot, persetujuan HR, pencatatan progres, penilaian manager, tinjauan akhir HR, keberatan karyawan, serta laporan/ekspor CSV dan PDF dengan pembatasan role dan cakupan.

**Kriteria keluar:** perhitungan dapat ditelusuri ke target/penilaian yang disetujui; tenggat keberatan mengikuti kalender hari kerja; ekspor tidak memuat data di luar izin; migrasi dan alur end-to-end terverifikasi.

### Tahap 5 — Pilot dan peluncuran

- Lokakarya lokal menggunakan data sintetis telah dipilih sebagai persiapan; ini bukan pilot karyawan. Alias sementara `127.0.0.1.nip.io` mengarah ke loopback dan bergantung pada DNS publik; port tetap terikat ke `127.0.0.1`, jadi alias tersebut hanya untuk komputer lokal, bukan domain kantor atau akses antar-cabang. Gunakan `localhost` jika alias tidak tersedia.
- Tetapkan HR lead, pemilik teknis, perwakilan atasan/karyawan di kedua cabang, kanal dukungan, serta pelatihan pergantian password, absensi, cuti, KPI, dan pelaporan insiden.
- Roster fiktif hanya contoh simulasi, bukan penunjukan: Rina Contoh (HR lead), Bima Simulasi (teknis), Dimas Sampel/Sari Uji (Bandung), dan Nadia Demo/Budi Contoh (Surabaya). Surel dan kanal dummy tidak aktif; jangan buat akun atau menganggapnya sebagai pemilik tanggung jawab aktual.
- HR harus mengonfirmasi koordinat/radius cabang, jatah cuti tahunan, kalender cuti bersama, jadwal efektif, retensi data, dan cara aman mengaktifkan akun.
- Jalankan uji penerimaan role/cakupan, absensi/geofence, cuti dan ledger, KPI/keberatan, ekspor, backup/restore, dan prosedur insiden menggunakan data sintetis atau data minimum yang disetujui.
- Catat temuan, pemilik perbaikan, hasil retest, dan persetujuan HR. Perluas penggunaan hanya setelah review keamanan, monitoring, TLS/domain, dukungan, dan backup/restore disetujui.

**Kriteria keluar:** uji penerimaan lintas kedua cabang ditandatangani HR; pemulihan dari backup diuji pada lingkungan terisolasi; personel dukungan dan prosedur insiden diketahui; tidak ada blocker keamanan atau konfigurasi kantor. Tidak boleh ada pembukaan jaringan atau pemindahan data produksi tanpa persetujuan dan rencana perubahan tersendiri.

**Payroll otomatis** hanya dipertimbangkan setelah proses HR inti stabil dan aturan payroll telah disetujui secara terpisah.

## 9. Keputusan yang masih terbuka

Tidak menghalangi pembuatan rancangan, tetapi perlu diputuskan sebelum modul terkait dibangun:

1. Koordinat resmi Bandung dan Surabaya; radius awal 50 meter dapat diatur HR.
2. Cara undangan akun dan pengiriman notifikasi (email/domain belum tersedia).
3. Kebijakan retensi untuk catatan absensi, metadata lokasi, dokumen, dan audit.
4. Pemilik pilot, daftar perwakilan dari tiap cabang, kanal/jam dukungan, dan persetujuan penerimaan HR.

## 10. Batas keselamatan perubahan

Dokumen ini adalah blueprint, bukan perintah untuk menghapus atau mengganti aplikasi/database yang berjalan. Sebelum implementasi baru, identifikasi proyek dan volume Docker yang aktif, buat backup terverifikasi, pisahkan lingkungan baru, lalu minta persetujuan eksplisit sebelum melakukan migrasi destruktif atau menghapus data.
