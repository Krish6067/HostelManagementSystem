#!/usr/bin/env python3
"""seed_all_credentials.py – Imports admins, wardens, guards, students & parents.
Passwords are stored as bcrypt hashes (the backend already uses `PasswordUtils` to verify them)."""

import pathlib, pandas as pd, bcrypt
from sqlalchemy import create_engine, text

# ---------------------------------------------------
# CONFIGURATION – adjust only if your layout differs
# ---------------------------------------------------
PROJECT_ROOT = pathlib.Path(__file__).parents[2]
DB_PATH = r"C:\\work\\OHms\\test hm\\hm\\HM\\HM\\HostelManagementSystem\\backend\\hostel.db"
EXCEL_PATH = pathlib.Path(r"C:\\Users\\thaku\\.gemini\\antigravity\\brain\\cdfe01be-2846-4d7d-9c7d-4a9bafecc57a\\.user_uploaded\\media_1795190963708_f807539e.xlsx")

engine = create_engine(f"sqlite:///{DB_PATH}")

def bcrypt_hash(pwd: str) -> str:
    return bcrypt.hashpw(pwd.encode(), bcrypt.gensalt()).decode()

def store_user(conn, email, raw_pwd, role):
    pwd_hash = bcrypt_hash(raw_pwd)
    sql = text(
        "INSERT OR IGNORE INTO users (email, password_hash, role) VALUES (:email, :pwd, :role)"
    )
    conn.execute(sql, {"email": email.strip(), "pwd": pwd_hash, "role": role.upper()})

def main():
    print(f"Loading data from {EXCEL_PATH}")
    xls = pd.ExcelFile(EXCEL_PATH)

    # ---- Admins ----
    admin_df = pd.read_excel(xls, sheet_name='1_Admins', skiprows=3, header=None)
    # Columns: 0=Admin ID,1=Full Name,2=Role/Designation,3=Email ID,4=Password,5=Phone Number,6=Access Level
    with engine.begin() as conn:
        for _, r in admin_df.iterrows():
            email = r[3]
            pwd = r[4]
            store_user(conn, email, pwd, "ADMIN")
    print(f"Inserted {len(admin_df)} admin(s)")

    # ---- Wardens ----
    warden_df = pd.read_excel(xls, sheet_name='2_Wardens', skiprows=3, header=None)
    # Columns: 0=Warden ID,1=Full Name,2=Designation,3=Email ID,4=Password,5=Phone Number,6=Other...
    with engine.begin() as conn:
        for _, r in warden_df.iterrows():
            email = r[3]
            pwd = r[4]
            store_user(conn, email, pwd, "WARDEN")
    print(f"Inserted {len(warden_df)} warden(s)")

    # ---- Security Guards ----
    guard_df = pd.read_excel(xls, sheet_name='3_Security_Guards', skiprows=3, header=None)
    # Columns: 0=Guard ID,1=Full Name,2=Badge No.,3=Email ID,4=Password,5=Phone Number,6=Other...
    with engine.begin() as conn:
        for _, r in guard_df.iterrows():
            email = r[3]
            pwd = r[4]
            store_user(conn, email, pwd, "SECURITY")
    print(f"Inserted {len(guard_df)} guard(s)")

    # ---- Students & Parents ----
    stu_df = pd.read_excel(xls, sheet_name='4_Students_and_Parents', skiprows=3, header=None)
    # Expected column indices based on sample data:
    # 0=S.No,1=Enrollment No.,2=Student Name,3=Gender,4=Hostel,5=Room No.,6=Bed,
    # 7=Branch & Year,8=Blood Group,9=Student Email ID,10=Student Password,
    # 11=Student Phone,12=Registered Parent Name,13=Parent Email ID,14=Parent Password,
    # 15=Parent Phone,16=Fee Status
    with engine.begin() as conn:
        for _, r in stu_df.iterrows():
            student_email = r[9]
            student_pwd = r[10]
            parent_email = r[13]
            parent_pwd = r[14]
            # student user
            store_user(conn, student_email, student_pwd, "STUDENT")
            # parent user
            store_user(conn, parent_email, parent_pwd, "PARENT")

            # optional student table (add if it exists)
            conn.execute(
                text("INSERT OR IGNORE INTO students (user_email, enrollment_no, hostel, room_no, bed, branch_year) VALUES (:email, :enroll, :hostel, :room, :bed, :branch)"),
                {
                    "email": student_email.strip(),
                    "enroll": str(r[1]).strip(),
                    "hostel": r[4].strip(),
                    "room": r[5].strip(),
                    "bed": r[6].strip(),
                    "branch": r[7].strip(),
                },
            )
            # optional parent table
            conn.execute(
                text("INSERT OR IGNORE INTO parents (user_email, name, phone) VALUES (:email, :name, :phone)"),
                {
                    "email": parent_email.strip(),
                    "name": r[12].strip(),
                    "phone": r[15].strip(),
                },
            )
            # linking table
            conn.execute(
                text("INSERT OR IGNORE INTO parent_student (parent_email, student_email) VALUES (:parent, :student)"),
                {"parent": parent_email.strip(), "student": student_email.strip()},
            )
    print(f"Inserted {len(stu_df)} student‑parent pairs")

if __name__ == "__main__":
    main()
