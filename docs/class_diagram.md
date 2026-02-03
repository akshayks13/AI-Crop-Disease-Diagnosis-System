# Class Diagram

```mermaid
classDiagram
    %% ==================== USER MANAGEMENT ====================
    class User {
        +UUID id
        +String email
        +String password_hash
        +String full_name
        +String phone
        +UserRole role
        +UserStatus status
        +Boolean is_verified
        +String otp_code
        +DateTime otp_created_at
        +String expertise_domain
        +String qualification
        +Integer experience_years
        +String location
        +DateTime created_at
        +verify_password() Boolean
    }
    
    class UserRole {
        <<enum>>
        FARMER
        EXPERT
        ADMIN
    }
    
    class UserStatus {
        <<enum>>
        PENDING
        ACTIVE
        SUSPENDED
    }
    
    %% ==================== DIAGNOSIS ====================
    class Diagnosis {
        +UUID id
        +UUID user_id
        +String media_path
        +String crop_type
        +String disease_name
        +Float confidence
        +String severity
        +JSON symptoms
        +JSON treatment_plan
        +JSON prevention_tips
        +String location
        +DateTime created_at
    }
    
    %% ==================== Q&A SYSTEM ====================
    class Question {
        +UUID id
        +UUID farmer_id
        +UUID diagnosis_id
        +String question_text
        +String media_path
        +QuestionStatus status
        +DateTime created_at
    }
    
    class Answer {
        +UUID id
        +UUID question_id
        +UUID expert_id
        +String answer_text
        +Integer rating
        +DateTime created_at
    }
    
    class QuestionStatus {
        <<enum>>
        OPEN
        RESOLVED
        CLOSED
    }
    
    %% ==================== COMMUNITY ====================
    class CommunityPost {
        +UUID id
        +UUID user_id
        +String title
        +String content
        +String image_path
        +Integer likes_count
        +Integer comments_count
        +Boolean is_pinned
        +DateTime created_at
    }
    
    class CommunityComment {
        +UUID id
        +UUID post_id
        +UUID user_id
        +String content
        +DateTime created_at
    }
    
    class PostLike {
        +UUID id
        +UUID post_id
        +UUID user_id
        +DateTime created_at
    }
    
    %% ==================== FARM MANAGEMENT ====================
    class FarmCrop {
        +UUID id
        +UUID user_id
        +String name
        +String crop_type
        +String field_name
        +Float area_size
        +Date sow_date
        +Date expected_harvest_date
        +GrowthStage growth_stage
        +Float progress
        +String notes
        +Boolean is_active
    }
    
    class FarmTask {
        +UUID id
        +UUID user_id
        +UUID crop_id
        +String title
        +String description
        +DateTime due_date
        +TaskPriority priority
        +Boolean is_completed
        +Boolean is_recurring
        +Integer recurrence_days
    }
    
    class GrowthStage {
        <<enum>>
        GERMINATION
        SEEDLING
        VEGETATIVE
        FLOWERING
        FRUITING
        RIPENING
        HARVEST
    }
    
    class TaskPriority {
        <<enum>>
        LOW
        MEDIUM
        HIGH
    }
    
    %% ==================== MARKET ====================
    class MarketPrice {
        +UUID id
        +String commodity
        +Float price
        +String unit
        +String location
        +TrendType trend
        +Float change_percent
        +Float min_price
        +Float max_price
        +DateTime recorded_at
    }
    
    class TrendType {
        <<enum>>
        UP
        DOWN
        STABLE
    }
    
    %% ==================== ENCYCLOPEDIA ====================
    class CropInfo {
        +UUID id
        +String name
        +String scientific_name
        +String description
        +String season
        +Float temp_min
        +Float temp_max
        +String water_requirement
        +JSON growing_tips
        +JSON common_diseases
        +String image_url
    }
    
    class DiseaseInfo {
        +UUID id
        +String name
        +String scientific_name
        +JSON affected_crops
        +String description
        +JSON symptoms
        +JSON chemical_treatment
        +JSON organic_treatment
        +JSON prevention
        +String severity_level
    }
    
    %% ==================== RELATIONSHIPS ====================
    User "1" --> "*" Diagnosis : creates
    User "1" --> "*" Question : asks
    User "1" --> "*" Answer : provides
    User "1" --> "*" CommunityPost : publishes
    User "1" --> "*" CommunityComment : writes
    User "1" --> "*" PostLike : gives
    User "1" --> "*" FarmCrop : manages
    User "1" --> "*" FarmTask : owns
    
    Question "*" --> "0..1" Diagnosis : references
    Question "1" --> "*" Answer : receives
    
    CommunityPost "1" --> "*" CommunityComment : contains
    CommunityPost "1" --> "*" PostLike : receives
    
    FarmCrop "1" --> "*" FarmTask : has
    
    CropInfo "1" --> "*" DiseaseInfo : affected_by
    
    User ..> UserRole
    User ..> UserStatus
    Question ..> QuestionStatus
    FarmCrop ..> GrowthStage
    FarmTask ..> TaskPriority
    MarketPrice ..> TrendType
```
