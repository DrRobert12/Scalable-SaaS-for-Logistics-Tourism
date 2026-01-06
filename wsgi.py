"""
Punto de Entrada para Producción (WSGI)
Para uso con Gunicorn, uWSGI u otros servidores WSGI
"""

from app import create_app

# Crear instancia de la aplicación para producción
app = create_app(config_name='production')

# Exponer 'application' para compatibilidad con algunos servidores WSGI
application = app
