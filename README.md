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
