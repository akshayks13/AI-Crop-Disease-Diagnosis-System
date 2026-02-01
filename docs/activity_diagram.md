# Activity Diagram

```mermaid
flowchart TD
    START((Start)) --> AUTH{Logged In?}
    AUTH -->|No| LOGIN[Login/Register]
    AUTH -->|Yes| HOME
    LOGIN --> OTP[Verify OTP] --> HOME
    
    HOME[Home Dashboard] --> FEATURES{Feature}
    
    FEATURES -->|Diagnose| UPLOAD[Upload Image]
    UPLOAD --> AI[AI Analysis]
    AI --> RESULT[Disease + Treatment]
    RESULT --> HOME
    
    FEATURES -->|Ask Expert| QUESTION[Write Question]
    QUESTION --> SUBMIT[Submit]
    SUBMIT --> ANSWER[View Answer] --> RATE[Rate] --> HOME
    
    FEATURES -->|Community| POSTS[Browse/Create Posts]
    POSTS --> INTERACT[Like/Comment]
    INTERACT --> HOME
    
    FEATURES -->|Farm| MANAGE[Manage Crops & Tasks]
    MANAGE --> HOME
    
    FEATURES -->|Market| PRICES[View Prices]
    PRICES --> HOME
    
    FEATURES -->|Encyclopedia| INFO[Browse Crops/Diseases]
    INFO --> HOME
    
    FEATURES -->|Profile| SETTINGS[Edit/Logout]
    SETTINGS --> HOME
```
