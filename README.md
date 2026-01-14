# AI-Based Crop Disease Diagnosis System

An AI-powered agricultural solution that helps farmers diagnose crop diseases using image analysis and provides treatment recommendations with expert consultation.

## Features

### For Farmers
- **AI Diagnosis**: Upload crop images for instant disease detection
- **Treatment Plans**: Get detailed chemical and organic treatment options
- **Voice Narration**: TTS support for accessibility
- **Expert Consultation**: Ask verified agricultural experts
- **Offline Support**: Works without internet connection

### For Experts
- **Question Dashboard**: View and answer farmer questions
- **Profile Management**: Manage expertise and qualifications
- **Approval System**: Admin verification before access

### For Admins
- **Dashboard Analytics**: Real-time metrics and trends
- **Expert Approval**: Review and approve expert applications
- **User Management**: Manage all system users
- **System Logs**: Monitor system activity

## Tech Stack

| Component | Technology |
|-----------|------------|
| Mobile App | Flutter + Riverpod |
| Admin Dashboard | Next.js + TypeScript + Tailwind |
| Backend API | FastAPI + SQLAlchemy |
| Database | PostgreSQL |
| ML Pipeline | PyTorch + OpenCV |
| Auth | JWT + RBAC |

## Project Structure

```
├── backend/                 # FastAPI Backend
│   ├── app/
│   │   ├── auth/           # JWT authentication
│   │   ├── models/         # SQLAlchemy models
│   │   ├── routes/         # API endpoints
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── services/       # Business logic
│   │   └── main.py         # App entry
│   └── requirements.txt
├── frontend/
│   ├── flutter_app/        # Mobile App
│   │   ├── lib/
│   │   │   ├── config/     # Theme & routes
│   │   │   ├── core/       # API, storage
│   │   │   └── features/   # Feature modules
│   │   └── pubspec.yaml
│   └── admin_dashboard/    # Next.js Admin
│       └── src/app/        # App pages
├── database/
│   └── init.sql            # Schema initialization
└── ml_models/              # ML models
```

## Quick Start

### Prerequisites
- Python 3.9+
- Node.js 18+
- Flutter 3.10+
- PostgreSQL 14+

---

### 1. PostgreSQL Setup

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

---

## Default Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@cropdiagnosis.com | admin_password |

> Change these credentials in production!

---

## API Endpoints

### Authentication
- `POST /auth/register` - Register user
- `POST /auth/login` - Login
- `POST /auth/refresh` - Refresh token
- `GET /auth/me` - Current user

### Farmer
- `POST /diagnosis/predict` - Upload image for diagnosis
- `GET /diagnosis/history` - Diagnosis history
- `POST /questions` - Ask expert

### Expert
- `GET /expert/questions` - View questions
- `POST /expert/answer` - Submit answer

### Admin
- `GET /admin/dashboard` - Dashboard metrics
- `GET /admin/experts/pending` - Pending experts
- `POST /admin/experts/approve/{id}` - Approve expert

---

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql+asyncpg://user:pass@localhost:5432/crop_diagnosis` |
| `JWT_SECRET_KEY` | Secret for JWT tokens | `your-secret-key-here` |
| `ALLOWED_ORIGINS` | CORS allowed origins | `http://localhost:3000` |
| `DEBUG` | Enable debug mode | `true` or `false` |

---

## ML Model

The system uses a simulated ML model for development. To integrate a real model:

1. Train a PyTorch model on crop disease dataset
2. Update `backend/app/services/ml_service.py`
3. Replace the `predict()` method with actual inference

---

## App Screens

- **Auth**: Splash, Login, Register
- **Farmer**: Home, Diagnosis, Results, History, Ask Expert
- **Expert**: Dashboard, Questions, Answer
- **Common**: Profile

---
