#!/usr/bin/env python3
"""Run SQLite migrations for the Hostel Management System.
Executes all .sql files in the `backend/database/migrations` directory in
lexicographic order. Uses the same DB_PATH as the seed script.
"""
import pathlib, sqlite3

# Paths (must match seed script configuration)
DB_PATH = r"C:\\work\\OHms\\test hm\\hm\\HM\\HM\\HostelManagementSystem\\backend\\hostel.db"
MIGRATIONS_DIR = pathlib.Path(r"C:\\work\\OHms\\test hm\\hm\\HM\\HM\\HostelManagementSystem\\backend\\database\\migrations")

def run_migration(sql_path):
    with open(sql_path, "r", encoding="utf-8") as f:
        sql = f.read()
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.executescript(sql)
        conn.commit()
        print(f"Applied {sql_path.name}")
    finally:
        conn.close()

def main():
    for sql_file in sorted(MIGRATIONS_DIR.glob("*.sql")):
        run_migration(sql_file)
    print("All migrations applied.")

if __name__ == "__main__":
    main()
