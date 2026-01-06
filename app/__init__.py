"""
Application Factory - Punto de entrada principal del paquete app
Crea y configura la instancia de Flask con todos sus componentes
"""

import os
from flask import Flask
from flask_talisman import Talisman

# Importar extensiones
from app.extensions import cors, csrf, limiter, cache
from app.config import config

# Importar registro de fuentes (PDF)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont


def create_app(config_name=None):
    """
    Application Factory - Crea y configura la instancia de Flask
    
    Args:
        config_name (str): Nombre de la configuración ('development', 'production', 'default')
    
    Returns:
        Flask: Instancia configurada de la aplicación
    """
    
    # Determinar entorno
    if config_name is None:
        config_name = 'production' if os.getenv('FLASK_ENV') == 'production' else 'development'
    
    # Crear instancia de Flask
    app = Flask(__name__, 
                template_folder='../templates',  # Templates en raíz del proyecto
                static_folder='../static')        # Static en raíz del proyecto
    
    # Cargar configuración
    app.config.from_object(config[config_name])
    
    # Registra fuentes para PDF (ReportLab)
    _register_pdf_fonts(app)
    
    # Inicializa extensiones
    cors.init_app(app)
    csrf.init_app(app)
    limiter.init_app(app)
    cache.init_app(app)
    
    # Inicializa Connection Pool
    from app.utils.db import init_pool, close_pool
    
    # Crear pool con 3-12 conexiones
    init_pool(minconn=5, maxconn=50)
    
    # Configurar Talisman (seguridad HTTPS)
    _configure_talisman(app, config_name)
    
    # Ejecutar migraciones automáticas en producción
    if config_name == 'production':
        _run_auto_migration(app)
    
    # Registrar blueprints
    _register_blueprints(app)
    
    # Mensajes de debug
    if app.config['DEBUG']:
        print(f"✓ App iniciada en modo {config_name.upper()}")
        print(f"✓ Login URL: /{app.config['LOGIN_URL']}")
        print(f"✓ Dashboard URL: /{app.config['DASHBOARD_URL']}")
    
    return app


def _register_pdf_fonts(app):
    """Registra fuentes TrueType para generación de PDFs"""
    try:
        font_paths = {
            'Roboto-Regular': 'fonts/Roboto-Regular.ttf',
            'Roboto-Bold': 'fonts/Roboto-Bold.ttf'
        }
        
        for font_name, font_path in font_paths.items():
            try:
                # Intentar ruta relativa
                pdfmetrics.registerFont(TTFont(font_name, font_path))
            except:
                try:
                    # Intentar ruta absoluta
                    absolute_path = os.path.join(os.path.dirname(app.root_path), font_path)
                    pdfmetrics.registerFont(TTFont(font_name, absolute_path))
                except Exception as font_error:
                    app.logger.warning(f"Error al registrar {font_name}: {font_error}")
                    continue
        
        app.logger.info("✓ Fuentes PDF registradas correctamente")
    except Exception as e:
        app.logger.error(f"Error al registrar fuentes PDF: {e}")


def _configure_talisman(app, config_name):
    """Configura Talisman para seguridad HTTPS"""
    if config_name == 'production':
        Talisman(
            app,
            force_https=app.config['TALISMAN_FORCE_HTTPS'],
            strict_transport_security=app.config['TALISMAN_STRICT_TRANSPORT_SECURITY'],
            content_security_policy=app.config['TALISMAN_CSP']
        )
    else:
        # Modo desarrollo: Talisman deshabilitado
        Talisman(app, force_https=False, content_security_policy=None)


def _run_auto_migration(app):
    """Ejecuta migraciones automáticas en producción (Render)"""
    try:
        from migrate_render_complete import migrate_render_complete
        app.logger.info("Ejecutando migración automática...")
        migrate_render_complete()
        app.logger.info("✓ Migración completada")
    except Exception as e:
        app.logger.error(f"Error en migración automática: {e}")
        # Continuar de todas formas


def _register_blueprints(app):
    """Registra todos los blueprints de la aplicación"""
    
    # Importar blueprints
    from app.routes.auth import auth_bp, login
    from app.routes.public import public_bp, dashboard
    from app.routes.admin import admin_bp
    from app.routes.usuarios import usuarios_bp
    from app.routes.servicios import servicios_bp
    from app.routes.cupones import cupones_bp
    from app.routes.agencias import agencias_bp
    from app.routes.reportes import reportes_bp
    from app.utils.decorators import login_required
    
    # Registrar blueprints normalmente
    app.register_blueprint(auth_bp)
    app.register_blueprint(public_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(usuarios_bp)
    app.register_blueprint(servicios_bp)
    app.register_blueprint(cupones_bp)
    app.register_blueprint(agencias_bp)
    app.register_blueprint(reportes_bp)
    
    # Registrar rutas con URLs personalizadas (ofuscadas)
    login_url = app.config['LOGIN_URL']
    dashboard_url = app.config['DASHBOARD_URL']
    
    # Aplicar decoradores y registrar
    decorated_login = limiter.limit("5 per minute")(limiter.limit("20 per hour")(csrf.exempt(login)))
    decorated_dashboard = login_required(dashboard)
    
    app.add_url_rule(f'/{login_url}', 'custom_login', decorated_login, methods=['GET', 'POST'])
    app.add_url_rule(f'/{dashboard_url}', 'custom_dashboard', decorated_dashboard, methods=['GET'])
