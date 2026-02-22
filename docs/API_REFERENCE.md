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

### Create Diagnosis

`POST /diagnosis/predict` (multipart/form-data)

| Field | Type | Required |
|-------|------|----------|
| `image` | File | Yes |
| `crop_type` | string | Yes |
| `location` | string | No |
| `farmer_symptoms` | string | No — voice/text description of symptoms |

```json
// Response 200
{
  "id": "uuid",
  "disease_name": "Leaf Blight",
  "confidence": 0.92,
  "severity": "moderate",
  "symptoms": ["yellowing", "spots"],
  "treatment_plan": {
    "chemical": [...],
    "organic": [...]
  },
  "prevention_tips": [...]
}
```

### Get Diagnosis History

`GET /diagnosis/history?page=1&limit=10`

```json
// Response 200
{
  "diagnoses": [...],
  "total": 25,
  "page": 1
}
```

### Rate Diagnosis

`POST /diagnosis/{id}/rate`

```json
// Request
{ "rating": 5 }

// Response 200
{ "message": "Rating updated" }
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
