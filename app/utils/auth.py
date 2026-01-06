from flask import Blueprint, render_template, request, redirect, url_for, session, flash

from app.utils.db import get_db
from app.utils.auth import hash_password, verify_password
from app.extensions import limiter, csrf

# Crear blueprint
auth_bp = Blueprint('auth', __name__)


def login():
    """
    Ruta de login con autenticación y redirección según rol.
    """
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        
        if not email or not password:
            flash('Por favor, completa todos los campos', 'error')
            return render_template('login.html')
        
        # NUEVO: Usar modelo Usuario
        from app.models.usuario import Usuario
        
        try:
            user = Usuario.get_by_email(email)
            
            if not user:
                flash('Credenciales inválidas', 'error')
                return render_template('login.html')
            
            # Verificar contraseña usando sistema híbrido (Argon2 + PBKDF2 legacy)
            if not verify_password(password, user.password_hash):
                flash('Credenciales inválidas', 'error')
                return render_template('login.html')
            
            # ============================================
            # HOOK DE MIGRACIÓN CRIPTOGRÁFICA (TOFU)
            # Migra silenciosamente de PBKDF2 a Argon2id
            # ============================================
            from app.utils.auth import needs_rehash, hash_password
            from app.utils.db import get_db
            
            if needs_rehash(user.password_hash):
                try:
                    new_hash = hash_password(password)
                    with get_db() as (conn, cur):
                        cur.execute(
                            "UPDATE usuarios SET password_hash = %s WHERE id = %s",
                            (new_hash, user.id)
                        )
                    print(f"Migración Argon2id completada para usuario ID={user.id}")
                except Exception as migration_error:
                    # No interrumpir el login si la migración falla
                    print(f"Error en migración Argon2id (usuario {user.id}): {migration_error}")
            # ============================================
            
            # Verificar que el usuario esté activo
            if not user.activo:
                flash('Tu cuenta ha sido desactivada. Contacta al administrador.', 'error')
                return render_template('login.html')
            
            # Verificar que la agencia esté activa (solo para empleados)
            if user.rol == 'empleado' and user.agencia_id:
                from app.models import Agencia
                agencia = Agencia.get_by_id(user.agencia_id)
                if not agencia or not agencia.activo:
                    flash('Tu agencia ha sido desactivada. Contacta al administrador.', 'error')
                    return render_template('login.html')
            
            # Verificar aprobación (Solo para empleados, admins/contadores nacen aprobados)
            if not user.cuenta_aprobada and user.rol == 'empleado':
                flash('Tu cuenta está pendiente de aprobación.', 'warning')
                return render_template('login.html')
            
            # Login exitoso
            session.clear()
            session.modified = True
            session.permanent = True  # Activa el TTL configurado en config
            
            # Guardar datos en sesión (usando atributos del modelo)
            session['user_id'] = user.id
            session['user_nombre'] = user.nombre
            session['user_apellido'] = user.apellido
            session['user_email'] = user.email
            session['rol'] = user.rol
            session['agencia_id'] = user.agencia_id
            session['agencia_nombre'] = user.agencia_nombre
            session['user_telefono'] = user.telefono
            
            flash(f'Bienvenido, {user.nombre}!', 'success')
            
            # Redirigir según el rol del usuario
            if user.rol == 'admin':
                return redirect(url_for('admin.panel_dashboard'))  # Nueva ruta SPA unificada
            elif user.rol == 'contador':
                return redirect(url_for('admin.panel_dashboard'))  # Nueva ruta SPA unificada
            else:
                return redirect(url_for('custom_dashboard'))
                
        except Exception as e:
            print(f" Error en login: {e}")
            import traceback
            traceback.print_exc()
            flash('Error al procesar el login', 'error')
            return render_template('login.html')
    
    # GET request
    return render_template('login.html')


@auth_bp.route('/logout')
def logout():
    """
    Ruta para cerrar sesión.
    """
    session.clear()
    flash('Sesión cerrada exitosamente', 'success')
    return redirect(url_for('custom_login'))


@auth_bp.route("/registro", methods=["GET", "POST"])
@limiter.limit("20 per hour")
def registro():
    """
    Ruta de registro de nuevos usuarios (empleados).
    """
    if request.method == "GET":
        try:
            with get_db() as (conn, cur):
                cur.execute("SELECT id, nombre FROM agencias WHERE activo = TRUE ORDER BY nombre")
                agencias = cur.fetchall()
                return render_template("registro.html", agencias=agencias)
        except Exception as e:
            print(f"Error obteniendo agencias: {e}")
            flash("Error cargando formulario de registro", "error")
            return render_template("registro.html", agencias=[])
    
    # POST: Procesar registro
    email = request.form.get("email")
    password = request.form.get("password")
    password_confirm = request.form.get("password_confirm")
    nombre = request.form.get("nombre")
    apellido = request.form.get("apellido")
    telefono = request.form.get("telefono", "")
    agencia_id = request.form.get("agencia_id")
    
    # Validaciones
    if not all([email, password, password_confirm, nombre, apellido, agencia_id]):
        flash("Por favor, completa todos los campos obligatorios", "error")
        return redirect(url_for("auth.registro"))
    
    if password != password_confirm:
        flash("Las contraseñas no coinciden", "error")
        return redirect(url_for("auth.registro"))
    
    if len(password) < 8:
        flash("La contraseña debe tener al menos 8 caracteres", "error")
        return redirect(url_for("auth.registro"))
    
    try:
        with get_db() as (conn, cur):
            # Verificar si el email ya existe
            cur.execute("SELECT id FROM usuarios WHERE email = %s", (email,))
            if cur.fetchone():
                flash("Este email ya está registrado", "error")
                return redirect(url_for("auth.registro"))
            
            # Crear usuario
            password_hash = hash_password(password)
            cur.execute("""
                INSERT INTO usuarios (email, password_hash, nombre, apellido, telefono, agencia_id, rol, cuenta_aprobada, activo) 
                VALUES (%s, %s, %s, %s, %s, %s, 'empleado', FALSE, FALSE)
            """, (email, password_hash, nombre, apellido, telefono, agencia_id))
            conn.commit()
            
            flash("¡Cuenta creada exitosamente! Espera a que el Administrador Central la active.", "success")
            return redirect(url_for("custom_login"))
            
    except Exception as e:
        print(f"Error en registro: {e}")
        flash("Error al crear la cuenta. Intenta nuevamente.", "error")
        return redirect(url_for("auth.registro"))
