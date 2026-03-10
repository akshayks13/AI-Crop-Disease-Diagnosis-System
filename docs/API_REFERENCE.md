# API Reference

## Base URL

- **Development**: `http://localhost:8000`
- **Production**: `https://api.cropdiag.example.com`

## Authentication

All protected endpoints require a JWT token in the `Authorization` header:

```
Authorization: Bearer <access_token>
```

## Rate Limiting

All endpoints are rate-limited to **60 requests per minute per IP address**.

```json
// Response 429 — Too Many Requests
{ "detail": "Rate limit exceeded: 60 per 1 minute" }
```

---

## Auth Endpoints

### Register

`POST /auth/register`

```json
// Request
{
  "email": "farmer@example.com",
  "password": "securepassword",
  "full_name": "John Doe",
  "phone": "+919876543210",
  "role": "FARMER"  // FARMER | EXPERT
}

// Response 201
{
  "message": "OTP sent to email"
}
```

### Verify OTP

`POST /auth/verify`

```json
// Request
{ "email": "farmer@example.com", "otp": "123456" }

// Response 200
{ "message": "Email verified" }
```

### Login

`POST /auth/login`

```json
// Request
{ "email": "farmer@example.com", "password": "securepassword" }

// Response 200
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer",
  "user": { "id": "uuid", "email": "...", "role": "FARMER" }
}
```

### Refresh Token

`POST /auth/refresh`

```json
// Request
{ "refresh_token": "eyJ..." }

// Response 200
{ "access_token": "eyJ..." }
```

### OAuth2 Token (Swagger UI)

`POST /auth/token` (form-data: `username` + `password`)

> Used by Swagger UI's Authorize button. Enter your email as username.

```json
// Response 200
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer"
}
```

---

## Diagnosis Endpoints

### Create Diagnosis (Image Upload)

`POST /diagnosis/predict` (multipart/form-data)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | File | Yes | JPEG/PNG/WebP crop image |
| `crop_type` | string | No | Crop name |
| `location` | string | No | Text location |
| `latitude` | float | No | GPS latitude for disease map |
| `longitude` | float | No | GPS longitude for disease map |

```json
// Response 200
{
  "id": "uuid",
  "disease": "Apple Scab",
  "disease_id": "apple_apple_scab",
  "confidence": 0.92,
  "severity": "moderate",
  "crop_type": "Apple",
  "treatment_steps": [...],
  "chemical_options": [...],
  "organic_options": [...],
  "warnings": "...",
  "prevention": "...",
  "dss_advisory": null,
  "created_at": "2026-03-09T10:00:00"
}
```

### Save DSS Advisory to Diagnosis

`POST /diagnosis/{id}/save-advisory`

> Stores a DSS advisory snapshot and GPS coordinates into an existing diagnosis record.

```json
// Request body
{
  "disease_id": "apple_apple_scab",
  "disease": "Apple Scab",
  "confidence": 0.92,
  "severity": "moderate",
  "plant": "Apple",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "dss_advisory": {
    "risk_score": 7.5,
    "risk_level": "High",
    "treatment_options": [...],
    "irrigation_advice": "...",
    "crop_rotation_advice": "..."
  }
}

// Response 200
{ "status": "ok", "updated_fields": ["disease_id", "dss_advisory", "latitude", "longitude"] }
```

### Get DSS Advisory

`POST /diagnosis/dss-advisory`

