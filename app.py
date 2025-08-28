import os
import sqlite3
from flask import Flask, render_template, request, redirect, url_for, flash, g

app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "dev-secret-key-change-me")

# Database configuration
DB_PATH = os.path.join(app.root_path, "messages.db")


def get_db():
    db = getattr(g, "_database", None)
    if db is None:
        db = g._database = sqlite3.connect(DB_PATH)
        db.row_factory = sqlite3.Row
    return db


@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, "_database", None)
    if db is not None:
        db.close()


def init_db():
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT NOT NULL,
                message TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        conn.commit()
    finally:
        conn.close()


# Initialize DB at import time (Flask >= 3 compatibility; idempotent)
init_db()


@app.route("/", methods=["GET"]) 
def index():
    return render_template("index.html")


@app.route("/contact", methods=["POST"]) 
def contact():
    name = request.form.get("name", "").strip()
    email = request.form.get("email", "").strip()
    message = request.form.get("message", "").strip()

    if not name or not email or not message:
        flash("Proszę wypełnić wszystkie pola.", "danger")
        return redirect(url_for("index"))

    db = get_db()
    db.execute(
        "INSERT INTO messages (name, email, message) VALUES (?, ?, ?)",
        (name, email, message),
    )
    db.commit()

    flash("Dziękujemy! Twoja wiadomość została wysłana.", "success")
    return redirect(url_for("index"))


@app.route("/admin/messages", methods=["GET"]) 
def admin_messages():
    db = get_db()
    cur = db.execute(
        "SELECT id, name, email, message, datetime(created_at) as created_at FROM messages ORDER BY created_at DESC"
    )
    messages = cur.fetchall()
    return render_template("admin.html", messages=messages)


if __name__ == "__main__":
    # Ensure DB exists and has the required table
    os.makedirs(app.root_path, exist_ok=True)
    init_db()
    app.run(host='0.0.0.0', port=5030, debug=True)
