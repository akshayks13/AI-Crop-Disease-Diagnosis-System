# System Architecture

## Overview
AI-powered crop disease diagnosis platform for farmers with expert consultation.

## Architecture
```
┌─────────────────────────────────────────────┐
│              FRONTEND                       │
│  Flutter App (Mobile)  │  Next.js (Admin)   │
└─────────────────────────────────────────────┘
                    │ REST API
                    ▼
┌─────────────────────────────────────────────┐
│           BACKEND (FastAPI)                 │
│  Auth │ Routes │ Services │ AI/ML          │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│              DATA LAYER                     │
│     PostgreSQL      │    File Storage       │
└─────────────────────────────────────────────┘
```

## Core Models

```mermaid
classDiagram
    class User {
        +UUID id
        +String email
        +UserRole role
        +UserStatus status
    }
    
    class Diagnosis {
        +UUID id
        +UUID user_id
        +String disease_name
        +Float confidence
        +JSON treatment_plan
    }
    
    class Question {
        +UUID id
        +UUID farmer_id
        +String question_text
        +QuestionStatus status
    }
    
    class Answer {
        +UUID id
        +UUID question_id
        +UUID expert_id
        +String answer_text
        +Integer rating
    }
    
    User "1" --> "*" Diagnosis
    User "1" --> "*" Question
    User "1" --> "*" Answer
    Question "1" --> "*" Answer
```

## User Roles

```mermaid
graph LR
    subgraph Actors
        F[👨‍🌾 Farmer]
        E[👨‍🔬 Expert]
        A[👨‍💼 Admin]
    end
    
    subgraph Features
        D[Disease Diagnosis]
        Q[Ask Questions]
        C[Community]
        M[Market Prices]
        FA[Farm Management]
    end
    
    F --> D
    F --> Q
    F --> C
    F --> M
    F --> FA
    
    E --> Q
    E --> C
    
    A --> |Manage Users| U[User Management]
    A --> |Approve| E
```
