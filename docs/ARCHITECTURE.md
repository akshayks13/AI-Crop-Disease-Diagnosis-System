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
       ┌────────────┼────────────┐
       ▼            ▼            ▼
┌──────────────┐ ┌──────────┐ ┌─────────────────┐
│ ML MODELS    │ │  REDIS   │ │   DATA LAYER    │
│ • Disease    │ │  Cache   │ │  PostgreSQL     │
│ • Treatment  │ │  Port    │ │  File Storage   │
└──────────────┘ │  6379    │ └─────────────────┘
                 └──────────┘
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
        -UUID id
        -String email
        -String password_hash
        -UserRole role
        -UserStatus status
        -Boolean is_verified
        -String otp_code
        +verify_password(plain) bool
        +set_password(plain) void
        +generate_otp() str
        +to_response_dict() dict
    }
    class Diagnosis {
        -UUID id
        -UUID user_id
        -String disease
        -Float confidence
        -String severity
        -Float latitude
        -Float longitude
        -JSON treatment
        -Integer rating
        +to_response_dict() dict
        +update_rating(rating) void
    }
    
    class Question {
        -UUID id
        -UUID farmer_id
        -UUID diagnosis_id
        -String question_text
        -QuestionStatus status
        +close() void
        +resolve() void
        +to_response_dict() dict
    }
    
    class Answer {
        -UUID id
        -UUID question_id
        -UUID expert_id
        -String answer_text
        -Integer rating
        +update_rating(rating) void
        +to_response_dict() dict
    }
    
    class CommunityPost {
        -UUID id
        -UUID user_id
        -String title
        -String content
        -Integer likes_count
        -Integer comments_count
        +increment_likes() void
        +decrement_likes() void
        +increment_comments() void
    }
    
    class FarmCrop {
        -UUID id
        -UUID user_id
        -String crop_type
        -GrowthStage growth_stage
        -Float progress
        +calculate_progress() float
        +update_growth_stage(stage) void
    }
    
    class FarmTask {
        -UUID id
        -UUID crop_id
        -String title
        -TaskPriority priority
        -Boolean is_completed
        +toggle_complete() void
        +is_overdue() bool
    }
    
    class MarketPrice {
        -UUID id
        -String commodity
        -Float price
        -String location
        -TrendType trend
        -Float change_percent
        +to_response_dict() dict
    }
    
    class DiagnosticRule {
        -UUID id
        -UUID disease_id
        -JSON conditions
        -JSON impact
        -Float priority
        -Boolean is_active
        +evaluate(diagnosis_data) bool
    }
    
    User "1" --> "*" Diagnosis : creates
    User "1" --> "*" Question : asks
    User "1" --> "*" Answer : provides
    User "1" --> "*" CommunityPost : publishes
    User "1" --> "*" FarmCrop : manages
    Question "1" --> "*" Answer : receives
    FarmCrop "1" --> "*" FarmTask : has
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
