# AI Crop Disease Diagnosis System

## Overview

A comprehensive agricultural platform that enables farmers to diagnose crop diseases using AI, seek expert advice, manage their farms, and access market information.

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    FRONTEND LAYER                          │
├──────────────────┬─────────────────┬─────────────────────┤
│   Flutter App    │  Admin Dashboard │     (Future Web)   │
│   (Mobile)       │  (React/Next.js) │                    │
└────────────────────────────────────────────────────────────┘
                          │ REST API
                          ▼
┌────────────────────────────────────────────────────────────┐
│                    BACKEND LAYER                           │
│                    (FastAPI/Python)                        │
├──────────────────┬─────────────────┬─────────────────────┤
│   Auth Module    │  Business Logic │   AI/ML Services   │
│   (JWT)          │  (Routes)       │   (Diagnosis)      │
└────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────────┐
│                    DATA LAYER                              │
├────────────────────────────┬──────────────────────────────┤
│    PostgreSQL Database     │    File Storage (Uploads)   │
└────────────────────────────────────────────────────────────┘
```

## Features

| Module | Description |
|--------|-------------|
| **Disease Diagnosis** | AI-powered crop disease detection from images |
| **Expert Q&A** | Farmers can ask questions, experts provide answers |
| **Market Prices** | Real-time agricultural commodity prices |
| **Community Forum** | Discussion platform for farmers |
| **Farm Management** | Track crops, tasks, and activities |
| **Encyclopedia** | Reference for crops and diseases |

## User Roles

- **Farmer**: Diagnose diseases, ask questions, manage farm, view market prices
- **Expert**: Answer questions, provide agricultural guidance (requires approval)
- **Admin**: Manage users, approve experts, monitor system health

## Documentation

- [Use Case Diagram](./use_case_diagram.md)
- [Class Diagram](./class_diagram.md)
- [Sequence Diagram](./sequence_diagram.md)
- [Activity Diagram](./activity_diagram.md)

## API Endpoints

### Authentication
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `POST /auth/refresh` - Refresh token

### Farmer/Diagnosis
- `POST /diagnosis/predict` - Upload image for diagnosis
- `GET /diagnosis/history` - Get diagnosis history

### Questions
- `POST /questions` - Ask a question
- `GET /questions` - Get my questions

### Community
- `GET /community/posts` - Get posts
- `POST /community/posts` - Create post
- `POST /community/posts/{id}/like` - Like/unlike

### Market
- `GET /market/prices` - Get commodity prices

### Farm
- `GET /farm/crops` - Get user's crops
- `POST /farm/crops` - Add crop
- `GET /farm/tasks` - Get tasks
- `POST /farm/tasks` - Create task

### Encyclopedia
- `GET /encyclopedia/crops` - Browse crops
- `GET /encyclopedia/diseases` - Browse diseases
