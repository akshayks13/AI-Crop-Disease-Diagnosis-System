# Testing Documentation

## Overview

This document outlines the complete testing strategy for the AI Crop Disease Diagnosis System, covering all testing tools, test cases, and expected outputs.

**Total Tests: 156**
- Backend (pytest): 58 tests
- Flutter: 54 tests
- Admin Dashboard (Vitest): 22 tests
- E2E (Playwright): 22 tests

---

## Testing Tools

| Component | Testing Framework | Language | Runner Command |
|-----------|------------------|----------|----------------|
| Backend | **pytest** + pytest-asyncio | Python 3.11 | `pytest` |
| Flutter App | **Flutter Test** | Dart | `flutter test` |
| Admin Dashboard | **Vitest** | TypeScript | `npm test` |
| E2E (Admin) | **Playwright** | TypeScript | `npx playwright test` |

### Tool Versions

```
# Backend
pytest==7.4.4
pytest-asyncio==0.23.3
httpx==0.27.0 (async HTTP client for testing)

# Flutter
flutter_test (built-in)
flutter_lints 5.0.0

# Admin Dashboard
vitest==4.0.18

# E2E
@playwright/test==1.41.0
```

---

## Backend Tests (pytest)

### Test Files Overview

| Test File | Tests | Description |
|-----------|-------|-------------|
| `test_auth.py` | 7 | Authentication & authorization |
| `test_diagnosis.py` | 3 | Diagnosis history & pagination |
| `test_questions.py` | 6 | Q&A system for farmers |
| `test_community.py` | 6 | Community posts & comments |
| `test_farm.py` | 5 | Farm crops & tasks |
| `test_market.py` | 4 | Market prices |
| `test_encyclopedia.py` | 5 | Crop & disease encyclopedia |
| `test_expert.py` | 9 | Expert functionality |
| `test_admin.py` | 9 | Admin dashboard & management |
| `test_agronomy.py` | 4 | Agronomy knowledge base |
| **Total** | **58** | |

---

### test_auth.py - Authentication Tests

| Test Case | Expected Output | Status Code |
|-----------|----------------|-------------|
| `test_register_farmer` | User created, returns user ID | 201 |
| `test_register_duplicate_email` | Error: email exists | 400 |
| `test_login_valid` | Returns access_token, refresh_token | 200 |
| `test_login_invalid_password` | Error: invalid credentials | 401 |
| `test_login_unverified_user` | Error: email not verified | 401 |
| `test_get_current_user` | Returns user profile | 200 |
| `test_password_reset_flow` | Reset token sent | 200 |

---

### test_diagnosis.py - Diagnosis Tests

| Test Case | Expected Output | Status Code |
|-----------|----------------|-------------|
| `test_diagnosis_history_empty` | `{"diagnoses": [], "total": 0}` | 200 |
| `test_diagnosis_history_pagination` | Paginated results with `page`, `total` | 200 |
| `test_diagnosis_unauthorized` | Error: authentication required | 401 |

---

### test_questions.py - Q&A System Tests

| Test Case | Expected Output | Status Code |
|-----------|----------------|-------------|
| `test_create_question` | Question created with ID | 201 |
| `test_get_my_questions` | List of farmer's questions | 200 |
| `test_question_with_media` | Question with media_path | 201 |
| `test_question_detail` | Full question with answers | 200 |
| `test_close_question` | Status changed to CLOSED | 200 |
| `test_rate_answer` | Rating saved (1-5) | 200 |

---

### test_community.py - Community Tests

| Test Case | Expected Output | Status Code |
|-----------|----------------|-------------|
| `test_create_post` | Post created with ID | 201 |
| `test_get_community_posts` | Paginated posts list | 200 |
| `test_like_post` | likes_count incremented | 200 |
| `test_add_comment` | Comment added to post | 201 |
| `test_get_post_comments` | List of comments | 200 |
| `test_delete_own_post` | Post deleted | 204 |

---

### test_farm.py - Farm Management Tests

