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

> Model saat ini: `min_samples_split=10`, `min_samples_leaf=5`, tanpa
> `class_weight` → **akurasi 85%**, CM `[[31, 2], [4, 3]]`, 16 daun, kedalaman 6.
> Hasil non-100% kini tersedia di **kedua kelas**.

### Hasil LANCAR dengan confidence BUKAN 100%

| No | Usia | Pekerjaan | Gaji | Tanggungan | Pinjaman | Tabungan | Durasi | Hasil |
|---|---|---|---|---|---|---|---|---|
| 1 | 35 | Buruh | 5.000.000 | 5 | 25.000.000 | 10.000.000 | 300 Hari | **Lancar (83,3%)** |
| 2 | 35 | Buruh | 5.000.000 | 1 | 25.000.000 | 10.000.000 | 120 Hari | **Lancar (80,0%)** |
| 3 | 35 | Buruh | 5.000.000 | 1 | 15.000.000 | 10.000.000 | 120 Hari | **Lancar (75,0%)** |
| 4 | 40 | PNS | 5.000.000 | 3 | 15.000.000 | 2.000.000 | 120 Hari | **Lancar (66,7%)** |
| 5 | 25 | Buruh | 3.000.000 | 1 | 25.000.000 | 10.000.000 | 300 Hari | **Lancar (57,1%)** |

### Hasil MACET dengan confidence BUKAN 100%

| No | Usia | Pekerjaan | Gaji | Tanggungan | Pinjaman | Tabungan | Durasi | Hasil |
|---|---|---|---|---|---|---|---|---|
| 6 | 35 | Buruh | 5.000.000 | 5 | 25.000.000 | 10.000.000 | 120 Hari | **Macet (83,3%)** |
| 7 | 35 | Buruh | 5.000.000 | 5 | 25.000.000 | 2.000.000 | 300 Hari | **Macet (57,1%)** |

### Hasil 100% untuk pembanding

| No | Usia | Pekerjaan | Gaji | Tanggungan | Pinjaman | Tabungan | Durasi | Hasil |
|---|---|---|---|---|---|---|---|---|
| 8 | 45 | PNS | 8.000.000 | 2 | 10.000.000 | 10.000.000 | 300 Hari | Lancar (100%) |
| 9 | 40 | Wiraswasta | 10.000.000 | 1 | 20.000.000 | 15.000.000 | 365 Hari | Lancar (100%) |

> Catatan: dari 3.402 kombinasi input, **1.149 menghasilkan Lancar non-100%**
> (83,3% · 80,0% · 75,0% · 66,7% · 57,1%) dan **378 menghasilkan Macet non-100%**
> (83,3% · 57,1%).

---

## 📊 Menguji Model — Metrik Tabel 4.23

Cara paling mudah (Windows):

1. Buka folder **`backend`**
2. Double-click **`EVALUASI MODEL.bat`**
3. Tunggu ±5 detik → muncul confusion matrix, akurasi, dan perbandingan otomatis dengan hasil acuan

Atau lewat terminal:

```bash
cd backend
python evaluasi_model.py            # ringkas
python evaluasi_model.py --detail   # + 40 baris data uji
python evaluasi_model.py --retrain  # + latih ulang dari nol
```

Hasil yang benar:

```
AKURASI : 85.0 %
Bentuk ringkas : [[31, 2], [4, 3]]
KESIMPULAN: model ini SAMA dengan hasil training ulang Colab. [OK]
```

> Jika muncul pesan `openpyxl belum terpasang`, jalankan:
> `pip install -r requirements.txt`

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
| `backend/model_ml/` | Model yang dipakai aplikasi — hasil training ulang (`split=10`, `leaf=5`), akurasi 85%, CM [[31, 2], [4, 3]] |
| `backend/model_ml_backup_asli/` | Model ASLI Colab awal (`class_weight='balanced'`, `split=2`, `leaf=1`, CM [[30, 3], [3, 4]]) — arsip pembanding |
| `backend/train_model.py` | Pipeline training model saat ini (sama dengan kode Google Colab). Menjalankannya menimpa `model_ml/` |
| `backend/evaluasi_model.py` | Menguji model & mencetak metrik (tidak mengubah apa pun) |
| `backend/EVALUASI MODEL.bat` | Tombol sekali-klik untuk menjalankan evaluasi di Windows |
| `backend/data/Data_Nasabah.xlsx` | Dataset training 200 data KSP Pahae Jaya |
| `credit_risk_app_v1_backup` (di luar folder ini) | Versi aplikasi lama (6 fitur, tanpa tabungan) — arsip |
