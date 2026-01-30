# Docker Deployment Status

The Docker composition has been started with `docker-compose up --build -d`.

## Status
- **Building & Pulling:** The system is currently pulling images and building containers.
- **Estimated Time:** 5-10 minutes (Flutter build takes the longest).

## Access Points (Once Running)
- **Flutter App (Farmer/Expert):** http://localhost:8080
- **Admin Dashboard:** http://localhost:3000
- **Backend API:** http://localhost:8000/docs
- **Database:** localhost:5432

## Troubleshooting
- Check logs: `docker-compose logs -f`
- Stop containers: `docker-compose down`
- Rebuild: `docker-compose up --build`
