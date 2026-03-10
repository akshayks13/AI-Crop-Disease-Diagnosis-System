# CI/CD Documentation

## Overview

This project uses **GitHub Actions** for Continuous Integration (CI) and Continuous Deployment (CD). Workflows run automatically on push or pull request to `main`/`master` branches.

**Workflow files:**
| File | Trigger | Purpose |
|------|---------|--------|
| `.github/workflows/ci.yml` | Push / PR to `main` or `master` | Lint, test, and build all components |
| `.github/workflows/deploy-flutter.yml` | Push to `main` (flutter changes) + manual | Build Flutter Web and deploy to Firebase Hosting |

---

## What Happens When You Push?

```
git push → GitHub Actions Triggers → 4 Parallel Jobs Run → ✅ or ❌
```

---

## Jobs Overview

| Job | Language | What it checks |
|-----|----------|----------------|
| `backend` | Python | Linting + Tests |
| `flutter` | Dart | Static Analysis + Tests |
| `admin` | TypeScript | Linting + Tests + Build |
| `e2e` | TypeScript | End-to-End (Playwright) |

---

## Backend Job (Python/FastAPI)

### Tools Used

| Tool | Purpose | Why? |
|------|---------|------|
| **Python 3.11** | Runtime | Latest stable LTS version |
| **Ruff** | Linting | 100x faster than Flake8/Black combined |
| **Pytest** | Testing | Industry standard, async support |
| **PostgreSQL (service)** | Test DB | App uses UUID type which SQLite doesn't support |

### Steps
```yaml
1. Checkout code
2. Setup Python 3.11 with pip caching
3. Install dependencies from requirements.txt + ruff
4. Run: ruff check . --output-format=github  # Lint (GitHub-annotated output)
5. Run: pytest -v --tb=short                 # Test
```

### Database Handling
- CI spins up a **fresh PostgreSQL container** per run
- Tests run against `test_db` (not your real database)
- Container is destroyed after the job ends

---

## Flutter Job (Mobile App)

### Tools Used

| Tool | Purpose | Why? |
|------|---------|------|
| **Flutter 3.38.1** | SDK | Specified version for consistency |
| **flutter analyze** | Static analysis | Catches type errors, unused code |
| **flutter test** | Unit/Widget tests | Fast feedback on UI components |

### Steps
```yaml
1. Checkout code
2. Setup Flutter 3.38.1 (stable channel, cached)
3. Copy assets/.env.example to assets/.env   # Create env file from example
4. Run: flutter pub get                       # Install deps
5. Run: flutter analyze --no-fatal-infos --no-fatal-warnings  # Lint
6. Run: flutter test                          # Test
```

---

## Admin Dashboard Job (Next.js)

### Tools Used

| Tool | Purpose | Why? |
|------|---------|------|
| **Node.js 20** | Runtime | LTS version |
| **npm ci** | Install | Faster, lockfile-exact installs |
| **ESLint** | Linting | Catches JS/React/TypeScript errors |
| **Vitest** | Testing | Runs unit tests for API utilities |
| **next build** | Build check | Ensures production build works |

### Steps
```yaml
1. Checkout code
2. Setup Node.js 20 with npm caching
3. Run: npm ci        # Install deps
4. Run: npm run lint  # Lint
5. Run: npm test      # Test (Vitest)
6. Run: npm run build # Build
```

---

## E2E Job (Playwright)

> **Status**: Run locally; CI job to be added.

### Tools Used

| Tool | Purpose | Why? |
|------|---------|------|
| **Node.js 20** | Runtime | LTS version |
| **Playwright** | E2E testing | Cross-browser, full user-journey tests |
| **Chromium** | Browser | Default browser for CI runs |

### Steps
```yaml
1. Checkout code
2. Setup Node.js 20
3. Install dependencies: npm ci
4. Install Playwright browsers: npx playwright install --with-deps chromium
5. Run: npx playwright test   # E2E tests
6. Upload test report as artifact (on failure)
```

### What It Tests
- Admin login and dashboard load
- User management (list, suspend, activate)
- Expert approval workflow
- Diagnosis history pagination
- Community posts and comments flow
- Market prices page rendering

