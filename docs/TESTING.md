# Testing Documentation

## Overview

This document outlines the testing strategy for the AI Crop Disease Diagnosis System, covering unit tests, integration tests, and end-to-end testing.

---

## Test Inventory

### Backend Tests (pytest)

| Test File | Coverage |
|-----------|----------|
| `test_auth.py` | Registration, login, password reset |
| `test_diagnosis.py` | Diagnosis history, pagination, auth |
| `test_questions.py` | Question CRUD, farmer flows |
| `test_community.py` | Community posts, comments |
| `test_farm.py` | Farm crops, tasks |
| `test_market.py` | Market prices |
| `test_encyclopedia.py` | Encyclopedia CRUD |
| `test_expert.py` | Expert status, stats, answer submission |
| `test_admin.py` | Admin dashboard, user management, expert approval |
| `test_agronomy.py` | Agronomy knowledge base endpoints |
| `manual_test_agronomy.py` | Manual agronomy testing script |

### Flutter Tests

| Test File | Coverage | Tests |
|-----------|----------|-------|
| `unit_test.dart` | Unit tests for utilities | 17 |
| `widget_test.dart` | Widget rendering tests | 0 |
| `test/core/services/api_client_test.dart` | ApiConfig endpoints, timeouts, URL building | 37 |

---

## Running Tests

### Backend (pytest)

```bash
cd backend

# Activate virtual environment
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate      # Windows

# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_auth.py

# Run with verbose output
pytest -v

# Run only tests matching a pattern
pytest -k "test_login"

# Run async tests only
pytest -m asyncio
```

### Flutter Tests

```bash
cd frontend/flutter_app

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit_test.dart

# Run with verbose output
flutter test --reporter expanded
```

### Admin Dashboard (Next.js)

```bash
cd frontend/admin_dashboard

# Run linter
npm run lint

# Run type checking
npx tsc --noEmit
```

---

## Test Configuration

### Backend Fixtures (conftest.py)

```python
@pytest_asyncio.fixture
async def test_db():
    """Create test database session with PostgreSQL."""
    # Creates fresh schema, yields session, drops all tables

@pytest_asyncio.fixture
async def test_user(test_db):
    """Create a test farmer user."""
    
@pytest_asyncio.fixture
async def test_expert(test_db):
    """Create a test expert user."""
    
@pytest_asyncio.fixture
async def auth_token(test_user):
    """Generate JWT auth token for test user."""
    
@pytest_asyncio.fixture
async def client(test_db):
    """Create test client with overridden DB dependency."""
    
@pytest_asyncio.fixture
async def auth_client(client, auth_token):
    """Create authenticated test client with headers set."""
```

### Database Requirements

Tests require PostgreSQL due to PostgreSQL-specific UUID types:

```bash
# Set environment variable
export DATABASE_URL="postgresql+asyncpg://user@localhost:5432/crop_diagnosis_test"

# Or create test database
createdb crop_diagnosis_test
```

---

## Test Structure

```
backend/tests/
├── conftest.py              # Fixtures (test DB, client, users)
├── test_auth.py             # Authentication tests
├── test_diagnosis.py        # Diagnosis endpoint tests
├── test_questions.py        # Q&A system tests
├── test_community.py        # Community feature tests
├── test_encyclopedia.py     # Encyclopedia CRUD tests
├── test_farm.py             # Farm management tests
├── test_market.py           # Market price tests
├── test_agronomy_mock.py    # Agronomy CRUD tests
└── manual_test_agronomy.py  # Manual testing script

frontend/flutter_app/test/
├── unit_test.dart           # Unit tests
├── widget_test.dart         # Widget tests
└── core/
    └── services/            # Service layer tests
```

---

## Writing Tests

### Backend Example

```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_create_diagnosis(auth_client: AsyncClient):
    """Test creating a new diagnosis."""
    response = await auth_client.post(
        "/diagnosis/predict",
        files={"image": ("test.jpg", b"fake_image_data", "image/jpeg")},
        data={"crop_type": "Tomato"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "disease" in data
    assert "confidence" in data
```

### Flutter Example

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Diagnosis Model', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': '123',
        'disease': 'Leaf Blight',
        'confidence': 0.95,
      };
      
      final diagnosis = Diagnosis.fromJson(json);
      
      expect(diagnosis.disease, 'Leaf Blight');
      expect(diagnosis.confidence, 0.95);
    });
  });
}
```

---

## CI/CD Integration

Tests run on every push via GitHub Actions:

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  backend:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: crop_diagnosis_test
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - run: pip install -r backend/requirements.txt
      - run: pip install pytest pytest-asyncio pytest-cov httpx
      - run: pytest backend/tests --cov=app
        env:
          DATABASE_URL: postgresql+asyncpg://postgres:postgres@localhost:5432/crop_diagnosis_test

  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test frontend/flutter_app
```

---

