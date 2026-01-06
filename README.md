# Scalable-SaaS-for-Logistics-Tourism
Sistema modular (Application Factory) para manejo de cupones

# Core Backend & Logistics Architecture

[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Flask-3.1-000000?style=for-the-badge&logo=flask&logoColor=white)](https://flask.palletsprojects.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)


---

## 🏗️ Architectural Overview

El sistema implementa el patrón **Application Factory** para garantizar el desacoplamiento y facilitar el testing. La migración de una arquitectura MPA (Multi-Page Application) a una **SPA (Single Page Application)** híbrida mediante Vue 3 permite una reactividad fluida en el frontend sin abandonar la robustez de Jinja2 para la inyección de datos iniciales.

## 🔐 Security Stack & Implementation

Como desarrollador enfocado en **integridad financiera**, la seguridad es un pilar central del proyecto.

### Hashing de Grado Industrial
- **Argon2id** (`argon2-cffi`)
- Configuración:
  - Memoria: **64 MB**
  - Iteraciones: **3**
- Diseñado para mitigar ataques por **ASIC / GPU** y fuerza bruta paralela.

### Protection Layers
- **Flask-Talisman**
  - Content Security Policy (CSP) estricta
  - Forzado de **HSTS**
- **Flask-Limiter**
  - Rate limiting basado en IP
  - Aplicado a endpoints críticos (**Auth / API**)
- **CSRF Integrity**
  - Validación de tokens en todas las transacciones asíncronas desde **Vue 3**
- **RBAC (Role-Based Access Control)**
  - Decoradores personalizados
  - Control de accesos jerárquicos:
    - `Admin`
    - `Contador`
    - `Empleado`

---

## 📊 Database & Performance Engineering

El diseño relacional prioriza **trazabilidad histórica** y **consistencia de datos**.

### Snapshots de Datos
- Para evitar inconsistencias históricas (ej. cambios de información del empleado)
- Se persiste `telefono_vendedor_snapshot` en cada cupón generado

### Vistas Materializadas
- PostgreSQL:
  - `vista_resumen_semanal`
- Optimización de reportes financieros de alto costo
- Reducción significativa de la carga en el servidor de aplicaciones

---

## 🚀 Key Technical Features

- **Modular Blueprints**
  - Separación clara de dominios:
    - `Auth`
    - `Admin`
    - `Cupones`
    - `Servicios`
- **Vue 3 – Composition API**
  - Gestión de estado reactivo
  - Dashboard de Check-in
  - Enfoque *Bootstrap-free*
- **PDF Engine**
  - Generación dinámica de comprobantes con **ReportLab**
  - Optimización de:
    - Fuentes
    - Buffer de memoria
- **Env Ofuscation**
  - URLs de acceso personalizables vía `.env`
  - Mitigación de ataques por descubrimiento automático de rutas

---

## 🛠️ Stack Tecnológico

- **Language:** Python 3.10+  
  - Type Hinting implementado
- **Web Framework:** Flask 3.1.1
- **Database:** PostgreSQL + Psycopg2
- **Frontend:**
  - Vue 3
  - Vanilla CSS (Custom Design System)
  - ApexCharts
- **Infrastructure:**
  - Gunicorn
  - Docker (ready)
  - Render


## 📂 Estructura del Proyecto

```
Agencias_App/
├── app/                      # Paquete principal de la aplicación
│   ├── __init__.py          # Application Factory
│   ├── config.py            # Configuraciones (Development/Production)
│   ├── extensions.py        # Extensiones Flask
│   ├── utils/               # Módulos de utilidades
│   │   ├── auth.py         # Autenticación y hashing
│   │   ├── db.py           # Conexión a base de datos
│   │   ├── decorators.py   # Decoradores RBAC
│   │   ├── helpers.py      # Funciones auxiliares
│   │   └── pdf_generator.py # Generación de PDFs
│   └── routes/              # Blueprints por dominio
│       ├── auth.py         # Autenticación
│       ├── public.py       # Rutas públicas
│       ├── admin.py        # Panel de administración (SPA Backend)
│       ├── usuarios.py     # Gestión de usuarios
│       ├── agencias.py     # Gestión de agencias
│       ├── servicios.py    # Gestión de servicios
│       ├── cupones.py      # Gestión de cupones
│       └── reportes.py     # Reportes y métricas
├── templates/               # Templates Jinja2 (SPA mounting points)
├── static/                  # Archivos estáticos (CSS, JS, imágenes)
│   ├── js/
│   │   ├── AdminApp.js     # Admin SPA Core
│   │   ├── CheckinApp.js   # Check-in SPA Core
│   │   └── components/     # Vue Components (Admin & Public)
├── fonts/                   # Fuentes para PDFs (ReportLab)
├── run.py                   # Entry point desarrollo
├── wsgi.py                  # Entry point producción
├── requirements.txt         # Dependencias Python
├── .env                     # Variables de entorno
└── README.md               # Este archivo
```

