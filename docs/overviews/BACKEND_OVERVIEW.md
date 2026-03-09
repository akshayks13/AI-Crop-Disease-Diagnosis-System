# Backend Documentation

## 🏗️ Architecture Overview

The backend is built using **FastAPI**, a high-performance, modern Python web framework. It follows a modular, layered architecture to ensure scalability and maintainability.

### Key Technologies

| Technology | Version | Purpose | Why we use it? |
| :--- | :--- | :--- | :--- |
| **FastAPI** | Latest | Web Framework | Async native, auto-generated docs, 300% faster than Flask |
| **Uvicorn** | Latest | ASGI Server | Lightning-fast server for running FastAPI |
| **PostgreSQL** | 15 | Database | Robust relational DB with UUID and JSON support |
| **SQLAlchemy** | 2.0 (Async) | ORM | Type-safe Python objects instead of raw SQL |
| **Alembic** | Latest | DB Migrations | Version control for database schema |
| **Pydantic** | v2 | Data Validation | Ensures API request/response data is valid |
| **Python-Jose** | Latest | JWT Auth | Secure, stateless authentication |
| **Passlib** | Latest | Password Hashing | Bcrypt-based secure password storage |
| **slowapi** | Latest | Rate Limiting | 60 req/min per IP, prevents abuse |
| **loguru** | Latest | File Logging | Structured JSON logs with rotation (separate from admin DB logs) |
| **Ruff** | Latest | Linter | 100x faster than Flake8, all-in-one tooling |

---

## 📂 Project Structure

```
backend/
├── alembic/                # Database migration scripts
│   └── versions/           # Migration history
├── app/
│   ├── agronomy/           # Agronomy intelligence routes
│   ├── core/               # Core config (Security, Settings)
│   ├── db/                 # Database setup (Session, Base)
│   ├── models/             # SQLAlchemy Database Models
│   │   ├── encyclopedia.py # CropInfo, DiseaseInfo
│   │   ├── pest.py         # PestInfo (new)
│   │   └── ...
│   ├── routes/             # API Endpoints
│   ├── schemas/            # Pydantic Request/Response Schemas
│   ├── services/           # Business Logic Layer
│   ├── utils/
│   │   └── logger.py       # loguru structured file logger
│   ├── database.py         # DB connection & session management
│   └── main.py             # App Entry Point (rate limiting, middleware)
├── scripts/                # Operational scripts
│   ├── backup_db.sh        # Shell backup script (cron-ready)
│   ├── restore_db.sh       # DB restore from .sql.gz
│   └── backup_db.py        # Cross-platform Python backup script
├── logs/                   # Log files (gitignored)
│   ├── app.log             # All logs (JSON, rotating 10MB, 7-day retention)
│   └── errors.log          # Errors only (JSON, rotating 5MB, 30-day retention)
├── backups/                # DB backup dumps (gitignored)
├── tests/                  # Pytest test suite (59 tests)
├── requirements.txt        # Python dependencies
└── alembic.ini             # Alembic configuration
```

---

## 🧩 Key Components Explained

### 1. **Models (`app/models/`)**
Defines database tables using SQLAlchemy.
*   **Example**: `User`, `Diagnosis`, `Question`, `CommunityPost`
*   **Features**: UUID primary keys, relationships, JSON fields

### 2. **Schemas (`app/schemas/`)**
Defines API contracts using Pydantic.
*   **Example**: `UserCreate` validates email format and password strength
*   **Auto-generates**: OpenAPI documentation at `/docs`

### 3. **Routes (`app/routes/`)**
HTTP endpoint handlers.
*   **Flow**: Request → Rate Limiter → Pydantic Validation → Service → Response
*   **Files**: `auth.py`, `farmer.py`, `expert.py`, `admin.py`, `community.py`, `farm.py`, `market.py`, `encyclopedia.py`
*   **Encyclopedia** includes 3 resource types: Crops, Diseases, and **Pests** (new)

### 3.5 **Middleware (`app/middleware/`)**
Request/response processing.
*   **Logging Middleware**: Logs every API request with method, path, status code, and duration to `system_logs` table
*   **SlowAPI Rate Limiter**: 60 requests/minute per IP (returns 429 on exceed)

