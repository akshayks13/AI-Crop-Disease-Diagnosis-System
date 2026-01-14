# AI-Based Crop Disease Diagnosis System

An AI-powered agricultural solution that helps farmers diagnose crop diseases using image analysis and provides treatment recommendations with expert consultation.

## 🌾 Features

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

## 🛠 Tech Stack

| Component | Technology |
|-----------|------------|
| Mobile App | Flutter + Riverpod |
| Admin Dashboard | Next.js + TypeScript |
| Backend API | FastAPI + SQLAlchemy |
| Database | PostgreSQL |
| ML Pipeline | PyTorch + OpenCV |
| Auth | JWT + RBAC |

## 📁 Project Structure

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

## 🚀 Quick Start

### Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up database
psql -U postgres -f ../database/init.sql

# Run server
uvicorn app.main:app --reload
```

API docs available at: http://localhost:8000/docs

### Flutter App

```bash
cd frontend/flutter_app

# Get dependencies
flutter pub get

# Run app
flutter run
```

### Admin Dashboard

```bash
cd frontend/admin_dashboard

# Install dependencies
npm install

# Run dev server
npm run dev
```

Dashboard available at: http://localhost:3000

## 🔐 Default Credentials

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@cropdiagnosis.com | admin123 |

> ⚠️ Change these credentials in production!

## 📡 API Endpoints

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

## 🤖 ML Model

The system uses a simulated ML model for development. To integrate a real model:

1. Train a PyTorch model on crop disease dataset
2. Update `backend/app/services/ml_service.py`
3. Replace the `predict()` method with actual inference

## 📱 App Screens

- **Auth**: Splash, Login, Register
- **Farmer**: Home, Diagnosis, Results, History, Ask Expert
- **Expert**: Dashboard, Questions, Answer
- **Common**: Profile

## 📄 License

MIT License