> Accepts a disease label (e.g. from the server's ML response) and optional weather/farmer inputs, returns risk-scored advisory from the DSS engine.

```json
// Request body
{
  "disease_label": "apple_apple_scab",
  "temperature": 28,
  "humidity": 75,
  "irrigation": "Moderate",
  "waterlogged": false,
  "fertilizer_recent": false,
  "first_cycle": false
}

// Response 200
{
  "crop": "apple",
  "disease": "apple_scab",
  "season": "Rabi",
  "disease_type": "Fungal",
  "risk_score": 7.5,
  "risk_level": "High",
  "risk_justification": "High humidity (75%) increases fungal spread risk.",
  "treatment_options": ["Mancozeb 75% WP", "Captan 50% WP"],
  "irrigation_advice": "Avoid overhead irrigation to reduce leaf wetness.",
  "crop_rotation_advice": "Rotate with non-host crops for 1-2 seasons."
}
```

### Get Diagnosis History

`GET /diagnosis/history?page=1&page_size=20`

```json
// Response 200
{
  "diagnoses": [...],
  "total": 25,
  "page": 1
}
```

### Get Disease Outbreak Map Data

`GET /diagnosis/disease-map?days=30&disease=Leaf%20Blight`

> Returns geo-tagged diagnoses for the interactive outbreak map. **No authentication required.**

| Query Param | Type | Default | Description |
|-------------|------|---------|-------------|
| `days` | int | 30 | Lookback window in days |
| `disease` | string | — | Optional filter by disease name (case-insensitive) |

```json
// Response 200
{
  "outbreaks": [
    {
      "disease": "Leaf Blight",
      "severity": "severe",
      "latitude": 12.9716,
      "longitude": 77.5946,
      "crop_type": "Tomato",
      "date": "2026-03-09T10:00:00"
    }
  ],
  "total": 42,
  "diseases": ["Leaf Blight", "Apple Scab", "Early Blight"],
  "days": 30
}
```

### Rate Diagnosis

`POST /diagnosis/{id}/rate?rating=5`

```json
// Response 200
{ "message": "Rating submitted", "rating": 5 }
```

---

## Expert Endpoints

**Auth**: Expert role required

### Get Open Questions

`GET /expert/questions?status=OPEN`

### Answer Question

`POST /expert/answer`

```json
// Request
{ "question_id": "uuid", "answer_text": "Your answer here" }
```

### Expert Dashboard

`GET /expert/dashboard`

---

## Agronomy Endpoints

**Auth**: Expert or Admin required for write operations

### Diagnostic Rules

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/agronomy/diagnostic-rules` | List all rules |
| POST | `/agronomy/diagnostic-rules` | Create rule |
| PUT | `/agronomy/diagnostic-rules/{id}` | Update rule |
| DELETE | `/agronomy/diagnostic-rules/{id}` | Delete rule |

### Treatment Constraints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/agronomy/treatment-constraints` | List constraints |
| POST | `/agronomy/treatment-constraints` | Create constraint |
| PUT | `/agronomy/treatment-constraints/{id}` | Update |
| DELETE | `/agronomy/treatment-constraints/{id}` | Delete |

### Seasonal Patterns

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/agronomy/seasonal-patterns` | List patterns |
| POST | `/agronomy/seasonal-patterns` | Create pattern |
| PUT | `/agronomy/seasonal-patterns/{id}` | Update |
| DELETE | `/agronomy/seasonal-patterns/{id}` | Delete |

---

## Community Endpoints

### Posts

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/community/posts` | List posts |
| POST | `/community/posts` | Create post |
| GET | `/community/posts/{id}` | Get post details |
| POST | `/community/posts/{id}/like` | Toggle like |
| POST | `/community/posts/{id}/comments` | Add comment |
| GET | `/community/posts/{id}/comments` | Get comments |

---

## Farm Management Endpoints

**Auth**: Any authenticated user

### Crops

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/farm/crops` | List user's crops (auto-calculated progress) |
| POST | `/farm/crops` | Add a new crop |
| GET | `/farm/crops/{id}` | Get crop details |
| PUT | `/farm/crops/{id}` | Update crop |
| DELETE | `/farm/crops/{id}` | Delete crop |

```json
// POST /farm/crops
{
  "name": "Tomato Field A",
  "crop_type": "tomato",
  "field_name": "North Plot",
  "area_size": 2.5,
  "area_unit": "acres",
  "sow_date": "2026-01-15",
  "expected_harvest_date": "2026-05-15"
}
```

### Tasks

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/farm/tasks` | List user's tasks |
| POST | `/farm/tasks` | Create a task |
| PUT | `/farm/tasks/{id}/complete` | Toggle task completion |
| DELETE | `/farm/tasks/{id}` | Delete task |

---

## Market Price Endpoints

**Auth**: Any authenticated user

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/market/prices` | List commodity prices |
| GET | `/market/prices?commodity=Tomato` | Filter by commodity |
| GET | `/market/prices?location=Bengaluru` | Filter by location (city/district) |
| GET | `/market/prices?trend=up` | Filter by price trend |

> **Location-based filtering**: The Flutter app auto-detects the user's GPS location and passes the nearest city/district as the `location` query parameter. The backend filters both live Agmarknet API data and the database fallback using this parameter.

```json
// Response 200
{
  "prices": [
    {
      "commodity": "Tomato",
      "price": 45.0,
      "unit": "Quintal",
      "location": "Bengaluru, Bangalore Urban, Karnataka",
      "trend": "up",
      "change_percent": 5.2,
      "min_price": 40.0,
      "max_price": 50.0
    }
  ],
  "total": 25,
  "page": 1
}
```

---

## Encyclopedia Endpoints

### Crops

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/encyclopedia/crops` | List crops (supports `?search=`, `?season=`) |
| GET | `/encyclopedia/crops/{id}` | Get crop details |
| POST | `/encyclopedia/crops` | Create crop entry (admin only) |

### Diseases

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/encyclopedia/diseases` | List diseases (supports `?search=`, `?severity=`) |
| GET | `/encyclopedia/diseases/{id}` | Get disease details |
| POST | `/encyclopedia/diseases` | Create disease entry (admin only) |

### Pests _(new)_

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/encyclopedia/pests` | List pests (supports `?search=`, `?severity=`, `?crop=`) |
| GET | `/encyclopedia/pests/{id}` | Get pest details |
| POST | `/encyclopedia/pests` | Create pest entry (admin only) |

```json
// GET /encyclopedia/pests response
{
  "pests": [
    {
      "id": "uuid",
      "name": "Aphids",
      "scientific_name": "Aphidoidea",
      "affected_crops": ["Wheat", "Cotton", "Vegetables"],
      "damage_type": "Sucking",
      "severity_level": "moderate",
      "symptoms": ["Curling leaves", "Sticky honeydew"],
      "control_methods": [...],
      "organic_control": [...],
      "chemical_control": [...]
    }
  ],
  "total": 8
}
```

---

## Admin Endpoints

**Auth**: Admin role required

### Dashboard Stats

`GET /admin/dashboard`

### User Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/admin/users` | List users |
| PUT | `/admin/users/{id}/approve` | Approve expert |
| PUT | `/admin/users/{id}/suspend` | Suspend user |

### System Logs

`GET /admin/logs?level=ERROR&page=1`

---

## Error Responses

All errors follow this format:

```json
{
  "detail": "Error message here"
}
```

| Status | Description |
|--------|-------------|
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Missing or invalid token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource doesn't exist |
| 422 | Validation Error - Invalid data format |
| 429 | Too Many Requests - Rate limit exceeded (60/min per IP) |
| 500 | Server Error - Internal error |
