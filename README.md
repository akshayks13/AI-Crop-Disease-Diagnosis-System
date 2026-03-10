# AI-Based Crop Disease Diagnosis System

An AI-powered agricultural solution that helps farmers diagnose crop diseases using image analysis and provides treatment recommendations with expert consultation.

![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Next.js](https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=next.js&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-DC382D?style=for-the-badge&logo=redis&logoColor=white)
![TensorFlow](https://img.shields.io/badge/TensorFlow-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white)
![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Render](https://img.shields.io/badge/Render-46E3B7?style=for-the-badge&logo=render&logoColor=white)
![Vercel](https://img.shields.io/badge/Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)


## Table of Contents

- [Quick Start](#quick-start)
- [Overview](#overview)
- [Application URLs](#application-urls)
- [Production Deployment](#production-deployment)
- [Running the Application](#running-the-application)
  - [Backend](#backend)
  - [Frontend](#frontend)
- [Environment Variables](#environment-variables)
- [Testing](#testing)
- [Database Seeding](#database-seeding)
- [Database Backups](#database-backups)
- [API Overview](#api-overview)
- [Development Guidelines](#development-guidelines)

---

## Quick Start

### Prerequisites
- Docker & Docker Compose
- **OR** Python 3.9+, Node.js 18+, Flutter 3.10+, PostgreSQL 14+

### Swift Run (Docker)
Get the entire system running in minutes:

```bash
# Build and start all services
docker-compose up --build -d
```

Access the apps:
- **Mobile App (Web)**: http://localhost:8080
- **Admin Dashboard**: http://localhost:3000
- **Backend API**: http://localhost:8000/docs

---

## Overview

### Features

### For Farmers
- **AI Diagnosis**: Upload crop images — backend runs Keras/TFLite model server-side and returns disease label, confidence, and severity
- **DSS Advisory**: Decision Support System generates risk-scored treatment advisories (cultural + chemical + organic) from the disease label
- **Disease Outbreak Map**: Interactive OpenStreetMap showing geo-tagged disease outbreaks in real-time
- **Treatment Plans**: Detailed chemical and organic treatment options with step-by-step instructions
- **Farm Management**: Track crops, auto-calculated growth progress, and manage farm tasks
- **Market Prices**: Real-time commodity prices from **Agmarknet** (Government of India) with Redis → in-memory → DB fallback
- **Community Forum**: Share posts, comments, and like content — filter by category or expert-only
- **Encyclopedia**: Browse Crops, Diseases & **Pests** (3-tab UI with IPM controls, damage type, life cycle)
- **Expert Consultation**: Ask verified agricultural experts questions with file attachments

### ⚡ Performance (Redis Caching)
Redis is used across 6 high-traffic endpoints (Encyclopedia, Expert Trending, Admin Dashboard, Agmarknet API). 
Based on our isolated latency benchmark (`tests/test_redis_latency.py`):
* **Admin Dashboard** (12 COUNT queries): 0.49ms (Postgres) → **0.27ms** (Redis) 
* **Encyclopedia Crops**: 0.97ms (Postgres) → **0.38ms** (Redis)
* **Overall average speedup**: **1.6x faster** (up to **5.7x** under load) with sub-millisecond response times.

- **Diagnosis Ratings**: Rate AI and expert answers for quality feedback
- **Voice Narration**: TTS support for accessibility

### For Experts
- **Question Dashboard**: View and answer farmer questions
- **Community Contributions**: Share expert knowledge and articles
- **Knowledge Base**: Access agronomy diagnostic rules and patterns
- **Statistics**: View answer count, average ratings, and trends
- **Profile Management**: Manage expertise and qualifications

### For Admins
- **Dashboard Analytics**: Real-time metrics and daily trends
- **Expert Approval**: Review and approve expert applications
- **User Management**: Manage all system users (suspend, activate)
- **Diagnosis Overview**: View all diagnoses across the platform
- **System Logs**: Monitor system activity with level/source filtering
- **Agronomy Rules**: CRUD on diagnostic rules, treatment constraints, seasonal patterns

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System architecture overview |
| [API_REFERENCE.md](docs/API_REFERENCE.md) | Complete API endpoint documentation |
| [DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) | ER diagram and table descriptions |
| [ML_DOCS.md](docs/ML_DOCS.md) | Machine learning model documentation |
| [TESTING.md](docs/TESTING.md) | Testing strategy and guidelines |
| [DEVOPS.md](docs/DEVOPS.md) | Deployment and infrastructure |
| [SECURITY.md](docs/SECURITY.md) | Security considerations |
| [CONTRIBUTING.md](docs/CONTRIBUTING.md) | Contribution guidelines |
| [CI_CD.md](docs/CI_CD.md) | CI/CD pipeline configuration |

### Component Overviews
| Overview | Description |
|----------|-------------|
| [BACKEND_OVERVIEW.md](docs/overviews/BACKEND_OVERVIEW.md) | Backend architecture, services, and scripts |
| [FLUTTER_OVERVIEW.md](docs/overviews/FLUTTER_OVERVIEW.md) | Flutter app architecture and packages |
| [ADMIN_DASHBOARD_OVERVIEW.md](docs/overviews/ADMIN_DASHBOARD_OVERVIEW.md) | Admin dashboard features and deployment |

### UML Diagrams
| Diagram | Description |
|---------|-------------|
| [class_diagram.md](docs/diagrams/class_diagram.md) | Entity classes and relationships |
| [sequence_diagram.md](docs/diagrams/sequence_diagram.md) | API interaction flows |
| [activity_diagram.md](docs/diagrams/activity_diagram.md) | User activity flows |
| [use_case_diagram.md](docs/diagrams/use_case_diagram.md) | Actor use cases |

### Tech Stack

| Component | Technology |
|-----------|------------|
| Mobile App | Flutter 3.38+ + Riverpod |
| Admin Dashboard | Next.js 16 + TypeScript + Tailwind CSS |
| Backend API | FastAPI + SQLAlchemy 2.0 (async) |
| Database | PostgreSQL 15 |
| Cache | Redis 7 |
| ML Inference | TensorFlow / Keras + TFLite (server-side) |
| DSS Engine | CSV-based advisory engine (Python) |
| File Storage | Cloudinary (production) / Local disk (dev) |
| Market Data | Agmarknet — OGD Platform API |
| Auth | JWT + RBAC |
| Hosting — Backend | Render |
| Hosting — Admin | Vercel |
| Hosting — Flutter Web | Firebase Hosting |

---

## Application URLs

| Application | Local URL | Description |
|-------------|-----------|-------------|
| **Backend API** | `http://localhost:8000` | FastAPI Server & Swagger Docs (`/docs`) |
| **Admin Dashboard** | `http://localhost:3000` | Web Dashboard for Admins |
| **Flutter Web** | `http://localhost:8080` | Crop Diagnosis App (Docker) |
| **Database** | `localhost:5432` | PostgreSQL |
| **Redis** | `localhost:6379` | Cache |

---

## Production Deployment

| Component | Platform | Live URL | Auto-deploys on `main` push |
|-----------|----------|----------|-----------------------------|
| **Backend (FastAPI)** | [Render](https://render.com) | [ai-crop-disease-diagnosis-system-aumh.onrender.com](https://ai-crop-disease-diagnosis-system-aumh.onrender.com) | ✅ |
| **Admin Dashboard (Next.js)** | [Vercel](https://vercel.com) | [ai-crop-disease-diagnosis-system.vercel.app](https://ai-crop-disease-diagnosis-system.vercel.app) | ✅ |
| **Flutter Web** | [Firebase Hosting](https://firebase.google.com/docs/hosting) | [ai-crop-disease-7c811.web.app](https://ai-crop-disease-7c811.web.app) | ✅ (via `deploy-flutter.yml`) |

See [DEVOPS.md](docs/DEVOPS.md) for environment variable setup and step-by-step deployment instructions.

---

## Project Structure

```
├── backend/                 # FastAPI Backend
│   ├── app/
│   │   ├── agronomy/       # Agronomy intelligence routes
│   │   ├── auth/           # JWT authentication & dependencies
│   │   ├── middleware/     # Logging middleware
│   │   ├── models/         # SQLAlchemy models
│   │   ├── routes/         # API endpoints (farm, market, community, etc.)
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── services/       # Business logic (ML, diagnosis, storage)
│   │   ├── database.py     # DB connection & session
│   │   ├── seed.py         # Database seeding
│   │   └── main.py         # App entry point
│   ├── tests/              # Pytest integration tests (59 tests)
│   └── requirements.txt
├── frontend/
│   ├── flutter_app/        # Mobile App (Flutter + Riverpod)
│   │   ├── lib/
│   │   │   ├── config/     # Theme & routes
│   │   │   ├── core/       # API client, services, utils
│   │   │   └── features/   # auth, diagnosis, farm, community, market, etc.
│   │   ├── test/           # Flutter tests (54 tests)
│   │   └── pubspec.yaml
│   └── admin_dashboard/    # Next.js Admin Dashboard
│       ├── src/
│       │   ├── app/        # Pages (dashboard, users, experts, agronomy, logs)
│       │   ├── components/ # Reusable UI components
│       │   └── lib/        # API client utilities
│       └── package.json
├── database/
│   └── init.sql            # Schema initialization
├── ml_models/              # ML model files (TFLite)
├── docs/                   # Project documentation
└── docker-compose.yml      # Docker orchestration
```

## Running the Application

### 1. PostgreSQL Setup

### Windows

1. Download PostgreSQL:  
   https://www.postgresql.org/download/windows/

2. During installation:
   - Set a password for user `postgres`
   - Default port: `5432`

3. Create database:
```sql
CREATE DATABASE crop_diagnosis;
```
Initialize schema:

```bash
cd backend
psql -U postgres -d crop_diagnosis -f ../database/init.sql
```

### macOS

#### Install PostgreSQL (macOS)
```bash
# Install via Homebrew
brew install postgresql@16

# Start PostgreSQL service
brew services start postgresql@16
```

#### Install PostgreSQL (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

#### Create Database
```bash
# Create the database
createdb crop_diagnosis

# Initialize tables (from backend directory)
cd backend
psql -d crop_diagnosis -f ../database/init.sql
```

> **Note**: On macOS with Homebrew, the default PostgreSQL user is your system username (no password). On Linux, you may need to use `sudo -u postgres` prefix.

---

### 2. Backend Setup

### Windows
```bash
cd backend

python -m venv venv
venv\Scripts\activate

pip install -r requirements.txt
copy .env.example .env
```
Run server:

```bash
python -m uvicorn app.main:app --reload --port 8000
```

### macOS

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Start Redis (Required for caching)
# Make sure Docker is running on your machine first
docker run -d --name crop_diagnosis_redis -p 6379:6379 redis:7-alpine
# View logs: docker logs crop_diagnosis_redis
# Stop container: docker stop crop_diagnosis_redis

# Configure environment
cp .env.example .env
# Edit .env with your database credentials:
# DATABASE_URL=postgresql+asyncpg://your_username@localhost:5432/crop_diagnosis

# Run server
./venv/bin/python -m uvicorn app.main:app --reload --port 8000
```

API docs available at: http://localhost:8000/docs

---

### 3. Flutter App

```bash
cd frontend/flutter_app

# Get dependencies
flutter pub get

# Generate localization files (Required on first setup or branch switch)
flutter gen-l10n

# Run app
flutter run
```

---

### 4. Admin Dashboard

```bash
cd frontend/admin_dashboard

# Install dependencies
npm install

# Run dev server
npm run dev
```

Dashboard available at: http://localhost:3000


## Testing & Linting

### Backend (FastAPI)
```bash
cd backend

# Run Linter (Ruff)
ruff check .

# Run Tests (Pytest)
pytest
```

### Mobile App (Flutter)
```bash
cd frontend/flutter_app

# Run Linter
flutter analyze --no-fatal-infos

# Run Tests
flutter test
```

### Admin Dashboard (Next.js)
```bash
cd frontend/admin_dashboard

# Run Linter
npm run lint

# Run Tests (Vitest)
npm run test
```

---

## Database Backups

Two scripts are available in `backend/scripts/`:

- `backup_db.py`: Cross-platform backup script (Recommended)
- `backup_db.sh`: Shell script for Linux/macOS (Good for Cron)

**Usage:**
```bash
cd backend
python scripts/backup_db.py
```
Backups are saved to `backend/backups/` and retained for 7 days.

**Automated Backups (Cron):**
To run automatically every night at 2:00 AM, add this to your system crontab (`crontab -e`):
```bash
0 2 * * * /path/to/project/backend/scripts/backup_db.sh >> /path/to/project/backend/logs/backup.log 2>&1
```

See [DEVOPS.md](docs/DEVOPS.md) for full restore instructions and troubleshooting.

---

## Default Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@cropdiagnosis.com | admin123 |
| Farmer | farmer1@example.com | farmer123 |
| Farmer | farmer2@example.com | farmer123 |
| Expert (Approved) | expert1@example.com | expert123 |
| Expert (Pending) | expert2@example.com | expert123 |

> ⚠️ Change these credentials in production!

---

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql+asyncpg://user:pass@localhost:5432/crop_diagnosis` |
| `JWT_SECRET_KEY` | Secret for JWT tokens | `your-secret-key-here` |
| `ALLOWED_ORIGINS` | CORS allowed origins | `http://localhost:3000,http://localhost:8080` |
| `DEBUG` | Enable debug mode | `true` or `false` |
| `REDIS_URL` | Redis connection string (optional) | `redis://localhost:6379/0` |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary cloud name (production uploads) | `your-cloud` |
| `CLOUDINARY_API_KEY` | Cloudinary API key | from Cloudinary dashboard |
| `CLOUDINARY_API_SECRET` | Cloudinary API secret | from Cloudinary dashboard |
| `AGMARKNET_API_KEY` | API Key for OGD Platform (Agmarknet) | `your-api-key` |
| `AGMARKNET_API_URL` | Agmarknet API endpoint | `https://api.data.gov.in/resource/...` |

> When `CLOUDINARY_CLOUD_NAME` is empty, uploads are saved locally under `backend/uploads/`.

---

## ML Model

The backend loads a **Keras model** at startup (`Disease_Classification_v2.keras`) and falls back to TFLite (`Disease_Classification_v2_compressed.tflite`) if the Keras model is unavailable. Inference runs entirely server-side — the Flutter app uploads the image to `POST /diagnosis/predict` and receives the full diagnosis result.

The **DSS Advisory Engine** (`backend/app/services/dss_service.py`) then takes the disease label and generates a risk-scored advisory using CSV tables covering 19 crops and 38+ disease categories.

---

## App Screens

- **Auth**: Splash, Login, Register, OTP Verification, Forgot Password
- **Farmer**: Home, Diagnosis (Camera/Gallery), DSS Advisory, Results, History, Disease Outbreak Map, Ask Expert, My Questions, Farm Management (Crops & Tasks), Market Prices, Community Forum (with category/expert filters), Crop Encyclopedia, Disease Encyclopedia, Pest Encyclopedia
- **Expert**: Dashboard, Open Questions, Answer Question, My Answers, Statistics, Community, Knowledge Base
- **Admin** (Web Dashboard): Overview Metrics, User Management, Expert Approval, Diagnosis Viewer, System Logs, Agronomy Management, Encyclopedia (Crops, Diseases, Pests)
- **Common**: Profile, Settings

---

## Docker Deployment

### Quick Start with Docker
```bash
# Build and start all services
docker-compose up --build -d

# Check container status
docker ps
```

### Access Points
| Service | URL |
|---------|-----|
| Flutter App | http://localhost:8080 |
| Admin Dashboard | http://localhost:3000 |
| Backend API | http://localhost:8000/docs |
| Database | localhost:5432 |

### Useful Commands
```bash
# View backend logs (includes OTP codes for development)
docker logs crop_diagnosis_backend -f

# Restart a specific service
docker-compose restart backend

# Stop all containers
docker-compose down

# Rebuild after code changes
docker-compose up --build -d

# Reset Database (Delete all data and re-seed)
docker-compose down -v
```

### Database Access
Connect using any PostgreSQL client (DBeaver, TablePlus, pgAdmin):
- **Host**: localhost
- **Port**: 5432
- **Database**: crop_diagnosis
- **User**: postgres
- **Password**: postgres

Query database directly:
```bash
docker exec crop_diagnosis_db psql -U postgres -d crop_diagnosis -c "SELECT email, role FROM users;"
```

### OTP Retrieval (Development)
OTPs are logged to backend console. View them with:
```bash
docker logs crop_diagnosis_backend -f
```
Or query the database:
```bash
docker exec crop_diagnosis_db psql -U postgres -d crop_diagnosis -c "SELECT email, otp_code FROM users WHERE otp_code IS NOT NULL;"
```

---
