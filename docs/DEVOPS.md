# DevOps & Deployment Documentation

## Overview

This document covers infrastructure, deployment, monitoring, and operational procedures for the AI Crop Disease Diagnosis System.

---

## Architecture Overview

Current Development/Docker Environment:

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│   Flutter App   │       │ Admin Dashboard │       │   Backend API   │
│   (Web Server)  │       │    (Next.js)    │       │    (FastAPI)    │
│     Port 8080   │       │    Port 3000    │       │    Port 8000    │
└───────┤────────┘       └───────┤────────┘       └───────┬────────┘
         │                         │                         │
         └───────────────────────┼───────────────────────┘
                                    │
                          ┌─────────┘─────────┐
                          │                    │
                 ┌────────┴────┐    ┌────────┴───┐
                 │    PostgreSQL   │    │  Redis Cache  │
                 │    Port 5432   │    │  Port 6379    │
                 └────────────────┘    └──────────────┘
```

> **Note**: A Load Balancer (Nginx) is planned for the production environment to handle SSL termination and traffic distribution. It will be added in a future update.

---

## Docker Configuration

### docker-compose.yml

```yaml
version: '3.8'

services:
  # Postgres Database
  db:
    image: postgres:15-alpine
    container_name: crop_diagnosis_db
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=crop_diagnosis
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: crop_diagnosis_redis
    restart: always
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

  # Backend Service (FastAPI)
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: crop_diagnosis_backend
    restart: always
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql+asyncpg://postgres:postgres@db:5432/crop_diagnosis
      - REDIS_URL=redis://redis:6379/0
      - SECRET_KEY=your_secret_key_change_in_production
      - ALGORITHM=HS256
      - ACCESS_TOKEN_EXPIRE_MINUTES=30
    depends_on:
      - db
      - redis
    volumes:
      - ./backend/uploads:/app/uploads # Persist uploads

  # Admin Dashboard (Next.js)
  admin_dashboard:
    build:
      context: ./frontend/admin_dashboard
      dockerfile: Dockerfile
    container_name: crop_diagnosis_admin
    restart: always
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
    depends_on:
      - backend

  # Flutter App (Web served by Nginx)
  flutter_web:
    build:
      context: ./frontend/flutter_app
      dockerfile: Dockerfile
    container_name: crop_diagnosis_flutter_web
    restart: always
    ports:
      - "8080:80"
    depends_on:
      - backend

volumes:
  postgres_data:
```

### Backend Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Expose port
EXPOSE 8000

# Run with Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Environment Setup

### Development

```bash
# Clone repository
git clone <repo-url>
cd SE_Proj

# Start Redis via Docker (Required for caching)
docker run -d --name crop_diagnosis_redis -p 6379:6379 redis:7-alpine
# View logs: docker logs crop_diagnosis_redis
# Stop container: docker stop crop_diagnosis_redis

# Backend setup
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # Configure environment variables (ensure REDIS_URL=redis://localhost:6379/0)

# Run migrations
alembic upgrade head

# Start dev server
uvicorn app.main:app --reload --port 8000
```

### Production Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql+asyncpg://...` |
| `JWT_SECRET_KEY` | Secret key for JWT tokens | Random 32+ char string |
| `JWT_ALGORITHM` | JWT algorithm | `HS256` |
| `DEBUG` | Runtime mode | `false` |
| `ALLOWED_ORIGINS` | CORS allowed origins | `https://ai-crop-disease-diagnosis-system.vercel.app,https://ai-crop-disease-7c811.web.app` |
| `REDIS_URL` | Redis connection string | `redis://redis:6379/0` |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name | `your-cloud` |
| `CLOUDINARY_API_KEY` | Cloudinary API key | from dashboard |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret | from dashboard |
| `CLOUDINARY_FOLDER` | Upload folder prefix | `crop_diagnosis` |
| `AGMARKNET_API_KEY` | OGD Platform key for market prices | `your-api-key` |

