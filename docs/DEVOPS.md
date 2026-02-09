# DevOps & Deployment Documentation

## Overview

This document covers infrastructure, deployment, monitoring, and operational procedures for the AI Crop Disease Diagnosis System.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Load Balancer (Nginx)                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
         ┌────────────┴────────────┐
         │                         │
    ┌────▼────┐              ┌─────▼─────┐
    │ FastAPI │              │   Static  │
    │ Backend │              │   Files   │
    │ (Uvicorn)│              │  (Flutter │
    └────┬────┘              │    Web)   │
         │                    └───────────┘
    ┌────▼────┐
    │PostgreSQL│
    └─────────┘
```

---

## Docker Configuration

### docker-compose.yml

```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/cropdiag
      - JWT_SECRET=${JWT_SECRET}
      - ENVIRONMENT=production
    depends_on:
      - db
    volumes:
      - ./uploads:/app/uploads
      - ./ml_models:/app/ml_models

  db:
    image: postgres:15
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=cropdiag
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  admin:
    build: ./frontend/admin_dashboard
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://backend:8000

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

- **Backend**: Run multiple Uvicorn workers behind Nginx
- **Database**: PostgreSQL read replicas for heavy read loads
- **File Storage**: Move to S3/GCS for uploads

### Vertical Scaling

- Increase server CPU/RAM for ML inference
- Use GPU instances for faster model predictions

### Caching

Consider adding Redis for:
- JWT token blacklisting
- Session management
- API response caching

---
