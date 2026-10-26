# 📘 Panduan Menjalankan Aplikasi (Untuk Pemula)

## ⚡ CARA PALING MUDAH (sudah terpasang di laptop ini)

Semua alat (Python, library, Flutter, aplikasi web) **sudah terinstal otomatis**.
Anda hanya perlu:

1. **Double-click `MULAI APLIKASI.bat`** di Desktop
2. Browser terbuka otomatis → aplikasi siap dipakai
3. Login: klik **"Daftar sebagai Admin Baru"** → **Kode Admin** ada di file
   `Desktop\credit_risk_app\backend\.env` (buka pakai Notepad, lihat `ADMIN_SECRET_CODE`)
4. Selesai memakai: **double-click `STOP APLIKASI.bat`**

> Versi ini berjalan di **browser** (Chrome/Edge) — tidak perlu HP, kabel, atau
> Android Studio. Cocok untuk uji coba dan demo skripsi.
> Form prediksi sekarang memiliki **7 input**: usia, pekerjaan, pendapatan,
> tanggungan, pinjaman, **tabungan**, dan durasi.

---

## 🧪 Data Uji untuk Mencoba Aplikasi

### Hasil MACET dengan confidence BUKAN 100% (81,9%):

| No | Usia | Pekerjaan | Gaji | Tanggungan | Pinjaman | Tabungan | Durasi | Hasil |
|---|---|---|---|---|---|---|---|---|
| 1 | 35 | Karyawan | 6.000.000 | 2 | 50.000.000 | 2.000.000 | 120 Hari | **Macet (81,9%)** |
| 2 | 40 | Karyawan | 5.000.000 | 1 | 25.000.000 | 5.000.000 | 120 Hari | **Macet (81,9%)** |
| 3 | 25 | Buruh | 3.000.000 | 1 | 8.000.000 | 2.000.000 | 120 Hari | **Macet (81,9%)** |
| 4 | 35 | Wiraswasta | 6.000.000 | 2 | 50.000.000 | 2.000.000 | 120 Hari | **Macet (81,9%)** |

### Hasil lain untuk pembanding:

| No | Usia | Pekerjaan | Gaji | Tanggungan | Pinjaman | Tabungan | Durasi | Hasil |
|---|---|---|---|---|---|---|---|---|
| 5 | 40 | Buruh | 3.000.000 | 3 | 15.000.000 | 2.000.000 | 120 Hari | Macet (100%) |
| 6 | 45 | PNS | 8.000.000 | 2 | 10.000.000 | 10.000.000 | 300 Hari | Lancar (100%) |
| 7 | 40 | Wiraswasta | 10.000.000 | 1 | 20.000.000 | 15.000.000 | 365 Hari | Lancar (100%) |

> Catatan: pada model ini, satu-satunya hasil non-100% adalah **Macet (81,9%)**
> (29 kombinasi input, semuanya berciri: tanggungan sedikit + pinjaman besar +
> durasi pendek). Semua prediksi Lancar selalu 100%.

---

## Alternatif: menjalankan lewat terminal (satu perintah, seperti `npm run dev`)

```bash
wsl -e bash /home/wilarefa/example/aplikasi-ta/start_app.sh
```

---

## Aplikasi ini terdiri dari 2 bagian

```
┌─────────────┐         ┌──────────────────┐
│  BROWSER/HP │  ──WiFi──▶  LAPTOP (Server) │
│  aplikasi   │         │  backend Python   │
│  Flutter    │ ◀─────── │  + model C4.5    │
└─────────────┘   JSON   └──────────────────┘
```

1. **Backend (server)** → folder `backend/` (Flask + model 7 fitur + database)
2. **Aplikasi** → folder proyek Flutter (form, dashboard, riwayat, ekspor PDF)

> Urutan benar: nyalakan **server dulu**, baru aplikasinya.

---

## Menjalankan di HP Android (opsional)

1. Aktifkan **Debugging USB** di HP (*Setelan → Tentang ponsel → ketuk "Nomor
   bentukan" 7× → Opsi pengembang → Debugging USB*)
2. Sambungkan HP dengan kabel data → pilih mode *Transfer file*
3. Jalankan:
   ```
   cd Desktop\credit_risk_app
   flutter pub get
   flutter run --dart-define=API_BASE_URL=http://192.168.40.36:5000/api
   ```
   (`192.168.40.36` = IP laptop saat panduan ini dibuat — cek dengan `ipconfig`
   jika jaringan berubah; HP & laptop harus satu Wi-Fi)
4. Atau buat APK: `flutter build apk --release --dart-define=API_BASE_URL=http://<IP>:5000/api`

---

## ❗ Masalah yang Sering Terjadi

| Gejala | Penyebab & Solusi |
|---|---|
| Browser tidak muncul `{"status":"ok"}` di `localhost:5000/api/health` | Server belum menyala → jalankan `MULAI APLIKASI.bat` |
| Aplikasi terbuka tapi tidak bisa login / loading terus | Server mati, atau dibuka dari HP dengan IP salah |
| HP tidak terdeteksi `flutter devices` | Kabel bukan kabel data / Debug USB belum aktif |
| Popup Windows Defender saat server jalan | Klik **Allow/Izinkan** |

---

## 📂 Catatan Penting File & Folder

| Folder/File | Fungsi |
|---|---|
| `backend/app.py` | Kode server API (Flask) — versi 7 fitur dengan tabungan |
| `backend/model_ml/` | Model ASLI hasil training penulis skripsi (akurasi 85%) — **jangan ditimpa** |
| `backend/train_model.py` | Dokumentasi pipeline training. ⚠️ Menjalankannya MENGGANTI model & angka skripsi berubah — baca peringatan di dalamnya |
| `backend/data/Data_Nasabah.xlsx` | Dataset training 200 data KSP Pahae Jaya |
| `credit_risk_app_v1_backup` (di luar folder ini) | Versi aplikasi lama (6 fitur, tanpa tabungan) — arsip |
