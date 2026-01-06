"""
Flask Extensions -
Estas extensiones se inicializan aquí y se vinculan a la app en create_app()
"""

from flask_cors import CORS
from flask_wtf.csrf import CSRFProtect
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_caching import Cache

# Instancias sin vincular (se vinculan con init_app en factory)
cors = CORS()
csrf = CSRFProtect()
cache = Cache()

# Limiter requiere configuración especial
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["200 per day", "100 per hour"],
    storage_uri="memory://",
    strategy="fixed-window"
)