---

---

## Production Deployment

Each component is deployed to a different platform:

| Component | Platform | Live URL | Notes |
|-----------|----------|----------|-------|
| **Backend (FastAPI)** | [Render](https://render.com) | [ai-crop-disease-diagnosis-system-aumh.onrender.com](https://ai-crop-disease-diagnosis-system-aumh.onrender.com) | Free-tier web service, auto-deploy on `main` push |
| **Admin Dashboard (Next.js)** | [Vercel](https://vercel.com) | [ai-crop-disease-diagnosis-system.vercel.app](https://ai-crop-disease-diagnosis-system.vercel.app) | Root dir: `frontend/admin_dashboard`, auto-deploy |
| **Flutter Web** | [Firebase Hosting](https://firebase.google.com) | [ai-crop-disease-7c811.web.app](https://ai-crop-disease-7c811.web.app) | Firebase project: `ai-crop-disease-7c811`, auto-deploy via GitHub Actions (`deploy-flutter.yml`) on `frontend/flutter_app/**` changes |
| **PostgreSQL** | Render Managed DB | *(internal connection string)* | Provisioned alongside the backend web service |
| **Redis** | Render Redis (or Upstash) | *(internal connection string)* | Set `REDIS_URL` env var on Render |

### Backend — Render

**Live URL**: `https://ai-crop-disease-diagnosis-system-aumh.onrender.com`

1. Create a new **Web Service** on Render.
2. Connect the GitHub repo; set **Root Directory** to `backend`.
3. **Build command**: `pip install -r requirements.txt`
4. **Start command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Add environment variables (see table below).

> **Note (Free Tier)**: The service spins down after 15 minutes of inactivity. A keep-alive ping is built into the app — set `RENDER_EXTERNAL_URL=https://ai-crop-disease-diagnosis-system-aumh.onrender.com` to enable it (pings `/health` every 14 minutes).

> **ML Model on Render**: Due to the 512 MB RAM limit, the app automatically falls back to `Disease_Classification_v2_noflex.tflite` (23 MB, Flex-op free). The larger `Disease_Classification_v2_compressed.tflite` (46 MB) works locally but triggers a `FlexPad` error on Render's standard TensorFlow build.

Required environment variables on Render:

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Render PostgreSQL connection string (`postgresql+asyncpg://...`) |
| `JWT_SECRET_KEY` | Random 32+ character secret |
| `REDIS_URL` | Redis connection string |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name |
| `CLOUDINARY_API_KEY` | Cloudinary API key |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret |
| `AGMARKNET_API_KEY` | OGD Platform API key for market prices |
| `ALLOWED_ORIGINS` | Comma-separated CORS origins (Vercel + Firebase URLs) |
| `DEBUG` | `false` |

### Admin Dashboard — Vercel

**Live URL**: `https://ai-crop-disease-diagnosis-system.vercel.app`

1. Import the GitHub repo on Vercel.
2. Set **Root Directory** to `frontend/admin_dashboard`.
3. Framework preset: **Next.js** (auto-detected).
4. Add `NEXT_PUBLIC_API_URL=https://ai-crop-disease-diagnosis-system-aumh.onrender.com`.

Deploys automatically on every push to `main`.

### Flutter Web — Firebase Hosting

**Live URL**: `https://ai-crop-disease-7c811.web.app`  
**Firebase project**: `ai-crop-disease-7c811`

#### Auto-Deploy (Primary)

Pushing to `main` with changes inside `frontend/flutter_app/**` automatically triggers the `deploy-flutter.yml` GitHub Actions workflow:

```
git push origin main
  └─► deploy-flutter.yml triggered
        ├─ flutter pub get
        ├─ flutter gen-l10n           (generate localization files)
        ├─ flutter build web --release --dart-define=BASE_URL=<RENDER_URL>
        └─ FirebaseExtended/action-hosting-deploy@v0  → live in ~3 min
```

Required GitHub Secrets for the workflow:

| Secret | Description |
|--------|-------------|
| `BACKEND_BASE_URL` | Render backend URL |
| `OPENWEATHER_API_KEY` | OpenWeather API key |
| `GEMINI_API_KEY` | Google Gemini API key |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase service account JSON |
| `FIREBASE_PROJECT_ID` | `ai-crop-disease-7c811` |

See [CI_CD.md](CI_CD.md) for full workflow details.

#### Manual Deploy (One-time Setup / Emergency)

```bash
# One-time setup
firebase login
firebase init hosting   # public dir: build/web, rewrite all to index.html

# Build and deploy manually
flutter pub get
flutter gen-l10n
flutter build web --release --dart-define=BASE_URL=https://ai-crop-disease-diagnosis-system-aumh.onrender.com
firebase deploy --only hosting
```

Config is in `firebase.json` inside `frontend/flutter_app/`.

---

## File Storage — Cloudinary

User-uploaded images (diagnosis photos, community posts, question attachments) are stored on **Cloudinary** in production. Local disk storage is used as a fallback when Cloudinary credentials are not set.

| Setting | Env Variable | Description |
|---------|-------------|-------------|
| Cloud name | `CLOUDINARY_CLOUD_NAME` | Your Cloudinary cloud |
| API key | `CLOUDINARY_API_KEY` | Found in Cloudinary dashboard |
| API secret | `CLOUDINARY_API_SECRET` | Found in Cloudinary dashboard |
| Folder | `CLOUDINARY_FOLDER` | Default: `crop_diagnosis` |

Images are organised by upload category:
- `crop_diagnosis/diagnosis/` — disease diagnosis images
- `crop_diagnosis/community/` — community post media
- `crop_diagnosis/questions/` — question attachments

When `CLOUDINARY_CLOUD_NAME` is empty, files are saved locally under `backend/uploads/`.

---

## Deployment Pipeline

This project uses **two GitHub Actions workflows** to automate all deployments:

| Workflow file | Trigger | What it deploys |
|--------------|---------|----------------|
| `.github/workflows/ci.yml` | Push / PR to `main` or `master` | Runs all tests (no deploy) |
| `.github/workflows/deploy-flutter.yml` | Push to `main` (`frontend/flutter_app/**` changed) + manual | Flutter Web → Firebase Hosting |

### How Each Platform Auto-Deploys

#### Backend — Render
Render watches the connected GitHub repo. On every push to `main`, it:
1. Pulls the latest code from `backend/`
2. Runs the build command: `pip install -r requirements.txt`
3. Restarts the service with: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

> No GitHub Actions step needed — Render's GitHub integration handles this natively.

#### Admin Dashboard — Vercel
Vercel's GitHub integration watches the repo. On every push to `main`, it:
1. Detects changes in `frontend/admin_dashboard/`
2. Runs `npm run build` (Next.js)
3. Deploys the output to the Vercel CDN globally

> No GitHub Actions step needed — Vercel's GitHub integration handles this natively.

#### Flutter Web — Firebase Hosting (`deploy-flutter.yml`)
The `deploy-flutter.yml` workflow runs when `frontend/flutter_app/**` files change:

```yaml
# Simplified view of .github/workflows/deploy-flutter.yml
steps:
  - Setup Flutter 3.38.1
  - Create assets/.env from secrets        # OPENWEATHER_API_KEY, GEMINI_API_KEY
  - flutter pub get
  - flutter gen-l10n                        # Localization
  - flutter build web --release \
      --dart-define=BASE_URL=${{ secrets.BACKEND_BASE_URL }}
  - FirebaseExtended/action-hosting-deploy@v0   # Deploy to Firebase
```

### Full Deployment Flow Diagram

```
git push origin main
       │
       ├──► Render detects push ──────────────────────► Backend live (auto)
       │
       ├──► Vercel detects push ──────────────────────► Admin Dashboard live (auto)
       │
       ├──► GitHub Actions: ci.yml ──────────────────► Tests pass/fail
       │       ├─ backend job  (pytest)
       │       ├─ flutter job  (flutter test)
       │       └─ admin job    (vitest + next build)
       │
       └──► GitHub Actions: deploy-flutter.yml ───────► Flutter Web live (auto)
               (only if frontend/flutter_app/** changed)
```

---

## Monitoring & Logging

### Logging Architecture

The system has **three separate logging layers** — each independent:

| Layer | Tool | Output | Visible In |
|-------|------|--------|------------|
| Backend API requests | `SystemLoggingMiddleware` | `system_logs` DB table | Admin Dashboard |
| Backend errors/general | `loguru` | `backend/logs/app.log` + `errors.log` | Terminal / files |
| Flutter app | `AppLogger` (`dart:developer`) | Device console | `flutter run` / Logcat / Xcode |
| Admin dashboard | `logger.ts` (`console.*`) | Terminal + browser DevTools | `npm run dev` terminal |

### Backend Log Files (loguru)

```bash
# Watch live logs
tail -f backend/logs/app.log

# See only errors
cat backend/logs/errors.log

# Trigger a test error
curl http://localhost:8000/nonexistent-route
```

| File | Level | Rotation | Retention |
|------|-------|----------|-----------|
| `logs/app.log` | DEBUG+ | 10 MB | 7 days |
| `logs/errors.log` | ERROR+ | 5 MB | 30 days |

### Flutter Logs (AppLogger)

```dart
AppLogger.info('Market loaded', tag: 'Market');
AppLogger.error('API failed', tag: 'Market', error: e);
```

View in Android Logcat: `adb logcat -s CropDiag`

### Rate Limiting

All API endpoints are limited to **60 requests/minute per IP** via `slowapi`.
Exceeding returns `HTTP 429` with `{"detail": "Rate limit exceeded: 60 per 1 minute"}`.

### Test Rate Limiting

```bash
# Fire 65 rapid requests — last few should return 429
for i in {1..65}; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/health; done
```

### Health Check Endpoint

```
GET /health

Response:
{
  "status": "healthy",
  "database": "connected",
  "model_used": "TFLite-v2 (Disease_Classification_v2_noflex.tflite)",
  "version": "1.0.0"
}
```

The `model_used` field reflects whichever ML model file was actually loaded at startup (varies between local and Render environments).

```bash
# Quick health check against the live Render deployment
curl -s https://ai-crop-disease-diagnosis-system-aumh.onrender.com/health | python3 -m json.tool
```

### Metrics

Key metrics tracked in `system_metrics` and `daily_stats`:

- Total diagnoses per day
- API response times
- Error count
- Active users
- Average ML confidence

---

## Backup & Recovery

### Backup Scripts

Two backup scripts are provided in `backend/scripts/`:

| Script | Platform | Usage |
|--------|----------|-------|
| `backup_db.sh` | Linux/macOS | Shell script, ideal for cron |
| `backup_db.py` | All platforms | Python script, reads `.env` automatically |
| `restore_db.sh` | Linux/macOS | Restore from a `.sql.gz` backup |

All scripts read `DATABASE_URL` from `backend/.env` automatically.

### Running a Backup

You can use either script (they do the same thing):

**Option A: Python (Recommended for Cross-Platform)**
Works on macOS, Windows, and Linux. Requires Python 3.9+.
```bash
cd backend
python scripts/backup_db.py
```

**Option B: Shell Script (macOS / Linux)**
Native script, ideal for cron jobs.
```bash
cd backend
bash scripts/backup_db.sh
```

**What happens:**
1. A new file is created at `backend/backups/cropdiag_YYYYMMDD_HHMMSS.sql.gz`
2. Old backups (>7 days) are automatically deleted
3. Activity is logged to `backend/logs/backup.log`

### Restoring a Backup

**⚠️ WARNING**: maximizing this will DELETE your current database and replace it with the backup content. Only run this if you need to recover lost data.

```bash
cd backend
bash scripts/restore_db.sh backups/cropdiag_20260219_230355.sql.gz
```
The script will ask you to type `yes` before proceeding.

**How it works:**
1. **Unzips** the `.sql.gz` file in memory (streaming).
2. **Drops** the existing database (all current data is removed).
3. **Creates** a fresh, empty database.
4. **Restores** the schema and data from the backup file using `psql`.

### Troubleshooting
- **Python Version**: The `.py` script is compatible with Python 3.9+ (type hints fixed).
- **Permissions**: Ensure `scripts/backup_db.sh` is executable (`chmod +x scripts/backup_db.sh`).

### Automated Backups (Cron)

```bash
# Edit crontab
crontab -e

# Add this line — runs daily at 2 AM
0 2 * * * /path/to/SE_Proj/backend/scripts/backup_db.sh >> /path/to/SE_Proj/backend/logs/backup.log 2>&1
```

Backup activity is logged to `backend/logs/backup.log`.

---

## Scaling Considerations

### Horizontal Scaling

To scale for higher traffic, you should introduce a **Load Balancer**:

- **Nginx / HAProxy**: Place in front of multiple backend containers.
- **Docker Swarm / Kubernetes**: Use an orchestrator to manage replicas.

### Vertical Scaling

- Increase server CPU/RAM for ML inference
- Use GPU instances for faster model predictions

### Caching

Redis is the primary cache layer for the backend, dramatically improving response times for high-traffic endpoints:
- **Admin Dashboard**: 0.49ms (Postgres) → **0.27ms** (Redis) 
- **Encyclopedia Crops**: 0.97ms (Postgres) → **0.38ms** (Redis)
- **Market API cache**: Stores Agmarknet responses for 1 hour (TTL) to stay within rate limits
- **Rate-limit backoff**: Persists the 1-hour Agmarknet backoff state across backend restarts
- **Overall average speedup**: **1.6x faster** (up to **5.7x** under load) with sub-millisecond response times.

**Fallback**: If Redis is unavailable, it gracefully falls back to an in-memory dict (works per-process).
**Config**: Set `REDIS_URL=redis://redis:6379/0` in the backend environment.

```bash
# Useful Redis commands during development
docker exec crop_diagnosis_redis redis-cli KEYS "market_cache:*"
docker exec crop_diagnosis_redis redis-cli TTL "market_cache:10_0_None"

# Flush all Redis data
docker exec crop_diagnosis_redis redis-cli FLUSHALL

# Or use the API cache-clear endpoint (admin only)
curl -X POST http://localhost:8000/market/cache/clear \
  -H "Authorization: Bearer <admin_token>"
```

---

## Version Control & Branching Strategy

**Platform**: Git + GitHub (`akshayks13/AI-Crop-Disease-Diagnosis-System`)

### Branching Convention

| Branch prefix | Use case |
|--------------|----------|
| `main` | Production-ready, protected — all auto-deploys originate here |
| `feature/` | New features (e.g., `feature/market-prices`) |
| `bugfix/` | Bug fixes (e.g., `bugfix/login-error`) |
| `hotfix/` | Urgent production fixes |
| `docs/` | Documentation updates |
| `refactor/` | Code refactoring |

### Commit Standard

Conventional Commits format: `<type>(<scope>): <description>`

Examples: `feat(auth): add OTP email verification`, `fix(ml): fallback to noflex model on Render`

Full conventions and PR checklist: [CONTRIBUTING.md](CONTRIBUTING.md).

### Protected Main Branch

Every push to `main`:
- Triggers GitHub Actions CI (lint + test all three components)
- Triggers Render backend auto-deploy
- Triggers Vercel admin dashboard auto-deploy
- Triggers `deploy-flutter.yml` if `frontend/flutter_app/**` changed

---

## Code Quality & Security Scanning

### Automated Quality Tools in CI

| Tool | Language | What It Checks | Runs In CI |
|------|----------|----------------|------------|
| **Ruff** | Python | Linting + style (replaces Flake8/Black/isort) | ✅ |
| **ESLint** | TypeScript | React/Next.js code quality | ✅ |
| **flutter analyze** | Dart | Static analysis, type errors, unused code | ✅ |
| **Pytest** | Python | Unit & integration tests | ✅ |
| **Vitest** | TypeScript | Unit tests for admin utilities | ✅ |
| **flutter test** | Dart | Widget & unit tests | ✅ |
| **Playwright** | TypeScript | E2E browser tests (local; CI job planned) | Planned |

### Security Hardening in Application Code

- **Parameterized queries**: SQLAlchemy ORM prevents SQL injection at the ORM level
- **bcrypt** password hashing (no plaintext passwords stored)
- **JWT** with short-lived access tokens (30 min) + refresh tokens (7 days)
- **CORS** restricted to known production origins (Vercel + Firebase URLs only)
- **Rate limiting**: slowapi — 60 req/min per IP on all endpoints; returns `HTTP 429`
- **RBAC**: Three-role system (FARMER / EXPERT / ADMIN) enforced on every protected route
- **Secrets**: All sensitive credentials stored in GitHub Actions Secrets — never committed to code

### Vulnerability Scanning — Current Status

| Tool | Status | Notes |
|------|--------|-------|
| **Ruff** | Active in CI | Python code quality |
| **ESLint** | Active in CI | TypeScript code quality |
| **npm audit** | Manual | `npm audit` in `frontend/admin_dashboard/` |
| **pip-audit** | Manual | `pip-audit -r backend/requirements.txt` |
| **Trivy / Snyk** | Planned | Container image + dependency CVE scanning |
| **SonarQube** | Planned | Deep static analysis and code smell detection |

```bash
# Run dependency vulnerability checks manually
npm audit --audit-level=moderate                       # Admin dashboard
pip install pip-audit && pip-audit -r backend/requirements.txt  # Python deps
```

## Rollback Strategy

### Per-Platform Rollback

| Component | Platform | Rollback Method | Time to Rollback |
|-----------|----------|----------------|-----------------|
| **Backend** | Render | Dashboard → Deploys → select old deploy → **Rollback** | ~2 min |
| **Admin Dashboard** | Vercel | Dashboard → Deployments → select old → **Promote to Production** | ~1 min |
| **Flutter Web** | Firebase | `firebase hosting:rollback` (keeps last 25 releases) | ~1 min |
| **Database** | Render | Restore from `.sql.gz` backup (see below) | ~5–15 min |

### Backend — Render Rollback

```bash
# Option A: Render Dashboard
# Render → your service → "Deploys" tab → click old deploy → "Rollback to this deploy"

# Option B: Revert git commit and push (triggers new deploy with old code)
git revert HEAD
git push origin main
```

### Admin Dashboard — Vercel Rollback

```bash
# Option A: Vercel Dashboard
# Deployments → select a previous deployment → "..." → "Promote to Production"

# Option B: Revert and push
git revert HEAD
git push origin main
```

### Flutter Web — Firebase Rollback

Firebase Hosting keeps the last 25 releases automatically.

```bash
# List recent releases
firebase hosting:releases:list

# Roll back to the previous release immediately
firebase hosting:rollback

# Or clone a specific release ID
firebase hosting:clone <VERSION_ID>:live <PROJECT_ID>:live
```

### Database Rollback

See [Backup & Recovery](#backup--recovery). Restore a backup with:

```bash
cd backend
bash scripts/restore_db.sh backups/cropdiag_YYYYMMDD_HHMMSS.sql.gz
```

> ⚠️ Database restore is **destructive** — always take a fresh backup immediately before restoring.

---