### 3.6 **Logging (`app/utils/logger.py`)**
Structured file logging using **loguru** (completely separate from admin DB logs):
*   `logs/app.log` — all logs, JSON format, 10 MB rotation, 7-day retention
*   `logs/errors.log` — errors only, 30-day retention
*   Used by global exception handler and middleware fallback

### 4. **Services (`app/services/`)**
Business logic layer.
*   **Why?**: Keeps routes thin and testable
*   **`DiagnosisService`**: Handles diagnosis history, pagination, and advisory storage
*   **`DSSService`**: CSV-based Decision Support System — parses disease label, computes risk score, returns advisory with treatment options and cultural advice
*   **`MLService`**: Thin wrapper for server-side image handling; on-device TFLite runs classification in Flutter
*   **`RedisService`**: Cache helper — admin dashboard (5 min TTL), encyclopedia (24 h), market prices (1 h), daily metrics (1 min)
*   **`AgmarknetService`** (via `market.py`): Fetches real-time mandi prices from OGD Platform API with Redis → in-memory → API → DB fallback chain and 429 rate-limit backoff

### 5. **Dependencies (`app/core/deps.py` or `app/api/deps.py`)**
Reusable dependency injection.
*   **Examples**: `get_db()`, `get_current_user()`, `require_admin()`

---

## 🚀 Request Lifecycle

1.  **Request**: Client sends `POST /auth/login {email, password}`
2.  **Uvicorn**: ASGI server receives HTTP request
3.  **FastAPI Router**: Matches route and extracts path/body
4.  **Pydantic**: Validates request schema
5.  **Dependency Injection**: Injects database session
6.  **Route Handler**: Calls `AuthService.authenticate()`
7.  **Service Layer**: Queries DB, verifies bcrypt hash
8.  **Response**: Returns JWT tokens + user object

---

## 🧪 Testing

**Framework**: Pytest with async support
**Total Tests**: 59 (across 10 test files)

### Running Tests
```bash
cd backend
source venv/bin/activate

# Run all tests
pytest

# Run with verbose output
pytest -v

# Run specific test file
pytest tests/test_auth.py

# Run with coverage
pytest --cov=app --cov-report=html
```

### Test Infrastructure
*   **Database**: Fresh PostgreSQL instance per test session
*   **Fixtures** (`conftest.py`): `test_db`, `client`, `test_user`, `auth_client`
*   **HTTP Client**: `httpx.AsyncClient` for async endpoint testing

### Test Categories
| Test File | Tests | Coverage |
|-----------|-------|----------|
| `test_auth.py` | 7 | Login, Register, OTP, Token Refresh |
| `test_diagnosis.py` | 3 | History, Pagination |
| `test_questions.py` | 6 | Create, Answer, Rate |
| `test_community.py` | 6 | Posts, Comments, Likes |
| `test_farm.py` | 5 | Crops, Tasks, Completion Toggle |
| `test_market.py` | 4 | Prices, Filters, Pagination |
| `test_encyclopedia.py` | 5 | Crops, Diseases, Search |
| `test_admin.py` | 9 | Dashboard, User Management |
| `test_expert.py` | 10 | Questions, Answers, Stats |
| `test_agronomy.py` | 4 | Rules, Constraints, Patterns |

---

## 🎨 Linting

**Tool**: Ruff (modern, Rust-based linter)

### Running Linter
```bash
cd backend

# Check for issues
ruff check .

# Auto-fix issues
ruff check . --fix

# Format code
ruff format .
```

### What Ruff Checks
*   PEP 8 compliance
*   Unused imports and variables
*   Code complexity
*   Type hints

**CI Integration**: Runs `ruff check .` on every push

---

## 🗄️ Database Migrations

**Tool**: Alembic

### Common Commands
```bash
# Create new migration
alembic revision --autogenerate -m "Add rating field"

# Apply migrations
alembic upgrade head

# Rollback one version
alembic downgrade -1

# View history
alembic history
```

---

## 🚀 Running the Backend

### Development
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --port 8000
```

### Production
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

### Environment Variables
Create `.env` in `backend/`:
```env
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/dbname
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

---

## 📚 API Documentation

FastAPI auto-generates interactive API docs:
*   **Swagger UI**: http://localhost:8000/docs
*   **ReDoc**: http://localhost:8000/redoc