### Test Files
| File | Covers |
|------|--------|
| `e2e/auth.spec.ts` | Login, logout, invalid credentials |
| `e2e/dashboard.spec.ts` | Metrics cards, charts, daily stats |
| `e2e/users.spec.ts` | User list, role filter, suspend/activate |
| `e2e/experts.spec.ts` | Pending experts, approve/reject flow |
| `e2e/diagnoses.spec.ts` | Diagnosis list, pagination |

---

## Why These Specific Tools?

### Ruff (not Flake8/Black)
- **Speed**: 100x faster (written in Rust)
- **All-in-one**: Replaces Flake8, Black, isort, pydocstyle
- **Auto-fix**: Can fix issues automatically with `--fix`

### Pytest (not unittest)
- **Simpler syntax**: `assert x == y` vs. `self.assertEqual(x, y)`
- **Fixtures**: Reusable test setup
- **Async support**: Works with FastAPI's async routes

### PostgreSQL (not SQLite for tests)
- **UUID support**: Your models use PostgreSQL's native UUID type
- **Realistic**: Tests run against the same DB engine as production

### Playwright (not Cypress/Selenium)
- **Speed**: Runs tests in parallel across browsers natively
- **Reliability**: Auto-waits for elements, fewer flaky tests than Selenium
- **TypeScript-first**: Full type support, integrates with the Next.js codebase
- **Headless CI**: Works out of the box in GitHub Actions with `--with-deps`

### GitHub Actions (not Jenkins/CircleCI)
- **Free**: 2000 mins/month on free tier
- **Integrated**: No external service to manage
- **Parallel jobs**: Runs all CI checks simultaneously

---

## CD Workflow — Flutter Web Deploy (`deploy-flutter.yml`)

### Trigger
- **Auto**: Push to `main` that changes any file under `frontend/flutter_app/**`
- **Manual**: Workflow can be triggered from the GitHub Actions tab (`workflow_dispatch`)

### Steps
```yaml
1. Checkout code
2. Setup Flutter 3.38.1 (stable channel, cached)
3. Create assets/.env from GitHub secrets  # OPENWEATHER_API_KEY, GEMINI_API_KEY
4. Run: flutter pub get
5. Run: flutter gen-l10n                   # Generate localization files
6. Run: flutter build web --release \
       --dart-define=BASE_URL=${{ secrets.BACKEND_BASE_URL }}
7. Deploy to Firebase Hosting via FirebaseExtended/action-hosting-deploy@v0
```

### Required GitHub Secrets

Set these in **GitHub → Repository Settings → Secrets and Variables → Actions**:

| Secret | Description |
|--------|-------------|
| `BACKEND_BASE_URL` | Live backend URL: `https://ai-crop-disease-diagnosis-system-aumh.onrender.com` |
| `OPENWEATHER_API_KEY` | OpenWeather API key (injected into `assets/.env`) |
| `GEMINI_API_KEY` | Google Gemini API key (injected into `assets/.env`) |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase service account JSON (from Firebase console) |
| `FIREBASE_PROJECT_ID` | Firebase project ID: `ai-crop-disease-7c811` |
| `GITHUB_TOKEN` | Auto-provided by GitHub Actions (no setup needed) |

---

## How to Check CI Status

1. Push your code: `git push`
2. Go to **GitHub → Actions** tab
3. You'll see two workflows: **CI** (`ci.yml`) and **Deploy Flutter Web** (`deploy-flutter.yml`)
4. Click a workflow run to see each job
5. Green ✅ = All passed | Red ❌ = Click the failed job to see the error log

---

## Local Testing Commands

```bash
# Backend
cd backend
ruff check . --output-format=github   # Lint (same flags as CI)
DATABASE_URL="..." pytest -v --tb=short  # Test

# Flutter
cd frontend/flutter_app
flutter analyze --no-fatal-infos --no-fatal-warnings  # Lint
flutter test                           # Test

# Admin
cd frontend/admin_dashboard
npm run lint                           # Lint
npm test                               # Test (Vitest)
npm run build                          # Build

# E2E (requires running backend + admin dashboard)
cd frontend/admin_dashboard
npx playwright install chromium        # First-time setup
npx playwright test                    # Run all E2E tests
npx playwright test --ui               # Interactive UI mode
npx playwright show-report             # View last HTML report

# Flutter Web build (local simulation of deploy)
cd frontend/flutter_app
flutter gen-l10n
flutter build web --release --dart-define=BASE_URL=http://localhost:8000
```
