#!/usr/bin/env python3
"""Create SQLite tables for Hostel Management System.
The original migrations were MySQL‑style and cause syntax errors on SQLite.
This script creates the minimal tables required for the authentication
seed script and the rest of the backend.
"""
import pathlib, sqlite3

DB_PATH = r"C:\\work\\OHms\\test hm\\hm\\HM\\HM\\HostelManagementSystem\\backend\\hostel.db"

SQL_SCRIPT = """
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('STUDENT','PARENT','WARDEN','SECURITY','ADMIN')),
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS students (
    user_email TEXT NOT NULL PRIMARY KEY,
    enrollment_no TEXT,
    hostel TEXT,
    room_no TEXT,
    bed TEXT,
    branch_year TEXT,
    FOREIGN KEY(user_email) REFERENCES users(email) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS parents (
    user_email TEXT NOT NULL PRIMARY KEY,
    name TEXT,
    phone TEXT,
    FOREIGN KEY(user_email) REFERENCES users(email) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS parent_student (
    parent_email TEXT NOT NULL,
    student_email TEXT NOT NULL,
    PRIMARY KEY (parent_email, student_email),
    FOREIGN KEY(parent_email) REFERENCES parents(user_email) ON DELETE CASCADE,
    FOREIGN KEY(student_email) REFERENCES students(user_email) ON DELETE CASCADE
);
"""

def main():
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.executescript(SQL_SCRIPT)
        conn.commit()
        print("SQLite schema created successfully.")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