| Test Case | Expected Output | Status Code |
|-----------|----------------|-------------|
| `test_add_farm_crop` | Crop added with ID | 201 |
| `test_get_farm_crops` | List of user's crops | 200 |
| `test_add_farm_task` | Task created | 201 |
| `test_complete_task` | Status = COMPLETED | 200 |
| `test_delete_crop` | Crop deleted | 204 |

---

### test_market.py - Market Price Tests

| Test Case | Expected Output | Status Code |
|-----------|----------------|-------------|
| `test_get_market_prices` | List of crop prices | 200 |
| `test_filter_by_crop` | Filtered prices | 200 |
| `test_filter_by_region` | Region-specific prices | 200 |
| `test_price_trends` | Trend data (UP/DOWN/STABLE) | 200 |

---

### test_encyclopedia.py - Encyclopedia Tests

| Test Case | Expected Output | Status Code |
|-----------|----------------|-------------|
| `test_list_crops` | List of crops with info | 200 |
| `test_get_crop_detail` | Full crop information | 200 |
| `test_list_diseases` | List of diseases | 200 |
| `test_get_disease_detail` | Disease info + treatments | 200 |
| `test_search_encyclopedia` | Search results | 200 |

---

### test_expert.py - Expert Functionality Tests

| Test Case | Expected Output | Status Code |
|-----------|----------------|-------------|
| `test_get_expert_status` | Expert profile with `is_approved` | 200 |
| `test_get_expert_stats` | `total_answers`, `average_rating` | 200 |
| `test_get_open_questions` | List of OPEN questions | 200 |
| `test_expert_submit_answer` | Answer created with ID | 201 |
| `test_expert_cannot_answer_twice` | Error: already answered | 409 |
| `test_farmer_cannot_access_expert_questions` | Error: forbidden | 403 |
| `test_get_my_answers` | List of expert's answers | 200 |
| `test_update_expert_profile` | Profile updated | 200 |
| `test_get_trending_diseases` | Trending disease list | 200 |

---

### test_admin.py - Admin Dashboard Tests

| Test Case | Expected Output | Status Code |
|-----------|----------------|-------------|
| `test_admin_dashboard` | `{metrics: {total_users, ...}, trends: {...}}` | 200 |
| `test_admin_get_pending_experts` | List of pending experts | 200 |
| `test_admin_approve_expert` | Expert status = ACTIVE | 200 |
| `test_admin_get_users` | Paginated user list | 200 |
| `test_admin_get_system_logs` | System logs list | 200 |
| `test_admin_get_diagnoses` | All diagnoses (admin view) | 200 |
| `test_admin_get_questions` | All questions (admin view) | 200 |
| `test_farmer_cannot_access_admin_dashboard` | Error: forbidden | 403 |
| `test_admin_daily_metrics` | Daily metrics for charts | 200 |

---

### test_agronomy.py - Agronomy Knowledge Base Tests

| Test Case | Expected Output | Status Code |
|-----------|----------------|-------------|
| `test_list_diagnostic_rules` | `{rules: [...]}` | 200 |
| `test_list_treatment_constraints` | `{constraints: [...]}` | 200 |
| `test_list_seasonal_patterns` | `{patterns: [...]}` | 200 |
| `test_unauthenticated_cannot_access_agronomy` | Error: unauthorized | 401 |

---

## Flutter Tests (flutter_test)

### Test Files Overview

| Test File | Tests | Description |
|-----------|-------|-------------|
| `test/unit_test.dart` | 17 | Core validation & utilities |
| `test/widget_test.dart` | 0 | Widget rendering (placeholder) |
| `test/core/services/api_client_test.dart` | 37 | API configuration tests |
| **Total** | **54** | |

---

### unit_test.dart - Validation Tests

