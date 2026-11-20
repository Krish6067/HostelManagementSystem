# Hostel Management System - Local Test Portal

The dashboards are still a frontend prototype backed by local demo data. The local test server adds a server-side login gate using the supplied Shastri test credentials workbook.

## Key Features

- **Glassmorphism Design:** Modern, clean, professional interface.
- **Responsive Layout:** Works on mobile, tablet, and desktop. No horizontal overflow.
- **Role-based Access:** Five distinct portals for Student, Parent, Warden, Security, and Admin.
- **Strict Approval Workflow:** Student -> Parent -> Warden -> Security.
- **Frontend State Management:** Uses a local storage mock database (`demo-data.js`) to simulate data persistence and notifications.

## Project Structure

```
HostelManagementSystem/
├── frontend/
│   ├── index.html              (Landing page for role selection)
│   ├── css/
│   │   ├── style.css           (Global variables and base styles)
│   │   ├── components.css      (Reusable UI components: buttons, modals, cards)
│   │   └── responsive.css      (Media queries for mobile/tablet)
│   ├── js/
│   │   ├── main.js             (Core UI interactions, sidebar, modals)
│   │   ├── demo-data.js        (Mock database and data persistence)
│   │   └── outpass.js          (Business logic for the approval workflow)
│   ├── student/                (Student portal)
│   ├── parent/                 (Parent portal)
│   ├── warden/                 (Warden portal)
│   ├── security/               (Security portal)
│   └── admin/                  (Admin portal)
```

## Start the dataset-only test portal (Windows)

1. In PowerShell, run `backend\run-local.ps1` from this project folder.
2. Open `http://127.0.0.1:5197/` and choose a portal.
3. Sign in with an account and password from `Shastri_Hostel_Test_Credentials_Dataset.xlsx`.

The server reads the workbook at `C:\Users\acer\OneDrive\Shastri_Hostel_Test_Credentials_Dataset.xlsx` by default. Use `-WorkbookPath 'C:\path\to\dataset.xlsx'` if it is stored elsewhere. The server accepts only workbook accounts for the selected role, rate limits failed attempts, stores session tokens in HTTP-only cookies, and rejects direct dashboard requests without a matching role session. Stop it with Ctrl+C.

Do not open dashboard HTML files directly; use the localhost URL so the server can enforce the login gate. This is a local development gate, not production authentication: credentials remain in the supplied workbook, sessions are in memory, and portal data still uses the prototype's local-storage mock database rather than MySQL.
