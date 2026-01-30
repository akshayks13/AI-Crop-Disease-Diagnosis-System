# 🌾 AI-Based Crop Disease Diagnosis System

An AI-powered agricultural solution that helps farmers diagnose crop diseases using image analysis and provides treatment recommendations with expert consultation.

---

## ✨ Features

### 👨🌾 For Farmers
- **AI Diagnosis**: Upload crop images for instant disease detection
- **Treatment Plans**: Chemical and organic treatment recommendations
- **Voice Narration**: Text-to-Speech (TTS) for accessibility
- **Expert Consultation**: Ask verified agricultural experts
- **Offline Support**: Works without continuous internet

### 🧑🔬 For Experts
- **Question Dashboard**: View and respond to farmer queries
- **Profile Management**: Manage expertise and qualifications
- **Approval System**: Admin verification before access

### 🛠️ For Admins
- **Dashboard Analytics**: Real-time metrics and trends
- **Expert Approval**: Review and approve expert applications
- **User Management**: Manage all system users
- **System Logs**: Monitor system activity

---

## 🧰 Tech Stack

| Component | Technology |
|---------|------------|
| Mobile App | Flutter + Riverpod |
| Admin Dashboard | Next.js + TypeScript + Tailwind |
| Backend API | FastAPI + SQLAlchemy |
| Database | PostgreSQL |
| ML Pipeline | PyTorch + OpenCV |
| Authentication | JWT + RBAC |

---

## 📁 Project Structure

```
├── backend/ # FastAPI Backend
│ ├── app/
│ │ ├── auth/ # JWT authentication
│ │ ├── models/ # SQLAlchemy models
│ │ ├── routes/ # API endpoints
│ │ ├── schemas/ # Pydantic schemas
│ │ ├── services/ # Business logic
│ │ └── main.py # App entry
│ └── requirements.txt
├── frontend/
│ ├── flutter_app/ # Mobile App
│ └── admin_dashboard/ # Next.js Admin Dashboard
├── database/
│ └── init.sql # Database schema
└── ml_models/ # ML models
```

---

## ⚡ Quick Start (Windows + macOS)

### 🔧 Prerequisites

| Tool | Version |
|----|---------|
| Python | 3.9+ |
| Node.js | 18+ |
| Flutter | 3.10+ |
| PostgreSQL | 14+ |

---

## 🗄️ PostgreSQL Setup

### 🪟 Windows

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

### 🍎 macOS

```bash
brew install postgresql@16
brew services start postgresql@16

createdb crop_diagnosis

cd backend
psql -d crop_diagnosis -f ../database/init.sql
```
Homebrew PostgreSQL uses your macOS username by default.

---

## 🧠 Backend Setup (FastAPI)

### 🪟 Windows
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

### 🍎 macOS
```bash
cd backend

python3 -m venv venv
source venv/bin/activate

pip install -r requirements.txt
cp .env.example .env
```
Run server:

```bash
uvicorn app.main:app --reload --port 8000
```
API Documentation:
http://localhost:8000/docs

---

## 📱 Flutter Mobile App
```bash
cd frontend/flutter_app
flutter pub get
flutter run
```

---

## 🖥️ Admin Dashboard (Next.js)
```bash
cd frontend/admin_dashboard
npm install
npm run dev
```
Dashboard URL:
http://localhost:3000

---

## 🔐 Default Credentials
| Role | Email | Password |
|------|-------|----------|
| Admin | admin@cropdiagnosis.com | admin_password |

⚠️ Change credentials in production.

---

## 🌐 API Endpoints

### 🔑 Authentication
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh`
- `GET /auth/me`

### 🌾 Farmer
- `POST /diagnosis/predict`
- `GET /diagnosis/history`
- `POST /questions`

### 🧑🔬 Expert
- `GET /expert/questions`
- `POST /expert/answer`

### 🛠️ Admin
- `GET /admin/dashboard`
- `GET /admin/experts/pending`
- `POST /admin/experts/approve/{id}`

---

## 🌱 Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection | `postgresql+asyncpg://user:pass@localhost:5432/crop_diagnosis` |
| `JWT_SECRET_KEY` | JWT secret key | `your-secret-key` |
| `ALLOWED_ORIGINS` | CORS origins | `http://localhost:3000` |
| `DEBUG` | Debug mode | `true` |

---

## 🤖 ML Model
The system currently uses a mock ML model.

To integrate a real model:

1. Train a PyTorch model on a crop disease dataset
2. Update `backend/app/services/ml_service.py`
3. Replace the `predict()` method with real inference logic

---

## 📱 App Screens
- **Auth**: Splash, Login, Register
- **Farmer**: Home, Diagnosis, Results, History, Ask Expert
- **Expert**: Dashboard, Questions, Answer
- **Common**: Profile

---

## 📄 License
This project is intended for academic and research purposes.
