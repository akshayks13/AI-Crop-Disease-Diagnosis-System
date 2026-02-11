"""
Application Configuration Settings
"""
from pydantic_settings import BaseSettings
from typing import List
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Database
    database_url: str = "postgresql+asyncpg://postgres:password@localhost:5432/crop_diagnosis"
    
    # JWT Configuration
    jwt_secret_key: str = "your-secret-key-change-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    
    # Storage
    upload_dir: str = "./uploads"
    max_file_size_mb: int = 10
    
    # CORS
    allowed_origins: str = "http://localhost:3000,http://localhost:8080"
    
    # App Settings
    app_name: str = "AI Crop Disease Diagnosis System"
    debug: bool = True

    # External APIs
    agmarknet_api_key: str = ""
    agmarknet_api_url: str = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
    
    @property
    def cors_origins(self) -> List[str]:
        """Parse CORS origins from comma-separated string."""
        # In debug mode, allow all origins (for Flutter web dev on random ports)
        if self.debug:
            return ["*"]
        return [origin.strip() for origin in self.allowed_origins.split(",")]
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