| Test Group | Test Case | Expected Output |
|------------|-----------|-----------------|
| **App Initialization** | app should initialize | `true` |
| **User Model** | user roles have correct values | `roles.length == 3` |
| **Validation** | email validation works | valid: `true`, invalid: `false` |
| **Validation** | password minimum length | `>= 6 characters` |
| **Validation** | phone number validation | `>= 10 digits` |
| **Question Status** | statuses are correct | `OPEN, ANSWERED, CLOSED` |
| **Farm Management** | growth stages ordered | `GERMINATION → HARVEST` |
| **Farm Management** | task priorities exist | `LOW, MEDIUM, HIGH` |
| **Market** | trend types correct | `UP, DOWN, STABLE` |

---

### api_client_test.dart - API Configuration Tests

| Test Group | Test Case | Expected Output |
|------------|-----------|-----------------|
| **Base URL** | properly formatted HTTP URL | starts with `http` |
| **Base URL** | points to localhost in dev | contains `localhost` |
| **Auth Endpoints** | login endpoint | `/auth/login` |
| **Auth Endpoints** | register endpoint | `/auth/register` |
| **Auth Endpoints** | verify endpoint | `/auth/verify` |
| **Auth Endpoints** | refresh endpoint | `/auth/refresh` |
| **Auth Endpoints** | me endpoint | `/auth/me` |
| **Auth Endpoints** | updateProfile endpoint | `/auth/profile` |
| **Auth Endpoints** | forgotPassword endpoint | `/auth/forgot-password` |
| **Auth Endpoints** | resetPassword endpoint | `/auth/reset-password` |
| **Diagnosis Endpoints** | predict endpoint | `/diagnosis/predict` |
| **Diagnosis Endpoints** | history endpoint | `/diagnosis/history` |
| **Diagnosis Endpoints** | detail endpoint | `/diagnosis` |
| **Expert Endpoints** | status endpoint | `/expert/status` |
| **Expert Endpoints** | profile endpoint | `/expert/profile` |
| **Expert Endpoints** | questions endpoint | `/expert/questions` |
| **Expert Endpoints** | answer endpoint | `/expert/answer` |
| **Expert Endpoints** | stats endpoint | `/expert/stats` |
| **Expert Endpoints** | myAnswers endpoint | `/expert/my-answers` |
| **Other Endpoints** | marketPrices | `/market/prices` |
| **Other Endpoints** | communityPosts | `/community/posts` |
| **Other Endpoints** | farmCrops | `/farm/crops` |
| **Other Endpoints** | farmTasks | `/farm/tasks` |
| **Other Endpoints** | encyclopediaCrops | `/encyclopedia/crops` |
| **Other Endpoints** | encyclopediaDiseases | `/encyclopedia/diseases` |
| **Other Endpoints** | questions | `/questions` |
| **Timeouts** | connectTimeout | `30 seconds` |
| **Timeouts** | receiveTimeout | `60 seconds` |
| **Timeouts** | uploadTimeout | `120 seconds` |
| **URL Building** | full login URL | `http://localhost:8000/auth/login` |
| **URL Building** | full predict URL | `http://localhost:8000/diagnosis/predict` |

---

## Admin Dashboard Tests (Vitest)

### Test File: `src/__tests__/api.test.ts`

**Total Tests: 22**

