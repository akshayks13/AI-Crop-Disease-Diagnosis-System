# AI-Based Crop Disease Diagnosis System

An AI-powered agricultural solution that helps farmers diagnose crop diseases using image analysis and provides treatment recommendations with expert consultation.


## Table of Contents

- [Quick Start](#quick-start)
- [Overview](#overview)
- [Application URLs](#application-urls)
- [Running the Application](#running-the-application)
  - [Backend](#backend)
  - [Frontend](#frontend)
- [Environment Variables](#environment-variables)
  - [Backend Configuration](#backend-configuration)
  - [Frontend Configuration](#frontend-configuration)
- [Testing](#testing)
  - [Backend Tests](#backend-tests)
  - [Frontend Tests](#frontend-tests)
  - [End-to-End Tests](#end-to-end-tests)
- [Database Seeding](#database-seeding)
- [API Overview](#api-overview)
- [Development Guidelines](#development-guidelines)
- [Important Notes](#important-notes)

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
- **AI Diagnosis**: Upload crop images for instant disease detection
- **Treatment Plans**: Get detailed chemical and organic treatment options
- **Farm Management**: Track crops, growth progress, and manage farm tasks
- **Market Prices**: View real-time commodity prices from **Agmarknet** (Government of India) with fallback to local database
- **Community Forum**: Share posts, comments, and like content
- **Crop Encyclopedia**: Browse detailed crop and disease information
- **Expert Consultation**: Ask verified agricultural experts
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
| Mobile App | Flutter + Riverpod |
| Admin Dashboard | Next.js + TypeScript + Tailwind |
| Backend API | FastAPI + SQLAlchemy |
| Database | PostgreSQL |
| ML Pipeline | PyTorch + OpenCV |
| Auth | JWT + RBAC |

---

## Application URLs

| Application | Local URL | Docker URL | Description |
|-------------|-----------|------------|-------------|
| **Backend API** | `http://localhost:8000` | `http://localhost:8000` | FastAPI Server & Swagger Docs |
| **Admin Dashboard** | `http://localhost:3000` | `http://localhost:3000` | Web Dashboard for Admins |
| **Flutter App** | `n/a` (Mobile) | `http://localhost:8080` | Crop Diagnosis App (Web Version) |
| **Database** | `localhost:5432` | `localhost:5432` | PostgreSQL Database |

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
│   ├── tests/              # Pytest integration tests (58 tests)
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

# Run Tests
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
```

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
| `ALLOWED_ORIGINS` | CORS allowed origins | `http://localhost:3000` |
| `DEBUG` | Enable debug mode | `true` or `false` |
| `AGMARKNET_API_KEY` | API Key for OGD Platform (Agmarknet) | `your-api-key` |
| `AGMARKNET_API_URL` | Agmarknet API Endpoint | `https://api.data.gov.in/resource/...` |

---

## ML Model

The system uses a simulated ML model for development. To integrate a real model:

1. Train a PyTorch model on crop disease dataset
2. Update `backend/app/services/ml_service.py`
3. Replace the `predict()` method with actual inference

---

## App Screens

- **Auth**: Splash, Login, Register, OTP Verification, Forgot Password
- **Farmer**: Home, Diagnosis (Camera/Gallery), Results, History, Ask Expert, My Questions, Farm Management (Crops & Tasks), Market Prices, Community Forum, Crop Encyclopedia, Disease Encyclopedia
- **Expert**: Dashboard, Open Questions, Answer Question, My Answers, Statistics, Community, Knowledge Base
- **Admin** (Web Dashboard): Overview Metrics, User Management, Expert Approval, Diagnosis Viewer, System Logs, Agronomy Management
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
