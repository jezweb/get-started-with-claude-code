"""
Example configuration module for FastAPI applications
Shows how to use the environment variables with Pydantic Settings
"""

from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional, List, Literal
from functools import lru_cache


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables
    Uses Pydantic for validation and type safety
    """
    
    # ==============================================
    # Application Settings
    # ==============================================
    app_name: str = "AI Application"
    app_env: Literal["development", "staging", "production"] = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    app_debug: bool = False
    
    # ==============================================
    # Google Gemini Configuration
    # ==============================================
    gemini_api_key: str
    gemini_model: str = "gemini-2.5-flash"
    gemini_temperature: float = 0.7
    gemini_max_tokens: int = 1000
    gemini_top_p: float = 0.95
    gemini_thinking_mode: bool = False
    
    # ==============================================
    # Use Case: Chat
    # ==============================================
    chat_model: str = "gemini-2.5-flash"
    chat_temperature: float = 0.7
    chat_max_tokens: int = 1000
    chat_streaming: bool = True
    
    # ==============================================
    # Use Case: Document Generation
    # ==============================================
    doc_model: str = "gemini-2.5-pro"
    doc_temperature: float = 0.5
    doc_max_tokens: int = 4000
    doc_thinking_mode: bool = True
    
    # ==============================================
    # Use Case: Document Analysis
    # ==============================================
    analysis_model: str = "gemini-2.5-pro"
    analysis_temperature: float = 0.2
    analysis_max_tokens: int = 2000
    analysis_enable_pdf: bool = True
    analysis_enable_vision: bool = True
    
    # ==============================================
    # Database
    # ==============================================
    database_url: str = "sqlite:///./app.db"
    database_echo: bool = False
    
    # ==============================================
    # Security
    # ==============================================
    secret_key: str
    jwt_expiration: int = 3600
    cors_origins: List[str] = ["http://localhost:3000"]
    
    # ==============================================
    # Rate Limiting
    # ==============================================
    rate_limit_requests: int = 100
    rate_limit_window: int = 3600
    
    # ==============================================
    # File Paths
    # ==============================================
    upload_dir: str = "./uploads"
    log_dir: str = "./logs"
    temp_dir: str = "/tmp"
    
    # ==============================================
    # Optional: Fallback Models
    # ==============================================
    claude_api_key: Optional[str] = None
    openai_api_key: Optional[str] = None
    enable_fallback: bool = False
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False
    )
    
    @property
    def is_production(self) -> bool:
        """Check if running in production"""
        return self.app_env == "production"
    
    @property
    def is_development(self) -> bool:
        """Check if running in development"""
        return self.app_env == "development"
    
    def get_model_for_use_case(self, use_case: str) -> dict:
        """Get model configuration for a specific use case"""
        configs = {
            "chat": {
                "model": self.chat_model,
                "temperature": self.chat_temperature,
                "max_tokens": self.chat_max_tokens,
            },
            "document": {
                "model": self.doc_model,
                "temperature": self.doc_temperature,
                "max_tokens": self.doc_max_tokens,
            },
            "analysis": {
                "model": self.analysis_model,
                "temperature": self.analysis_temperature,
                "max_tokens": self.analysis_max_tokens,
            },
        }
        return configs.get(use_case, {
            "model": self.gemini_model,
            "temperature": self.gemini_temperature,
            "max_tokens": self.gemini_max_tokens,
        })


@lru_cache()
def get_settings() -> Settings:
    """
    Get cached settings instance
    Uses lru_cache to avoid reading .env file multiple times
    """
    return Settings()


# ==============================================
# Example usage in FastAPI
# ==============================================
if __name__ == "__main__":
    # Example: Load and display settings
    settings = get_settings()
    
    print(f"App Name: {settings.app_name}")
    print(f"Environment: {settings.app_env}")
    print(f"Debug Mode: {settings.app_debug}")
    print(f"Default Model: {settings.gemini_model}")
    
    # Get configuration for specific use case
    chat_config = settings.get_model_for_use_case("chat")
    print(f"\nChat Configuration:")
    print(f"  Model: {chat_config['model']}")
    print(f"  Temperature: {chat_config['temperature']}")
    print(f"  Max Tokens: {chat_config['max_tokens']}")
    
    # Example FastAPI usage:
    """
    from fastapi import FastAPI, Depends
    import google.generativeai as genai
    
    app = FastAPI()
    
    @app.on_event("startup")
    async def startup_event():
        settings = get_settings()
        genai.configure(api_key=settings.gemini_api_key)
    
    @app.post("/chat")
    async def chat(
        message: str,
        settings: Settings = Depends(get_settings)
    ):
        config = settings.get_model_for_use_case("chat")
        model = genai.GenerativeModel(
            model_name=config["model"],
            generation_config={
                "temperature": config["temperature"],
                "max_output_tokens": config["max_tokens"],
            }
        )
        response = model.generate_content(message)
        return {"response": response.text}
    """