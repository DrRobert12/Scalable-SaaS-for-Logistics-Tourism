"""
Decoradores de Control de Acceso (RBAC)
Decoradores para proteger rutas según roles de usuario
"""

from functools import wraps
from flask import session, redirect, url_for, flash, request, jsonify
from datetime import datetime, timedelta


def login_required(f):
    """
    Decorator para requerir que el usuario esté autenticado.
    
    Verifica:
    - Usuario tiene sesión activa ('user_id' en session)
    - Sesión no ha expirado (TTL)
    
    Returns:
        - JSON 401 si es API endpoint
        - Redirect a login si es página HTML
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            # Para endpoints API, devolver JSON en vez de redirect HTML
            if request.path.startswith('/api/'):
                return jsonify({'msg': 'No autenticado. Por favor inicia sesión.'}), 401
            return redirect(url_for('auth.login'))
        
        # Verificar si la sesión ha expirado
        if session.permanent and 'login_time' in session:
            login_time = datetime.fromisoformat(session['login_time'])
            
            # Obtener timeout de configuración de Flask
            from flask import current_app
            timeout = current_app.config.get('PERMANENT_SESSION_LIFETIME', timedelta(hours=1))
            if isinstance(timeout, int):
                timeout = timedelta(seconds=timeout)
            
            if datetime.now() - login_time > timeout:
                session.clear()
                # Para endpoints API, devolver JSON
                if request.path.startswith('/api/'):
                    return jsonify({'msg': 'Sesión expirada. Por favor inicia sesión nuevamente.'}), 401
                flash('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.', 'warning')
                return redirect(url_for('auth.login'))
        
        return f(*args, **kwargs)
    return decorated_function


def admin_required(f):
    """
    Decorator para requerir rol de administrador.
    
    Verifica:
    - Usuario autenticado
    - Rol es 'admin'
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('auth.login'))
        
        # Verificar rol 'admin'
        if session.get('rol') != 'admin':
            flash('No tienes permisos para acceder a esta sección', 'error')
            return redirect(url_for('public.dashboard'))
        
        return f(*args, **kwargs)
    return decorated_function


def financiero_required(f):
    """
    Decorator para requerir rol financiero (admin o contador).
    
    Verifica:
    - Usuario autenticado
    - Rol es 'admin' o 'contador'
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('auth.login'))
        
        # Permitir acceso a admin y contador
        user_rol = session.get('rol')
        if user_rol not in ['admin', 'contador']:
            flash('No tienes permisos para acceder a esta sección', 'error')
            return redirect(url_for('public.dashboard'))
        
        return f(*args, **kwargs)
    return decorated_function
