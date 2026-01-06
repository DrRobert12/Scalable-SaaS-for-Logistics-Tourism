# Scalable-SaaS-for-Logistics-Tourism
Sistema modular (Application Factory) para manejo de cupones

# 🐢 Casa Tortuga: Core Backend & Logistics Architecture

[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Flask-3.1-000000?style=for-the-badge&logo=flask&logoColor=white)](https://flask.palletsprojects.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)


---

## 🏗️ Architectural Overview

El sistema implementa el patrón **Application Factory** para garantizar el desacoplamiento y facilitar el testing. La migración de una arquitectura MPA (Multi-Page Application) a una **SPA (Single Page Application)** híbrida mediante Vue 3 permite una reactividad fluida en el frontend sin abandonar la robustez de Jinja2 para la inyección de datos iniciales.

### Data Flow Diagram
```mermaid
graph TD
    A[Vue 3 SPA] -->|JSON Requests| B[Flask Application Factory]
    B -->|RBAC Decorators| C{Security Layer}
    C -->|Argon2id| D[Auth Service]
    C -->|SQLAlchemy/Psycopg2| E[(PostgreSQL)]
    E -->|Materialized Views| F[Analytics Engine]
    F -->|Data Points| G[ApexCharts Dashboard]
    
    
    
🔐 Security Stack & Implementation
Como desarrollador enfocado en integridad financiera, la seguridad es el pilar del proyecto:

Hashing de Grado Industrial: Implementación de Argon2id (vía argon2-cffi). Configurado con 64MB de memoria y 3 iteraciones para mitigar ataques de hardware (ASIC/GPU).

Protection Layers:

Flask-Talisman: Configuración estricta de Content Security Policy (CSP) y forzado de HSTS.

Flask-Limiter: Rate-limiting basado en IP para endpoints críticos (Auth/API).

CSRF Integrity: Validación de tokens en todas las transacciones asíncronas desde Vue 3.

RBAC (Role-Based Access Control): Decoradores personalizados que gestionan accesos jerárquicos (Admin, Contador, Empleado).

📊 Database & Performance Engineering
El diseño relacional se enfoca en la trazabilidad histórica:

Snapshots de Datos: Para evitar inconsistencias si un empleado cambia su información, el sistema guarda un telefono_vendedor_snapshot en cada cupón generado.

Vistas Materializadas: Implementación de vista_resumen_semanal en PostgreSQL para optimizar reportes financieros pesados, reduciendo la carga computacional del servidor de aplicaciones.

🚀 Key Technical Features
Modular Blueprints: Separación de dominios (Auth, Admin, Cupones, Servicios).

Vue 3 Composition API: Gestión de estado reactivo en el Dashboard de Check-in (Bootstrap-free).

PDF Engine: Generación dinámica de comprobantes mediante ReportLab, optimizando el manejo de fuentes y buffer de memoria.

Env Ofuscation: Soporte para URLs de acceso personalizables vía .env para mitigar ataques de descubrimiento de rutas automáticos.

🛠️ Stack Tecnológico
Language: Python 3.10+ (Type Hinting implementado)

Web Framework: Flask 3.1.1

Database: PostgreSQL + Psycopg2

Frontend: Vue 3, Vanilla CSS (Custom Design System), ApexCharts

Infrastructure: Gunicorn, Docker (ready), Render        
