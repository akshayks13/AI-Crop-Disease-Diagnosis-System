# DevOps & Deployment Documentation

## Overview

This document covers infrastructure, deployment, monitoring, and operational procedures for the AI Crop Disease Diagnosis System.

---

## Architecture Overview

Current Development/Docker Environment:

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│   Flutter App   │       │ Admin Dashboard │       │   Backend API   │
│   (Web Server)  │       │    (Next.js)    │       │    (FastAPI)    │
│     Port 8080   │       │    Port 3000    │       │    Port 8000    │
└────────┬────────┘       └────────┬────────┘       └────────┬────────┘
         │                         │                         │
         │                         │                         │
         └─────────────────────────┼─────────────────────────┘
                                   │
                          ┌────────▼────────┐
                          │    PostgreSQL   │
                          │    Port 5432    │
                          └─────────────────┘
```

> **Note**: A Load Balancer (Nginx) is planned for the production environment to handle SSL termination and traffic distribution. It will be added in a future update.

---

## Docker Configuration

### docker-compose.yml

```yaml
version: '3.8'

services:
  # Postgres Database
  db:
    image: postgres:15-alpine
    container_name: crop_diagnosis_db
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=crop_diagnosis
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  # Backend Service (FastAPI)
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: crop_diagnosis_backend
    restart: always
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql+asyncpg://postgres:postgres@db:5432/crop_diagnosis
      - SECRET_KEY=your_secret_key_change_in_production
      - ALGORITHM=HS256
      - ACCESS_TOKEN_EXPIRE_MINUTES=30
    depends_on:
      - db
    volumes:
      - ./backend/uploads:/app/uploads # Persist uploads

  # Admin Dashboard (Next.js)
  admin_dashboard:
    build:
      context: ./frontend/admin_dashboard
      dockerfile: Dockerfile
    container_name: crop_diagnosis_admin
    restart: always
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
    depends_on:
      - backend

  # Flutter App (Web served by Nginx)
  flutter_web:
    build:
      context: ./frontend/flutter_app
      dockerfile: Dockerfile
    container_name: crop_diagnosis_flutter_web
    restart: always
    ports:
      - "8080:80"
    depends_on:
      - backend

volumes:
  postgres_data:
```

### Backend Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Expose port
EXPOSE 8000

# Run with Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Environment Setup

### Development

```bash
# Clone repository
git clone <repo-url>
cd SE_Proj

# Backend setup
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # Configure environment variables

# Run migrations
alembic upgrade head

# Start dev server
uvicorn app.main:app --reload --port 8000
```

### Production Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://...` |
| `JWT_SECRET` | Secret key for JWT tokens | Random 32+ char string |
| `JWT_ALGORITHM` | JWT algorithm | `HS256` |
| `ENVIRONMENT` | Runtime environment | `production` |
| `ALLOWED_ORIGINS` | CORS allowed origins | `https://example.com` |
| `ML_MODEL_PATH` | Path to TFLite models | `/app/ml_models` |

---

## Deployment Pipeline

### GitHub Actions CI/CD

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and push Docker images
        run: |
          docker build -t backend:${{ github.sha }} ./backend
          docker push registry/backend:${{ github.sha }}
      
      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /opt/cropdiag
            docker-compose pull
            docker-compose up -d
```

---

## Monitoring & Logging

### Application Logs

Logs are stored in `system_logs` table and accessible via Admin Dashboard.

| Level | Description |
|-------|-------------|
| `INFO` | Normal operations |
| `WARNING` | Non-critical issues |
| `ERROR` | Errors requiring attention |
| `CRITICAL` | System failures |

### Health Check Endpoint

```
GET /health

Response:
{
  "status": "healthy",
  "database": "connected",
  "version": "1.0.0"
}
```

### Metrics

Key metrics tracked in `system_metrics` and `daily_stats`:

- Total diagnoses per day
- API response times
- Error count
- Active users
- Average ML confidence

---

## Backup & Recovery

### Database Backup

```bash
# Create backup
pg_dump -U user -d cropdiag > backup_$(date +%Y%m%d).sql

# Restore backup
psql -U user -d cropdiag < backup_20240209.sql
```

### Automated Backups

Configure cron job for daily backups:

```bash
# /etc/cron.d/cropdiag-backup
0 2 * * * root pg_dump -U user -d cropdiag | gzip > /backups/cropdiag_$(date +\%Y\%m\%d).sql.gz
```

---

## Scaling Considerations

### Horizontal Scaling

To scale for higher traffic, you should introduce a **Load Balancer**:

- **Nginx / HAProxy**: Place in front of multiple backend containers.
- **Docker Swarm / Kubernetes**: Use an orchestrator to manage replicas.

### Vertical Scaling

- Increase server CPU/RAM for ML inference
- Use GPU instances for faster model predictions

### Caching

Consider adding Redis for:
- JWT token blacklisting
- Session management
- API response caching

---
