# Deploy Hostel Management System to GitHub

## 1. Initialise a Git repository
```powershell
cd "C:\\work\\OHms\\test hm\\hm\\HM\\HM\\HostelManagementSystem"
git init
git add .
git commit -m "Initial commit – Hostel Management System"
```

## 2. Create a GitHub repository
1. Go to https://github.com and create a **new repository** (e.g., `hostel-management-system`).
2. Do **not** initialise with a README – you already have files.
3. Copy the remote URL (HTTPS or SSH).

## 3. Push the code
```powershell
# Replace <URL> with the URL you copied
git remote add origin <URL>
# Optional: set the default branch name (GitHub now uses 'main')
git branch -M main
git push -u origin main
```

## 4. Enable GitHub Pages (static front‑end only)
The front‑end lives under `frontend/`. To serve it via GitHub Pages:
1. In the repository, go to **Settings → Pages**.
2. Under **Source**, choose the **`/frontend` folder** (or `main` branch → `/frontend`).
3. Save – GitHub will publish the static site at `https://<username>.github.io/<repo>/`.

> **Note:** The backend (`run‑local.ps1` / C++ server) cannot run on GitHub Pages. You will need a separate hosting service (Render, Railway, Azure, etc.) for the server and configure the front‑end to call the server’s public URL.

## 5. (Optional) Add a CI workflow
Create a GitHub Actions workflow to build the C++ backend and run tests on each push.
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python (for seeding script)
        uses: actions/setup-python@v5
        with:
          python-version: '3.14'
      - name: Install Python deps
        run: pip install pandas openpyxl bcrypt sqlalchemy
      - name: Build C++ backend
        run: |
          cmake -B build -S .
          cmake --build build --config Release
      - name: Run unit tests (if any)
        run: echo "Add your test command here"
```
Commit this file to `/.github/workflows/ci.yml`.

## 6. Update front‑end API endpoint
Once you have a server host (e.g., `https://my‑host.com/api`), edit the front‑end configuration (usually a `config.js` or `.env` file) to point to that endpoint instead of `http://127.0.0.1:5197`.

---
**Next steps**
- Choose a backend hosting provider and deploy the compiled server binary.
- Update the front‑end API base URL.
- Verify the site works end‑to‑end.

If you need help deploying the backend to a cloud service, let me know!