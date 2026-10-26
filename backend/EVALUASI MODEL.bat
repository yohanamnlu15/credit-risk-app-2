@echo off
chcp 65001 >nul
title CrediPredict - Evaluasi Model
cd /d "%~dp0"

echo ==========================================================
echo    UJI MODEL C4.5  ^|  METRIK TABEL 4.23 - 4.26
echo ==========================================================
echo.

if exist "venv\Scripts\python.exe" goto pakai_venv

where python >nul 2>nul
if errorlevel 1 goto tidak_ada_python
set "PY=python"
goto jalankan

:pakai_venv
set "PY=venv\Scripts\python.exe"
echo [i] Memakai Python dari folder venv.
echo.
goto jalankan

:tidak_ada_python
echo [GAGAL] Python tidak ditemukan di laptop ini.
echo.
echo Solusi:
echo    1. Jalankan setup_backend.bat lebih dulu, ATAU
echo    2. Install Python dari https://www.python.org/downloads/
echo       dan centang "Add python.exe to PATH" saat instalasi.
echo.
pause
exit /b 1

:jalankan
echo Menjalankan evaluasi... mohon tunggu beberapa detik.
echo ----------------------------------------------------------
"%PY%" evaluasi_model.py --detail
echo ----------------------------------------------------------
echo.
echo Selesai. Tekan tombol apa saja untuk menutup jendela ini.
pause >nul
