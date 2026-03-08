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
    otp_expire_minutes: int = 5
    
    # Storage
    upload_dir: str = "./uploads"
    max_file_size_mb: int = 10
    cloudinary_cloud_name: str = ""
    cloudinary_api_key: str = ""
    cloudinary_api_secret: str = ""
    cloudinary_secure: bool = True
    cloudinary_folder: str = "crop_diagnosis"
    
    # CORS
    allowed_origins: str = "http://localhost:3000,http://localhost:8080"
    
    # App Settings
    app_name: str = "AI Crop Disease Diagnosis System"
    debug: bool = True

    # Redis Cache
    redis_url: str = ""              # e.g. redis://localhost:6379/0 — leave empty to disable
    redis_max_connections: int = 10  # connection pool size

    # Cache TTLs (seconds) — tune per feature type
    cache_ttl_encyclopedia: int = 86400  # 24 h — static reference data (crops/diseases/pests)
    cache_ttl_trending: int = 900        # 15 min — expert trending diseases
    cache_ttl_admin_dashboard: int = 300 # 5 min — admin overview metrics
    cache_ttl_admin_metrics: int = 60    # 1 min — admin daily chart data

    # External APIs
    agmarknet_api_key: str = ""
    agmarknet_api_url: str = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"

    # Email / OTP delivery
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_from_email: str = ""
    smtp_from_name: str = "AI Crop Disease Diagnosis"
    smtp_use_tls: bool = True
    smtp_use_ssl: bool = False
    
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
