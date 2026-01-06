"""
Configuración de la aplicación Flask
Contiene clases de configuración para diferentes entornos (desarrollo, producción)
"""

import os
from datetime import timedelta


class Config:
    """Configuración base compartida entre todos los entornos"""
    
    # Seguridad
    SECRET_KEY = os.getenv('')
    
    # Base de datos
    DATABASE_URL = os.getenv('DATABASE_URL')
    
    # Sesiones
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'
    
    # URLs dinámicas (rutas ofuscadas)
    LOGIN_URL = os.getenv('')
    DASHBOARD_URL = os.getenv(')
    
    # Cache (SimpleCache por defecto, Redis si esta disponible)
    CACHE_TYPE = 'RedisCache' if os.getenv('REDIS_URL') else 'SimpleCache'
    CACHE_REDIS_URL = os.getenv('REDIS_URL')
    CACHE_DEFAULT_TIMEOUT = 120


class DevelopmentConfig(Config):
    """Configuración para entorno de desarrollo"""
    
    DEBUG = True
    
    # Sesiones más largas en desarrollo (2 horas)
    SESSION_COOKIE_SECURE = True  # False Permite HTTP en localhost
    PERMANENT_SESSION_LIFETIME = timedelta(hours=2)
    SESSION_REFRESH_EACH_REQUEST = False
    
    # Seguridad relajada
    TALISMAN_FORCE_HTTPS = False
    TALISMAN_CSP = None


class ProductionConfig(Config):
    """Configuración para entorno de producción"""
    
    DEBUG = False
    
    # Sesiones más cortas en producción (1 hora)
    SESSION_COOKIE_SECURE = True  # Forzar HTTPS
    PERMANENT_SESSION_LIFETIME = timedelta(hours=1)
    SESSION_REFRESH_EACH_REQUEST = False
    
    # Seguridad estricta
    TALISMAN_FORCE_HTTPS = True
    TALISMAN_STRICT_TRANSPORT_SECURITY = True
    TALISMAN_CSP = {
        'default-src': ["'self'"],
        'script-src': ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"],
        'style-src': ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"],
        'img-src': ["'self'", "data:", "https:"],
        'font-src': ["'self'", "https://cdnjs.cloudflare.com"],
        'frame-ancestors': ["'none'"],
    }


# Mapeo de nombres a clases de configuración
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}
