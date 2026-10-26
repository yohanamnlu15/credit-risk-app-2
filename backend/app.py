import os
import sqlite3
import secrets
from datetime import datetime
from functools import wraps

import joblib
import pandas as pd
from flask import Flask, request, jsonify, g
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "credit_risk.db")
ML_DIR = os.path.join(BASE_DIR, "model_ml")

ADMIN_SECRET_CODE = os.environ.get("ADMIN_SECRET_CODE", "ADMIN-CREDITRISK-2026")

app = Flask(__name__)
CORS(app)

model = joblib.load(os.path.join(ML_DIR, "decision_tree_model.pkl"))
encoder_dict = joblib.load(os.path.join(ML_DIR, "feature_encoders.pkl"))
target_encoder = joblib.load(os.path.join(ML_DIR, "target_encoder.pkl"))

FITUR_ORDER = [
    "usia_kategori",
    "pendapatan_kategori",
    "durasi_kategori",
    "tanggungan_kategori",
    "pinjaman_kategori",
    "tabungan_kategori",
    "Pekerjaan",
]


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
    # x dalam HARI
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


def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
    return g.db


@app.teardown_appcontext
def close_db(exception=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db():
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    db.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL CHECK(role IN ('Admin', 'Analis')),
            nama TEXT NOT NULL,
            created_at TEXT NOT NULL
        )
        """
    )
    db.execute(
        """
        CREATE TABLE IF NOT EXISTS evaluations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            analyst_id INTEGER NOT NULL,
            nama_debitur TEXT NOT NULL,
            usia INTEGER NOT NULL,
            pekerjaan TEXT NOT NULL,
            pendapatan REAL NOT NULL,
            jumlah_tanggungan INTEGER NOT NULL,
            jumlah_pinjaman REAL NOT NULL,
            tabungan REAL NOT NULL DEFAULT 0,
            durasi_hari INTEGER NOT NULL,
            durasi_label TEXT NOT NULL,
            status TEXT NOT NULL,
            confidence REAL NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (analyst_id) REFERENCES users (id)
        )
        """
    )

    # Migrasi untuk DB lama yang belum punya kolom tabungan
    cols = [c["name"] for c in db.execute("PRAGMA table_info(evaluations)").fetchall()]
    if "tabungan" not in cols:
        db.execute("ALTER TABLE evaluations ADD COLUMN tabungan REAL NOT NULL DEFAULT 0")

    existing = db.execute("SELECT COUNT(*) AS c FROM users").fetchone()["c"]
    if existing == 0:
        now = datetime.utcnow().isoformat()
        db.execute(
            "INSERT INTO users (username, password_hash, role, nama, created_at) VALUES (?, ?, ?, ?, ?)",
            ("admin", generate_password_hash("admin123"), "Admin", "Rizky Pratama", now),
        )
        db.execute(
            "INSERT INTO users (username, password_hash, role, nama, created_at) VALUES (?, ?, ?, ?, ?)",
            ("analis", generate_password_hash("analis123"), "Analis", "Anisa Putri Wardhani", now),
        )
    db.commit()
    db.close()


ACTIVE_TOKENS = {}  # token -> user_id


def require_auth(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "Token tidak ditemukan"}), 401
        token = auth_header.split(" ", 1)[1]
        user_id = ACTIVE_TOKENS.get(token)
        if user_id is None:
            return jsonify({"error": "Token tidak valid atau kedaluwarsa"}), 401
        g.user_id = user_id
        return f(*args, **kwargs)

    return wrapper


def require_role(*roles):
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            db = get_db()
            user = db.execute("SELECT role FROM users WHERE id = ?", (g.user_id,)).fetchone()
            if user is None or user["role"] not in roles:
                return jsonify({"error": "Akses ditolak untuk role ini"}), 403
            return f(*args, **kwargs)

        return wrapper

    return decorator


# ==========================
# AUTH
# ==========================
@app.route("/api/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    password = data.get("password", "")
    nama = data.get("nama", "").strip()
    kode_admin = data.get("kode_admin", "")

    if not username or not password or not nama:
        return jsonify({"error": "Semua field wajib diisi"}), 400
    if len(password) < 6:
        return jsonify({"error": "Password minimal 6 karakter"}), 400
    if kode_admin != ADMIN_SECRET_CODE:
        return jsonify({"error": "Kode registrasi Admin salah"}), 403

    db = get_db()
    existing = db.execute("SELECT id FROM users WHERE username = ?", (username,)).fetchone()
    if existing:
        return jsonify({"error": "Username sudah digunakan"}), 409

    db.execute(
        "INSERT INTO users (username, password_hash, role, nama, created_at) VALUES (?, ?, ?, ?, ?)",
        (username, generate_password_hash(password), "Admin", nama, datetime.utcnow().isoformat()),
    )
    db.commit()
    return jsonify({"message": "Registrasi Admin berhasil, silakan login."})


@app.route("/api/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    password = data.get("password", "")

    if not username or not password:
        return jsonify({"error": "Username dan password wajib diisi"}), 400

    db = get_db()
    user = db.execute("SELECT * FROM users WHERE username = ?", (username,)).fetchone()

    if user is None or not check_password_hash(user["password_hash"], password):
        return jsonify({"error": "Username atau password salah"}), 401

    token = secrets.token_hex(24)
    ACTIVE_TOKENS[token] = user["id"]

    return jsonify(
        {
            "token": token,
            "role": user["role"],
            "nama": user["nama"],
            "username": user["username"],
        }
    )


@app.route("/api/logout", methods=["POST"])
@require_auth
def logout():
    auth_header = request.headers.get("Authorization", "")
    token = auth_header.split(" ", 1)[1]
    ACTIVE_TOKENS.pop(token, None)
    return jsonify({"message": "Logout berhasil"})


@app.route("/api/me", methods=["GET"])
@require_auth
def me():
    db = get_db()
    user = db.execute(
        "SELECT id, username, nama, role, created_at FROM users WHERE id = ?", (g.user_id,)
    ).fetchone()
    if user is None:
        return jsonify({"error": "User tidak ditemukan"}), 404

    if user["role"] == "Admin":
        total = db.execute("SELECT COUNT(*) AS c FROM evaluations").fetchone()["c"]
        total_analis = db.execute("SELECT COUNT(*) AS c FROM users WHERE role = 'Analis'").fetchone()["c"]
        stats = {"totalEvaluasi": total, "totalAnalis": total_analis}
    else:
        total = db.execute(
            "SELECT COUNT(*) AS c FROM evaluations WHERE analyst_id = ?", (g.user_id,)
        ).fetchone()["c"]
        stats = {"totalEvaluasi": total}

    return jsonify(
        {
            "username": user["username"],
            "nama": user["nama"],
            "role": user["role"],
            "createdAt": user["created_at"],
            "stats": stats,
        }
    )


# ==========================
# MANAJEMEN AKUN ANALIS (Admin only)
# ==========================
@app.route("/api/users", methods=["GET"])
@require_auth
@require_role("Admin")
def list_analis():
    db = get_db()
    rows = db.execute(
        "SELECT id, username, nama, created_at FROM users WHERE role = 'Analis' ORDER BY created_at DESC"
    ).fetchall()
    return jsonify([dict(r) for r in rows])


@app.route("/api/users", methods=["POST"])
@require_auth
@require_role("Admin")
def create_analis():
    data = request.get_json(silent=True) or {}
    username = data.get("username", "").strip()
    password = data.get("password", "")
    nama = data.get("nama", "").strip()

    if not username or not password or not nama:
        return jsonify({"error": "Semua field wajib diisi"}), 400
    if len(password) < 6:
        return jsonify({"error": "Password minimal 6 karakter"}), 400

    db = get_db()
    existing = db.execute("SELECT id FROM users WHERE username = ?", (username,)).fetchone()
    if existing:
        return jsonify({"error": "Username sudah digunakan"}), 409

    db.execute(
        "INSERT INTO users (username, password_hash, role, nama, created_at) VALUES (?, ?, ?, ?, ?)",
        (username, generate_password_hash(password), "Analis", nama, datetime.utcnow().isoformat()),
    )
    db.commit()
    new_id = db.execute("SELECT last_insert_rowid() AS id").fetchone()["id"]
    return jsonify({"id": new_id, "username": username, "nama": nama, "role": "Analis"})


@app.route("/api/users/<int:user_id>", methods=["DELETE"])
@require_auth
@require_role("Admin")
def delete_analis(user_id):
    db = get_db()
    user = db.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if user is None:
        return jsonify({"error": "Akun tidak ditemukan"}), 404
    if user["role"] != "Analis":
        return jsonify({"error": "Hanya akun Analis yang bisa dihapus dari sini"}), 400

    db.execute("DELETE FROM users WHERE id = ?", (user_id,))
    db.commit()
    return jsonify({"message": "Akun Analis berhasil dihapus"})

@app.route("/api/me/password", methods=["PUT"])
@require_auth
def change_my_password():
    data = request.get_json(silent=True) or {}
    old_password = data.get("old_password", "")
    new_password = data.get("new_password", "")

    if not old_password or not new_password:
        return jsonify({"error": "Password lama dan password baru wajib diisi"}), 400
    if len(new_password) < 6:
        return jsonify({"error": "Password baru minimal 6 karakter"}), 400

    db = get_db()
    user = db.execute("SELECT * FROM users WHERE id = ?", (g.user_id,)).fetchone()
    if user is None:
        return jsonify({"error": "User tidak ditemukan"}), 404

    if not check_password_hash(user["password_hash"], old_password):
        return jsonify({"error": "Password lama tidak sesuai"}), 401

    db.execute(
        "UPDATE users SET password_hash = ? WHERE id = ?",
        (generate_password_hash(new_password), g.user_id),
    )
    db.commit()
    return jsonify({"message": "Password berhasil diperbarui"})

# ==========================
# PREDIKSI
# ==========================
@app.route("/api/predict", methods=["POST"])
@require_auth
def predict():
    data = request.get_json(silent=True) or {}

    required_fields = [
        "nama", "usia", "pekerjaan", "pendapatan", "tabungan",
        "jumlah_tanggungan", "jumlah_pinjaman", "durasi_hari", "durasi_label",
    ]
    missing = [f for f in required_fields if f not in data]
    if missing:
        return jsonify({"error": f"Field wajib belum lengkap: {', '.join(missing)}"}), 400

    try:
        usia = int(data["usia"])
        pendapatan = float(data["pendapatan"])
        tabungan = float(data["tabungan"])
        jumlah_tanggungan = int(data["jumlah_tanggungan"])
        jumlah_pinjaman = float(data["jumlah_pinjaman"])
        durasi_hari = int(data["durasi_hari"])
        durasi_label = str(data["durasi_label"]).strip()
        pekerjaan_raw = str(data["pekerjaan"]).strip()
        nama_debitur = str(data["nama"]).strip()
    except (ValueError, TypeError):
        return jsonify(
            {"error": "Tipe data tidak sesuai (usia/pendapatan/tabungan/tanggungan/pinjaman/durasi harus angka)"}
        ), 400

    if tabungan < 0:
        return jsonify({"error": "Tabungan tidak boleh negatif"}), 400

    pekerjaan_classes = list(encoder_dict["Pekerjaan"].classes_)
    if pekerjaan_raw not in pekerjaan_classes:
        return jsonify(
            {
                "error": f"Nilai pekerjaan '{pekerjaan_raw}' tidak dikenali model.",
                "pekerjaan_valid": pekerjaan_classes,
            }
        ), 400

    row = {
        "usia_kategori": kategori_usia(usia),
        "pendapatan_kategori": kategori_pendapatan(pendapatan),
        "durasi_kategori": kategori_durasi(durasi_hari),
        "tanggungan_kategori": kategori_tanggungan(jumlah_tanggungan),
        "pinjaman_kategori": kategori_pinjaman(jumlah_pinjaman),
        "tabungan_kategori": kategori_tabungan(tabungan),
        "Pekerjaan": pekerjaan_raw,
    }

    df_input = pd.DataFrame([row])[FITUR_ORDER]
    for col in FITUR_ORDER:
        df_input[col] = encoder_dict[col].transform(df_input[col])

    pred = model.predict(df_input)
    proba = model.predict_proba(df_input)[0]

    status_raw = target_encoder.inverse_transform(pred)[0]
    status = status_raw.capitalize()

    probabilities = {
        target_encoder.classes_[i].capitalize(): round(float(p) * 100, 2)
        for i, p in enumerate(proba)
    }
    confidence = probabilities[status]

    db = get_db()
    db.execute(
        """
        INSERT INTO evaluations
        (analyst_id, nama_debitur, usia, pekerjaan, pendapatan, jumlah_tanggungan,
         jumlah_pinjaman, tabungan, durasi_hari, durasi_label, status, confidence, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            g.user_id, nama_debitur, usia, pekerjaan_raw, pendapatan, jumlah_tanggungan,
            jumlah_pinjaman, tabungan, durasi_hari, durasi_label, status, confidence,
            datetime.utcnow().isoformat(),
        ),
    )
    db.commit()
    new_id = db.execute("SELECT last_insert_rowid() AS id").fetchone()["id"]

    return jsonify(
        {
            "id": new_id,
            "status": status,
            "confidence": confidence,
            "probabilities": probabilities,
            "kategori": row,
        }
    )