| Test Group | Test Case | Expected Output |
|------------|-----------|-----------------|
| **API Configuration** | default localhost value | contains `localhost` |
| **API Configuration** | valid HTTP URL | starts with `http` |
| **API Configuration** | no trailing slash | ends with port number |
| **Admin Endpoints** | dashboard endpoint | `/admin/dashboard` |
| **Admin Endpoints** | pagination in pending experts | contains `page=` |
| **Admin Endpoints** | users query params | `page=1&role=EXPERT&search=john` |
| **Admin Endpoints** | logs level filter | `level=ERROR` |
| **Admin Endpoints** | diagnoses disease filter | `disease=Leaf` |
| **Admin Endpoints** | approve expert URL | `/admin/experts/approve/{id}` |
| **Admin Endpoints** | reject expert URL | `/admin/experts/reject/{id}` |
| **Admin Endpoints** | suspend user URL | `/admin/users/{id}/suspend` |
| **Admin Endpoints** | activate user URL | `/admin/users/{id}/activate` |
| **Agronomy Endpoints** | diagnostic rules | `/agronomy/admin/rules` |
| **Agronomy Endpoints** | rules with disease filter | `disease_id=123-456` |
| **Agronomy Endpoints** | treatment constraints | `/agronomy/admin/constraints` |
| **Agronomy Endpoints** | patterns multi-filter | `crop_id=X&disease_id=Y` |
| **Agronomy Endpoints** | delete rule URL | `/agronomy/admin/rules/{id}` |
| **Auth Endpoints** | login endpoint | `/auth/login` |
| **Auth Endpoints** | me endpoint | `/auth/me` |
| **URL Helpers** | encode special chars | `test+user` |
| **URL Helpers** | skip empty params | `page=1` only |
| **URL Helpers** | multiple same-key params | `['urgent', 'reviewed']` |

---

## E2E Tests (Playwright)

### Overview
End-to-end tests simulate real user journeys through the Admin Dashboard in a headless Chromium browser. They run against the full stack (Next.js frontend + FastAPI backend).

### Test Files Overview

| Test File | Tests | Description |
|-----------|-------|-------------|
| `e2e/auth.spec.ts` | 4 | Login, logout, invalid credentials, session persistence |
| `e2e/dashboard.spec.ts` | 4 | Metrics cards, charts, daily stats load |
| `e2e/users.spec.ts` | 5 | User list, role filter, suspend/activate actions |
| `e2e/experts.spec.ts` | 5 | Pending expert list, approve/reject workflow |
| `e2e/diagnoses.spec.ts` | 4 | Diagnosis list, pagination, disease filter |
| **Total** | **22** | |

---

### auth.spec.ts — Authentication E2E

| Test Case | Expected Behaviour |
|-----------|-------------------|
| `login with valid admin credentials` | Redirects to `/dashboard` |
| `login with invalid password` | Shows error toast |
| `logout clears session` | Redirects to `/login` |
| `session persists on page reload` | Stays on `/dashboard` |

---

### dashboard.spec.ts — Dashboard E2E

| Test Case | Expected Behaviour |
|-----------|-------------------|
| `metrics cards render` | Total Users, Diagnoses, Questions visible |
| `daily stats chart loads` | Recharts SVG present on page |
| `pending experts count shown` | Badge visible in sidebar |
| `recent activity list renders` | At least one activity row |

---

### users.spec.ts — User Management E2E

| Test Case | Expected Behaviour |
|-----------|-------------------|
| `user list loads with pagination` | Table rows + page controls visible |
| `filter by EXPERT role` | Only expert rows shown |
| `suspend user` | Row status badge changes to SUSPENDED |
| `activate user` | Row status badge changes to ACTIVE |
| `search by name` | Filtered results match search term |

---

### experts.spec.ts — Expert Approval E2E

| Test Case | Expected Behaviour |
|-----------|-------------------|
| `pending experts list loads` | Shows experts with PENDING status |
| `approve expert` | Status changes to ACTIVE, row disappears from pending list |
| `reject expert` | Status changes to REJECTED |
| `approved expert visible in users list` | Appears in main users table |
| `expert stats visible after approval` | `total_answers` shows 0 |

---

### diagnoses.spec.ts — Diagnosis History E2E

| Test Case | Expected Behaviour |
|-----------|-------------------|
| `diagnosis list renders` | Table with disease, crop, confidence columns |
| `pagination controls work` | Clicking next page loads new rows |
| `disease name filter` | Results contain matching disease |
| `diagnosis detail opens` | Side panel or modal shows full record |

---

### Running E2E Tests

```bash
cd frontend/admin_dashboard

# First-time setup
npx playwright install chromium

# Run all E2E tests (headless)
npx playwright test

# Run in headed mode (see browser)
npx playwright test --headed

# Interactive UI mode
npx playwright test --ui

# Run a specific spec
npx playwright test e2e/auth.spec.ts

# View HTML report after a run
npx playwright show-report
```

