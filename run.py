"""
Punto de Entrada para Desarrollo
Ejecuta la aplicación Flask con configuración de desarrollo
"""

import os
from app import create_app

# Crear instancia de la aplicación
app = create_app()

if __name__ == '__main__':
    # Configuración del servidor de desarrollo
    port = int(os.getenv('PORT', 5000))
    debug_mode = os.getenv('FLASK_ENV') != 'production'
    
    print(f"Iniciando servidor en puerto {port}")
    app.run(
        host='0.0.0.0',
        port=port,
        debug=debug_mode
    )
