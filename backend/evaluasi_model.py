#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
evaluasi_model.py
=================
Menguji kembali model C4.5 yang dipakai aplikasi dan mencetak metrik
evaluasinya, persis seperti Tabel 4.23 - 4.26 di skripsi.

Skrip ini HANYA MEMBACA data & model. Tidak mengubah apa pun,
kecuali Anda sendiri memakai opsi --retrain.

Contoh pemakaian
----------------
    cd credit_risk_app/backend

    python3 evaluasi_model.py                  # uji model aplikasi (model_ml/)
    python3 evaluasi_model.py --detail         # + tampilkan 40 baris data uji
    python3 evaluasi_model.py --retrain        # bandingkan dgn latihan ulang dari nol
    python3 evaluasi_model.py --model model_ml_backup_asli
"""

import argparse
import sys
import warnings
from pathlib import Path

import joblib
import pandas as pd
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier

warnings.filterwarnings("ignore")

BASE = Path(__file__).resolve().parent
FILE_DATA = BASE / "data" / "Data_Nasabah.xlsx"

# Urutan fitur WAJIB sama dengan saat training
FITUR = [
    "usia_kategori",
    "pendapatan_kategori",
    "durasi_kategori",
    "tanggungan_kategori",
    "pinjaman_kategori",
    "tabungan_kategori",
    "Pekerjaan",
]

# Angka pembanding dari skripsi (Tabel 4.23 - 4.26)
TARGET = {
    "cm": [[30, 3], [3, 4]],
    "akurasi": 85.00,
    "precision_lancar": 90.91,
    "recall_lancar": 90.91,
    "precision_macet": 57.14,
    "recall_macet": 57.14,
}


# ======================================================================
# 1. ATURAN KATEGORI (sama persis dengan skrip training)
# ======================================================================
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
    return "Pendek" if x <= 180 else "Panjang"


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


# ======================================================================
# 2. MENYIAPKAN DATASET
# ======================================================================
def siapkan_dataset():
    """Baca Excel -> hitung kategori -> kembalikan (X, y, ringkasan)."""
    if not FILE_DATA.exists():
        sys.exit(f"[X] Dataset tidak ditemukan:\n    {FILE_DATA}")

    df = pd.read_excel(FILE_DATA)
    df.columns = df.columns.str.strip()

    # Pembersihan kecil, sama seperti skrip Colab asli
    df["Riwayat Pembayaran"] = df["Riwayat Pembayaran"].replace({"lacar": "lancar"})
    durasi_angka = (
        df["Durasi Pinjaman (Hari)"].astype(str).str.extract(r"(\d+)")[0].astype(int)
    )

    df["usia_kategori"] = df["Usia Nasabah"].apply(kategori_usia)
    df["pendapatan_kategori"] = df["Pendapatan Bulanan (Rp)"].apply(kategori_pendapatan)
    df["durasi_kategori"] = durasi_angka.apply(kategori_durasi)
    df["tanggungan_kategori"] = df["Jumlah Tanggungan"].apply(kategori_tanggungan)
    df["pinjaman_kategori"] = df["Jumlah Pinjaman (Rp)"].apply(kategori_pinjaman)
    df["tabungan_kategori"] = df["Tabungan (Rp)"].apply(kategori_tabungan)

    X = df[FITUR].copy()
    y = df["Riwayat Pembayaran"].astype(str).str.strip()

    ringkas = (
        f"{len(df)} baris  |  Lancar = {int((y == 'Lancar').sum())}"
        f"  |  Macet = {int((y == 'Macet').sum())}"
    )
    return X, y, ringkas


# ======================================================================
# 3. MEMUAT MODEL
# ======================================================================
def muat_model(folder):
    folder = Path(folder)
    if not folder.is_absolute():
        folder = BASE / folder

    berkas = {
        "model": folder / "decision_tree_model.pkl",
        "encoder fitur": folder / "feature_encoders.pkl",
        "encoder target": folder / "target_encoder.pkl",
    }
    for nama, path in berkas.items():
        if not path.exists():
            sys.exit(f"[X] Berkas '{nama}' tidak ditemukan:\n    {path}")

    model = joblib.load(berkas["model"])
    encoders = joblib.load(berkas["encoder fitur"])
    target_encoder = joblib.load(berkas["encoder target"])
    return model, encoders, target_encoder, folder


def encode(X, encoders):
    """Ubah kategori teks menjadi angka memakai encoder hasil training."""
    X_enc = X.copy()
    for kolom in FITUR:
        if kolom not in encoders:
            sys.exit(f"[X] Encoder untuk kolom '{kolom}' tidak ada di file .pkl")
        X_enc[kolom] = encoders[kolom].transform(X_enc[kolom])
    return X_enc


# ======================================================================
# 4. MENAMPILKAN HASIL
# ======================================================================
def garis(char="=", n=66):
    print(char * n)


def status(cocok):
    return "sama" if cocok else "BEDA"


def tampilkan(y_true, y_pred, target_encoder):
    kelas = list(target_encoder.classes_)
    cm = confusion_matrix(y_true, y_pred)
    akurasi = accuracy_score(y_true, y_pred)
    laporan = classification_report(
        y_true, y_pred, target_names=kelas, output_dict=True, zero_division=0
    )

    print("\n--- HASIL PADA DATA UJI ---")
    print("AKURASI :", round(akurasi * 100, 2), "%")

    print("\nCONFUSION MATRIX")
    print(f"{'':>18}{'prediksi ' + kelas[0]:>20}{'prediksi ' + kelas[1]:>20}")
    for i, nama in enumerate(kelas):
        print(f"{'aktual ' + nama:>18}{cm[i][0]:>20}{cm[i][1]:>20}")
    print("Bentuk ringkas :", cm.tolist())

    print("\nCLASSIFICATION REPORT")
    print(classification_report(y_true, y_pred, target_names=kelas, digits=2))
    return cm, akurasi, laporan


# ======================================================================
# 5. PROGRAM UTAMA
# ======================================================================
def main():
    p = argparse.ArgumentParser(
        description="Menguji model C4.5 dan mencetak metrik (setara Tabel 4.23-4.26)."
    )
    p.add_argument(
        "--model",
        default="model_ml",
        help="Folder berisi 3 berkas .pkl (default: model_ml)",
    )
    p.add_argument(
        "--detail",
        action="store_true",
        help="Tampilkan seluruh 40 baris data uji beserta tebakan model",
    )
    p.add_argument(
        "--retrain",
        action="store_true",
        help="Latih ulang dari nol dengan parameter skripsi, lalu bandingkan",
    )
    args = p.parse_args()

    garis()
    print("EVALUASI MODEL C4.5  -  PREDIKSI RESIKO KREDIT")
    garis()

    X, y, ringkas = siapkan_dataset()
    print(f"Dataset   : {FILE_DATA}")
    print(f"            {ringkas}")

    model, encoders, target_encoder, folder = muat_model(args.model)
    kelas = list(target_encoder.classes_)
    print(f"Model     : {folder}")
    print(f"            kelas = {kelas}")
    print(
        f"            daun = {model.get_n_leaves()}  |  kedalaman = {model.get_depth()}"
        f"  |  class_weight = {model.class_weight}"
    )
    print("            (class_weight='balanced' inilah yang membuat model peka ke Macet)")
    print("Pembagian : 80% latih / 20% uji  |  random_state=42  |  stratify")
    garis()

    # ---- encode & split (identik saat training) ----
    X_enc = encode(X, encoders)
    y_enc = target_encoder.transform(y)
    X_train, X_test, y_train, y_test = train_test_split(
        X_enc, y_enc, train_size=0.8, test_size=0.2, random_state=42, stratify=y_enc
    )
    print(f"Data latih : {len(X_train)} baris  |  data uji : {len(X_test)} baris")

    # ---- prediksi ----
    y_pred = model.predict(X_test)
    proba = model.predict_proba(X_test)
    cm, akurasi, laporan = tampilkan(y_test, y_pred, target_encoder)

    # ---- perbandingan dengan skripsi ----
    garis()
    print("PERBANDINGAN DENGAN SKRIPSI (Tabel 4.23 - 4.26)")
    garis()
    print(f"{'Metrik':<24}{'Hasil':>14}{'Skripsi':>12}{'Status':>8}")
    print("-" * 58)

    cocok_cm = cm.tolist() == TARGET["cm"]
    print(
        f"{'Confusion Matrix':<24}{str(cm.tolist()):>14}"
        f"{str(TARGET['cm']):>12}{status(cocok_cm):>8}"
    )

    def baris(nama, nilai, target):
        sesuai = abs(nilai - target) < 0.05
        print(f"{nama:<24}{f'{nilai:.2f}%':>14}{f'{target:.2f}%':>12}{status(sesuai):>8}")
        return sesuai

    semua = [cocok_cm]
    semua.append(baris("Akurasi", akurasi * 100, TARGET["akurasi"]))
    semua.append(
        baris(
            "Precision Lancar",
            laporan[kelas[0]]["precision"] * 100,
            TARGET["precision_lancar"],
        )
    )
    semua.append(
        baris("Recall Lancar", laporan[kelas[0]]["recall"] * 100, TARGET["recall_lancar"])
    )
    semua.append(
        baris(
            "Precision Macet",
            laporan[kelas[1]]["precision"] * 100,
            TARGET["precision_macet"],
        )
    )
    semua.append(
        baris("Recall Macet", laporan[kelas[1]]["recall"] * 100, TARGET["recall_macet"])
    )

    print("-" * 58)
    if all(semua):
        print("KESIMPULAN: model ini SAMA dengan yang menghasilkan Tabel 4.23-4.26.")
        print("            Seluruh angka skripsi berhasil direproduksi. [OK]")
    else:
        print("KESIMPULAN: ada angka yang BERBEDA dari skripsi.")
        print("            Periksa: versi scikit-learn, isi dataset, atau model yang dipakai.")

    # ---- detail 40 baris ----
    if args.detail:
        print()
        garis()
        print("RINCIAN 40 DATA UJI")
        garis()
        print(f"{'No':>3}  {'Aktual':<8}{'Tebakan':<8}{'Lancar%':>9}{'Macet%':>9}  Hasil")
        print("-" * 58)
        y_test_teks = target_encoder.inverse_transform(y_test)
        y_pred_teks = target_encoder.inverse_transform(y_pred)
        benar = 0
        for i, (a, pr, prob) in enumerate(zip(y_test_teks, y_pred_teks, proba), 1):
            tanda = "benar" if a == pr else "SALAH"
            if a == pr:
                benar += 1
            print(
                f"{i:>3}  {a:<8}{pr:<8}{prob[0]*100:>8.1f}%{prob[1]*100:>8.1f}%  {tanda}"
            )
        print("-" * 58)
        print(f"Total benar: {benar} dari {len(y_test)}  ->  {benar/len(y_test)*100:.2f}%")

    # ---- latih ulang dari nol ----
    if args.retrain:
        print()
        garis()
        print("LATIH ULANG DARI NOL (parameter skripsi, class_weight='balanced')")
        garis()
        model_baru = DecisionTreeClassifier(
            criterion="entropy",
            class_weight="balanced",
            max_depth=None,
            min_samples_split=2,
            min_samples_leaf=1,
            random_state=42,
        ).fit(X_train, y_train)
        pred_baru = model_baru.predict(X_test)
        cm_baru = confusion_matrix(y_test, pred_baru)
        akurasi_baru = accuracy_score(y_test, pred_baru)
        print(
            f"Daun       : {model_baru.get_n_leaves()}  |  kedalaman: {model_baru.get_depth()}"
        )
        print(f"Akurasi    : {akurasi_baru * 100:.2f}%")
        print(f"CM         : {cm_baru.tolist()}")
        print(
            f"Cocok dgn skripsi? {'YA' if cm_baru.tolist() == TARGET['cm'] else 'TIDAK'}"
        )
        print()
        print("Jika hasil ini sama, berarti resep training skripsi sudah terverifikasi")
        print("dan bisa dipakai untuk melatih ulang (mis. menambah data).")

    print()
    garis()
    print("SELESAI - tidak ada file yang diubah.")


if __name__ == "__main__":
    main()
