# Project Overview – Hostel Management System Backend

## Repository Layout
```
HostelManagementSystem/
│
├─ backend/                         # C++ server source tree
│   ├─ CMakeLists.txt                # Build definition (CMake)
│   ├─ Dockerfile                    # Container recipe for production
│   ├─ config.json                   # Drogon configuration (listeners, DB pool)
│   ├─ main.cpp                      # Application entry point
│   ├─ controllers/                  # HTTP route handlers (one per feature)
│   │   ├─ AuthController.{h,cpp}
│   │   ├─ StudentController.{h,cpp}
│   │   ├─ ParentController.{h,cpp}
│   │   ├─ WardenController.{h,cpp}
│   │   ├─ SecurityController.{h,cpp}
│   │   ├─ AdminController.{h,cpp}
│   │   ├─ OutpassController.{h,cpp}
│   │   ├─ ComplaintController.{h,cpp}
│   │   ├─ NoticeController.{h,cpp}
│   │   ├─ NotificationController.{h,cpp}
│   │   └─ HealthController.{h,cpp}
│   ├─ models/                       # Drogon ORM POCOs and mappers
│   │   ├─ User.h
│   │   ├─ Student.h
│   │   ├─ Parent.h
│   │   ├─ Warden.h
│   │   ├─ SecurityStaff.h
│   │   ├─ Hostel.h
│   │   ├─ Room.h
│   │   ├─ Outpass.h
│   │   ├─ QRPass.h
│   │   ├─ MovementRecord.h
│   │   ├─ Complaint.h
│   │   ├─ Notice.h
│   │   └─ Notification.h
│   ├─ services/                     # Business‑logic layer
│   │   ├─ AuthService.cpp
│   │   ├─ OutpassService.cpp
│   │   ├─ NotificationService.cpp
│   │   ├─ QRService.cpp
│   │   ├─ HostelService.cpp
│   │   └─ ReportService.cpp
│   ├─ middleware/                   # Request‑level security helpers
│   │   ├─ AuthMiddleware.cpp
│   │   ├─ RoleMiddleware.cpp
│   │   └─ RateLimitMiddleware.cpp
│   ├─ utils/                        # Re‑usable helpers
│   │   ├─ PasswordUtils.cpp    # Argon2id / bcrypt wrapper
│   │   ├─ TokenUtils.cpp       # JWT creation / validation
│   │   ├─ ValidationUtils.cpp  # Input validation helpers
│   │   └─ ResponseUtils.cpp    # Uniform JSON response builder
│   ├─ database/                     # SQL migrations & seed data
│   │   ├─ migrations/
│   │   │   ├─ 20231120_01_create_users.sql
│   │   │   ├─ 20231120_02_create_students.sql
│   │   │   ├─ 20231120_03_create_parents.sql
│   │   │   ├─ 20231120_04_create_parent_student.sql
│   │   │   ├─ 20231120_05_create_hostels.sql
│   │   │   ├─ 20231120_06_create_rooms.sql
│   │   │   ├─ 20231120_07_create_outpasses.sql
│   │   │   ├─ 20231120_08_create_outpass_approvals.sql
│   │   │   ├─ 20231120_09_create_qr_passes.sql
│   │   │   ├─ 20231120_10_create_movement_records.sql
│   │   │   ├─ 20231120_11_create_complaints.sql
│   │   │   ├─ 20231120_12_create_notices.sql
│   │   │   ├─ 20231120_13_create_notifications.sql
│   │   │   ├─ 20231120_14_create_audit_logs.sql
│   │   │   ├─ 20231120_15_create_refresh_tokens.sql
│   │   │   └─ 20231120_16_create_login_attempts.sql
│   │   └─ seeds/
│   │       └─ seed.sql            # Small demo dataset (admin, hostels, rooms, users)
│   └─ tests/                        # GoogleTest unit / integration tests
│       └─ (sample test files)
│
├─ frontend/                         # Minimal demo HTML/JS integration snippets
│   ├─ index.html
│   └─ js/
│       └─ api.js                  # fetch wrappers for each role
│
└─ README.md                         # Documentation, build & run guide
```

## What each layer does
- **Controllers** – receive HTTP requests, perform auth/role checks via middleware, call the appropriate service, and format the response using `ResponseUtils`.
- **Services** – contain the core business rules (e.g., the sequential outpass approval workflow, transactional QR generation, notification dispatch). All DB writes are performed inside **transactions** to guarantee consistency.
- **Middleware** – `AuthMiddleware` extracts the JWT, validates it, and injects the user identity into the request context. `RoleMiddleware` checks that the authenticated user has the required role(s). `RateLimitMiddleware` throttles abusive clients.
- **Utils** – cryptographic helpers (Argon2id via `libsodium`, JWT via `jwt-cpp`), request validation, and a single place for the JSON envelope (`success`, `message`, `data`, `error_code`).
- **Models** – plain‑old‑data structs; each has a corresponding Drogon `Mapper<>` alias for easy ORM operations.
- **Migrations** – pure SQL files executed by `drogon_ctl migrate up`. They create a fully **normalized** schema with proper foreign‑keys, indexes, and transaction‑safe defaults.
- **Dockerfile** – builds a minimal **Alpine** image with the compiled binary and the `config.json` (environment variables are injected at container start).
- **Frontend snippets** – show how to store the JWT, call a protected endpoint, and handle error responses. They can be copied into your existing HTML/JS files.

---

### Next deliverables (in order)
1. **Dockerfile** + updated `CMakeLists.txt` that compiles all source files.
2. **All migration scripts** (already listed in the tree) – they will be generated next.
3. **Model headers** for each table.
4. **Utility implementations** (PasswordUtils, TokenUtils, ResponseUtils, ValidationUtils).
5. **Middleware** (Auth & Role).
6. **Service implementations** (AuthService, OutpassService, QRService, NotificationService, ReportService).
7. **Controllers** (Auth, Student, Parent, Warden, Security, Admin, Outpass, Complaint, Notice, Notification, Health).
8. **Minimal frontend demo** (`index.html` + `js/api.js`).
9. **Test suite skeleton** (GoogleTest fixtures for auth and outpass workflow).
10. **README** with complete Windows‑11 build steps, Docker usage, and Postman collection.

When you are ready, I will start by committing the **Dockerfile** and **CMake** updates, then proceed with the migration scripts.
