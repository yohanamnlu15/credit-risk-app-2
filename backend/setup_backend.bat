@echo off
chcp 65001 >nul
title Setup Backend CrediPredict
echo ==================================================
echo   SETUP BACKEND CREDIPREDICT
echo   (Script ini cukup dijalankan SEKALI saja)
echo ==================================================
echo.

where python >nul 2>nul
if errorlevel 1 (
    echo [GAGAL] Python belum terinstall atau tidak ada di PATH.
    echo.
    echo Cara memperbaiki:
    echo   1. Download installer dari https://www.python.org/downloads/
    echo   2. Saat instalasi, WAJIB mencentang "Add python.exe to PATH"
    echo   3. Setelah selesai, jalankan ulang script ini.
    echo.
    pause
    exit /b 1
)

cd /d "%~dp0"

echo [1/3] Membuat lingkungan virtual Python...
python -m venv venv
if errorlevel 1 (
    echo [GAGAL] Tidak bisa membuat venv. Coba jalankan sebagai Administrator.
    pause
    exit /b 1
)

call venv\Scripts\activate.bat

echo [2/3] Mengunduh library yang dibutuhkan (butuh internet, +/- 2-5 menit)...
python -m pip install --upgrade pip >nul
pip install -r requirements.txt
if errorlevel 1 (
    echo [GAGAL] Instalasi library error. Periksa koneksi internet lalu ulangi.
    pause
    exit /b 1
)

echo.
echo [3/3] Selesai!
echo.
echo ==================================================
echo   SETUP BERHASIL.
echo   Untuk menyalakan server: jalankan run_backend.bat
echo ==================================================
echo.
pause
