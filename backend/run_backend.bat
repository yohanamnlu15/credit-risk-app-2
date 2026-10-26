@echo off
chcp 65001 >nul
title Backend CrediPredict (Server)
cd /d "%~dp0"

if not exist venv (
    echo [GAGAL] Belum setup. Jalankan setup_backend.bat dulu!
    pause
    exit /b 1
)

call venv\Scripts\activate.bat

echo ==================================================
echo   SERVER CREDIPREDICT SEDANG BERJALAN
echo ==================================================
echo   Alamat : http://localhost:5000
echo   Tes    : buka http://localhost:5000/api/health
echo             di browser -^> harus muncul {"status":"ok"}
echo.
echo   PENTING:
echo   - Biarkan jendela ini TERBUKA selama aplikasi dipakai
echo   - Untuk menghentikan: tekan Ctrl+C atau tutup jendela
echo ==================================================
echo.
python app.py
pause