**Expected Output:**
```
Running 22 tests using 4 workers

  22 passed (18s)
```

---

## Running Tests

### Backend

```bash
cd backend
source venv/bin/activate

# Run all tests
pytest

# Run with verbose output
pytest -v

# Run specific test file
pytest tests/test_auth.py

# Run specific test
pytest tests/test_auth.py::test_login_valid

# Run with coverage report
pytest --cov=app --cov-report=html

# Run only async tests
pytest -m asyncio

# Redis vs PostgreSQL latency benchmark (requires Redis running)
venv/bin/python tests/test_redis_latency.py
```

**Expected Output:**
```
=================== 58 passed, 25 warnings in 25.12s ===================
```

### Flutter

```bash
cd frontend/flutter_app

# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/core/services/api_client_test.dart

# Verbose output
flutter test --reporter expanded
```

**Expected Output:**
```
00:02 +54: All tests passed!
```

### Admin Dashboard

```bash
cd frontend/admin_dashboard

# Run all tests
npm test

# Run in watch mode
npm run test:watch
```

**Expected Output:**
```
 ✓ src/__tests__/api.test.ts (22 tests) 3ms
   ✓ API Configuration (3)
   ✓ Admin API Endpoints (9)
   ✓ Agronomy API Endpoints (5)
   ✓ Auth API Endpoints (2)
   ✓ URL Parameter Helpers (3)

 Test Files  1 passed (1)
      Tests  22 passed (22)
   Duration  167ms
```

---

## CI/CD Integration

Tests run automatically on every push via GitHub Actions (`.github/workflows/ci.yml`):

```yaml
jobs:
  backend:
    name: Backend (Python)
    steps:
      - pip install -r requirements.txt
      - ruff check .                    # Lint
      - pytest -v --tb=short            # Tests

  flutter:
    name: Flutter App
    steps:
      - flutter pub get
      - flutter analyze                 # Lint
      - flutter test                    # Tests

  admin:
    name: Admin Dashboard (Next.js)
    steps:
      - npm ci
      - npm run lint                    # Lint
      - npm test                        # Tests (Vitest)
      - npm run build                   # Build

  e2e:
    name: E2E Tests (Playwright)
    steps:
      - npm ci
      - npx playwright install --with-deps chromium
      - npx playwright test             # E2E tests
```

---

## Test Database Setup

Backend tests require PostgreSQL:

```bash
# Create test database
createdb crop_diagnosis_test

# Set environment variable
export DATABASE_URL="postgresql+asyncpg://user:pass@localhost:5432/crop_diagnosis_test"
```

### Test Fixtures (conftest.py)

| Fixture | Description |
|---------|-------------|
| `test_db` | Fresh database session per test |
| `test_user` | Farmer user for auth tests |
| `test_expert` | Approved expert user |
| `admin_user` | Admin user for admin tests |
| `client` | Unauthenticated HTTP client |
| `auth_client` | Authenticated farmer client |
| `expert_client` | Authenticated expert client |
| `admin_client` | Authenticated admin client |

---

## Adding New Tests

### Backend Example

```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_new_feature(auth_client: AsyncClient):
    """Test description."""
    response = await auth_client.post("/endpoint", json={"key": "value"})
    
    assert response.status_code == 200
    data = response.json()
    assert "expected_field" in data
```

### Flutter Example

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature Tests', () {
    test('should do something', () {
      // Arrange
      final input = 'test';
      
      // Act
      final result = processInput(input);
      
      // Assert
      expect(result, equals('expected'));
    });
  });
}
```

### Admin Dashboard Example (Vitest)

```typescript
import { describe, it, expect } from 'vitest';

describe('Feature Tests', () => {
  it('should do something', () => {
    const input = 'test';
    const result = processInput(input);
    expect(result).toBe('expected');
  });
});
```
