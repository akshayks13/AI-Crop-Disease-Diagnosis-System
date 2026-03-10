# Security Documentation

## Overview

This document outlines the security measures implemented in the AI Crop Disease Diagnosis System.

---

## Authentication

### JWT (JSON Web Tokens)

The application uses JWT for stateless authentication:

| Token Type | Lifetime | Purpose |
|------------|----------|---------|
| Access Token | 30 minutes | API authentication |
| Refresh Token | 7 days | Obtaining new access tokens |

```python
# JWT Configuration
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7
```

### Password Security

- Passwords are hashed using **bcrypt** with auto-generated salts
- Minimum password length: 8 characters
- Passwords are never stored in plain text

```python
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)
```

### OTP Verification

- 6-digit OTP sent via email during registration
- OTP expires after 10 minutes
- Rate limiting prevents brute force attempts

---

## Authorization (RBAC)

Role-Based Access Control with three roles:

| Role | Permissions |
|------|-------------|
| **FARMER** | Create diagnoses, ask questions, community access, farm management |
| **EXPERT** | Answer questions, manage knowledge base, view stats |
| **ADMIN** | Full access: user management, system logs, all CRUD operations |

### Permission Enforcement

```python
# Endpoint protection
@router.post("/agronomy/diagnostic-rules")
async def create_rule(
    data: RuleCreate,
    user: User = Depends(require_admin_or_expert)  # Role check
):
    ...
```

### Access Control Matrix

| Resource | FARMER | EXPERT | ADMIN |
|----------|--------|--------|-------|
| Diagnoses (own) | CRUD | R | CRUD |
| Questions | CR | RU | CRUD |
| Answers | R | CRU | CRUD |
| Community | CRUD | CRUD | CRUD |
| Agronomy Rules | R | CRUD | CRUD |
| Users | - | - | RUD |
| System Logs | - | - | R |

---

## Data Protection

### Database Security

- **Prepared statements**: All queries use parameterized queries (SQLAlchemy ORM)
- **No SQL injection**: ORM prevents direct SQL string concatenation
- **Encryption at rest**: Database encryption should be enabled in production

### API Security

- **HTTPS only**: All production traffic must use TLS/SSL
- **CORS**: Configured to allow only trusted origins
- **Rate limiting**: Prevents abuse of public endpoints

```python
# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://ai-crop-disease-diagnosis-system.vercel.app",
        "https://ai-crop-disease-7c811.web.app",
    ],
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)
```

### Input Validation

- **Pydantic schemas**: All inputs validated before processing
- **File validation**: Upload size and type restrictions
- **UUID validation**: Proper UUID format enforcement

---

## Secure Headers

Recommended security headers (configure in Nginx/reverse proxy):

```nginx
# Security Headers
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "DENY" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Content-Security-Policy "default-src 'self'" always;
```

---

## Secrets Management

### Environment Variables

Never commit secrets to version control. Use environment variables:

```bash
# .env (not in git)
JWT_SECRET=super_secret_random_string_32_chars_long
DATABASE_URL=postgresql://user:password@host:5432/db
```

### Required Secrets

| Secret | Description | Rotation |
|--------|-------------|----------|
| `JWT_SECRET` | Token signing key | Quarterly |
| `DATABASE_URL` | DB connection string | On credential change |
| `SMTP_PASSWORD` | Email service auth | Annually |

---

## Vulnerability Reporting

If you discover a security vulnerability:

1. **Do NOT** open a public issue
2. Email security@cropdiag.example.com with details
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We aim to respond within 48 hours and will coordinate disclosure.

---