# ==========================
# RIWAYAT & DASHBOARD (di-filter sesuai role)
# ==========================
@app.route("/api/history", methods=["GET"])
@require_auth
def history():
    db = get_db()
    user = db.execute("SELECT role FROM users WHERE id = ?", (g.user_id,)).fetchone()

    if user["role"] == "Admin":
        rows = db.execute(
            """
            SELECT e.*, u.nama AS analyst_nama
            FROM evaluations e
            JOIN users u ON u.id = e.analyst_id
            ORDER BY e.created_at DESC
            """
        ).fetchall()
    else:
        rows = db.execute(
            """
            SELECT e.*, u.nama AS analyst_nama
            FROM evaluations e
            JOIN users u ON u.id = e.analyst_id
            WHERE e.analyst_id = ?
            ORDER BY e.created_at DESC
            """,
            (g.user_id,),
        ).fetchall()

    result = [
        {
            "id": f"DB-{r['id']:04d}",
            "nama": r["nama_debitur"],
            "pekerjaan": r["pekerjaan"],
            "usia": r["usia"],
            "pendapatan": r["pendapatan"],
            "jumlahTanggungan": r["jumlah_tanggungan"],
            "jumlahPinjaman": r["jumlah_pinjaman"],
            "tabungan": r["tabungan"],
            "jangkaWaktu": r["durasi_label"],
            "status": r["status"],
            "confidence": r["confidence"],
            "tanggal": r["created_at"],
            "namaAnalis": r["analyst_nama"],
        }
        for r in rows
    ]
    return jsonify(result)


@app.route("/api/summary", methods=["GET"])
@require_auth
def summary():
    db = get_db()
    user = db.execute("SELECT role FROM users WHERE id = ?", (g.user_id,)).fetchone()

    if user["role"] == "Admin":
        total = db.execute("SELECT COUNT(*) AS c FROM evaluations").fetchone()["c"]
        lancar = db.execute("SELECT COUNT(*) AS c FROM evaluations WHERE status = 'Lancar'").fetchone()["c"]
    else:
        total = db.execute(
            "SELECT COUNT(*) AS c FROM evaluations WHERE analyst_id = ?", (g.user_id,)
        ).fetchone()["c"]
        lancar = db.execute(
            "SELECT COUNT(*) AS c FROM evaluations WHERE analyst_id = ? AND status = 'Lancar'", (g.user_id,)
        ).fetchone()["c"]

    macet = total - lancar
    lancar_percent = round((lancar / total) * 100, 1) if total else 0
    macet_percent = round((macet / total) * 100, 1) if total else 0

    return jsonify({"total": total, "lancarPercent": lancar_percent, "macetPercent": macet_percent})


@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000, debug=True)