"""
⚠️ PERINGATAN — BACA DULU SEBELUM MENJALANKAN ⚠️

Script ini mendokumentasikan pipeline training model 7 fitur (dengan tabungan).
Namun model yang saat ini ter-deploy (model_ml/) adalah model ASLI hasil training
penulis skripsi yang mencapai akurasi 85% pada data uji 80:20 — pipeline persisnya
(dari Google Colab) tidak tersimpan, sehingga TIDAK dapat direproduksi persis dari
dataset saat ini (hasil training ulang = pohon berbeda, akurasi ~72,5%).

Jalankan script ini HANYA jika Anda sengaja ingin mengganti model:
  - Model lama otomatis tertimpa (backup dulu folder model_ml/ jika perlu)
  - Angka evaluasi skripsi (85%, Tabel 4.23-4.26) TIDAK berlaku lagi utk model baru
  - Setelah menjalankan, catat metrik baru (dibuat otomatis di output) dan
    perbarui skripsi.

Pipeline (sesuai skripsi — 7 fitur, Tabel 4.10):
  1. Load data/Data_Nasabah.xlsx (200 data KSP Pahae Jaya)
  2. Kategorisasi (Bab III): usia, pendapatan, durasi, tanggungan, pinjaman, tabungan
  3. Label Encoding per atribut + target (Lancar/Macet)
  4. Split 80:20 (random_state=42, stratify)
  5. DecisionTreeClassifier(criterion='entropy', random_state=42)
"""

import os

import joblib
import pandas as pd
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.tree import DecisionTreeClassifier

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(BASE_DIR, "data", "Data_Nasabah.xlsx")
ML_DIR = os.path.join(BASE_DIR, "model_ml")

FITUR = [
    "usia_kategori",
    "pendapatan_kategori",
    "durasi_kategori",
    "tanggungan_kategori",
    "pinjaman_kategori",
    "tabungan_kategori",
    "Pekerjaan",
]  # harus sama dengan FITUR_ORDER di app.py


def kategori_usia(x):
    if x <= 30:
        return "Muda"
    elif x <= 49:
        return "Dewasa"
    return "Tua"


def kategori_pendapatan(x):
    if x <= 3899000:
        return "Rendah"
    elif x <= 6999999:
        return "Menengah"
    return "Tinggi"


def kategori_durasi(x):
    # x dalam satuan HARI
    if x <= 180:
        return "Pendek"
    return "Panjang"


def kategori_tanggungan(x):
    if x <= 2:
        return "Sedikit"
    elif x <= 4:
        return "Sedang"
    return "Banyak"


def kategori_pinjaman(x):
    if x <= 12199999:
        return "Kecil"
    elif x <= 18599999:
        return "Sedang"
    return "Besar"


def kategori_tabungan(x):
    if x <= 3599999:
        return "Kecil"
    elif x <= 6499999:
        return "Sedang"
    return "Besar"


def load_dataset():
    df = pd.read_excel(DATA_PATH)
    return pd.DataFrame(
        {
            "usia_kategori": df["Usia Nasabah"].apply(kategori_usia),
            "pendapatan_kategori": df["Pendapatan Bulanan (Rp)"].apply(kategori_pendapatan),
            "durasi_kategori": df["Durasi Pinjaman (Hari)"].apply(kategori_durasi),
            "tanggungan_kategori": df["Jumlah Tanggungan"].apply(kategori_tanggungan),
            "pinjaman_kategori": df["Jumlah Pinjaman (Rp)"].apply(kategori_pinjaman),
            "tabungan_kategori": df["Tabungan (Rp)"].apply(kategori_tabungan),
            "Pekerjaan": df["Pekerjaan"].astype(str).str.strip(),
            "Riwayat Pembayaran": df["Riwayat Pembayaran"].astype(str).str.strip(),
        }
    )


def train():
    d = load_dataset()

    X = d[FITUR].copy()
    encoder_dict = {}
    for col in FITUR:
        le = LabelEncoder()
        X[col] = le.fit_transform(X[col])
        encoder_dict[col] = le

    target_encoder = LabelEncoder()
    y = target_encoder.fit_transform(d["Riwayat Pembayaran"])

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, train_size=0.8, test_size=0.2, random_state=42, stratify=y
    )

    model = DecisionTreeClassifier(
        criterion="entropy",
        max_depth=None,
        min_samples_split=10,
        min_samples_leaf=5,
        random_state=42,
    )
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    print("=" * 55)
    print("HASIL TRAINING ULANG - SPLIT 80:20 (7 fitur)")
    print("=" * 55)
    print("Confusion Matrix:")
    print(confusion_matrix(y_test, y_pred))
    print()
    print(classification_report(y_test, y_pred, target_names=target_encoder.classes_, digits=2))
    print("Akurasi: {:.2%}".format(accuracy_score(y_test, y_pred)))

    os.makedirs(ML_DIR, exist_ok=True)
    joblib.dump(model, os.path.join(ML_DIR, "decision_tree_model.pkl"))
    joblib.dump(encoder_dict, os.path.join(ML_DIR, "feature_encoders.pkl"))
    joblib.dump(target_encoder, os.path.join(ML_DIR, "target_encoder.pkl"))
    print("\nModel BARU tersimpan di:", ML_DIR)
    print("(Perbarui angka evaluasi di skripsi dengan output di atas!)")


if __name__ == "__main__":
    train()
