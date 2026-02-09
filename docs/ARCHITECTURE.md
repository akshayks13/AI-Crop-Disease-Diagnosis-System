# System Architecture

## Overview
AI-powered crop disease diagnosis platform for farmers with expert consultation, featuring dual ML models for disease classification and treatment recommendation.

## High-Level Architecture
```
┌─────────────────────────────────────────────┐
│              FRONTEND                       │
│  Flutter App (Mobile)  │  Next.js (Admin)   │
└─────────────────────────────────────────────┘
                    │ REST API
                    ▼
┌─────────────────────────────────────────────┐
│           BACKEND (FastAPI)                 │
│  Auth │ Routes │ Services │ Agronomy       │
└─────────────────────────────────────────────┘
                    │
       ┌────────────┴────────────┐
       ▼                         ▼
┌──────────────┐        ┌─────────────────┐
│ ML MODELS    │        │   DATA LAYER    │
│ • Disease    │        │  PostgreSQL     │
│ • Treatment  │        │  File Storage   │
└──────────────┘        └─────────────────┘
```

## ML Model Architecture

The system employs two specialized TensorFlow Lite models:

### 1. Disease Classification Model
- **Input**: Crop leaf/plant images (224x224 RGB)
- **Output**: Disease predictions with confidence scores
- **Model**: MobileNetV2-based CNN, TFLite format
- **Accuracy**: ~92% on test dataset

### 2. Treatment Recommendation Model  
- **Input**: Disease name, crop type, severity, environmental context
- **Output**: Ranked chemical and organic treatment options
- **Model**: Ensemble model (Random Forest + BERT), TFLite format
- **Integration**: Provides personalized treatment plans based on diagnosis

```mermaid
flowchart LR
    A[User Image] --> B[Disease Model]
    B --> C[Disease Prediction]
    C --> D[Treatment Model]
    D --> E[Treatment Plan]
    E --> F[Backend API]
    F --> G[User Diagnosis]
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
        +String disease
        +Float confidence
        +JSON treatment
        +Integer rating
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
    
    class DiagnosticRule {
        +UUID id
        +UUID disease_id
        +JSON conditions
        +JSON impact
        +Float priority
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
        KB[Knowledge Base]
    end
    
    F --> D
    F --> Q
    F --> C
    F --> M
    F --> FA
    
    E --> Q
    E --> C
    E --> KB
    
    A --> |Manage Users| U[User Management]
    A --> |Approve| E
    A --> |Manage| KB
```

## Agronomy Intelligence Layer

The platform includes an intelligent agronomy system that enhances ML predictions:

- **Diagnostic Rules**: Context-aware validation of disease predictions
- **Treatment Constraints**: Safety checks for treatment recommendations
- **Seasonal Patterns**: Regional disease prevalence data
- **Expert Knowledge**: Community-driven agronomy database
