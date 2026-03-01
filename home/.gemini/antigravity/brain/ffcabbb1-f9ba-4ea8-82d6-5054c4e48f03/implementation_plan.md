# Plan de Implementación — PCE-Agencia (Backend)

## 🎯 Objetivo General

Desarrollar la estructura inicial del backend para el sistema PCE-Agencia, configurando un servidor web escalable con Node.js, Express y una base de datos MongoDB. Este plan servirá como guía paso a paso para la generación de código.

## 📁 Estructura del Proyecto Recomendada

```
server/
├── src/
│   ├── config/
│   │   └── db.js                # Conexión persistente a MongoDB
│   ├── models/                  # Esquemas de Mongoose con Tipado JSDoc
│   │   ├── User.model.js
│   │   ├── Cliente.model.js
│   │   ├── Proveedor.model.js
│   │   ├── Itinerario.model.js
│   │   ├── Reserva.model.js
│   │   ├── Transaccion.model.js
│   │   └── Factura.model.js
│   ├── controllers/             # Controladores (Vacíos inicialmente)
│   ├── routes/                  # Configuración de Endpoints
│   ├── middlewares/             # Funciones de validación
│   └── utils/                   # Utilidades generales
├── .env                         # Variables de entorno (PORT, MONGO_URI, JWT_SECRET)
├── package.json
└── index.js                     # Punto de entrada principal
```

---

## 🏗️ FASE 1: Configuración Inicial y Conexión

1. **Inicializar Proyecto:** Configurar `package.json` con dependencias (`express`, `mongoose`, `dotenv`, `cors`, `bcryptjs`, `jsonwebtoken`) y scripts de desarrollo (`nodemon`).
2. **Setup del Servidor (`index.js`):**
   - Configurar middlewares base: `cors()`, `express.json()`.
   - Definir puerto (ej. 4000) leyendo de `process.env`.
   - Incluir manejo de errores global.
3. **Conexión a MongoDB (`src/config/db.js`):**
   - Implementar función asíncrona para conectar a Mongoose usando la URL de `.env`.
   - Agregar logs para éxito y caídas de conexión.

---

## 🗄️ FASE 2: Implementación de Modelos de Datos

Todos los modelos deben incluir `timestamps: true` y estar correctamente documentados.

### 2.1 Módulo de Autenticación y Usuarios

- **`User.model.js`**:
  - Campos: `nombre`, `email` (único), `password`, `rol` (enum: `admin`, `empleado`, `cliente`), `activo`.

### 2.2 Módulo de Clientes

- **`Cliente.model.js`**:
  - Relación 1:1 con `User` referenciando `ObjectId`.
  - Campos detallados: `telefono`, `direccion`, `preferenciasViaje` (Arr de Strings), e `historialViajes` (Refs a `Reserva`).

### 2.3 Módulo de Proveedores

- **`Proveedor.model.js`**:
  - Datos de contacto embebidos y tipado claro (`aerolinea`, `hotel`, etc.).
  - Arreglo de subdocumentos para `catalogo` (servicios provistos por el proveedor).

### 2.4 Módulo de Itinerarios

- **`Itinerario.model.js`**:
  - Relación con el creador (`User`).
  - Lista de actividades con soporte de coordenadas `lat`/`lng` para mapas.

### 2.5 Módulo Central (Reservas)

- **`Reserva.model.js`**:
  - Entidad pivote. Referencia al `Cliente`, al `User` (empleado que gestiona), y al `Itinerario`.
  - Arreglo de `servicios` que une la reserva con múltiples `Proveedores`.
  - Control de estados detallado.

### 2.6 Módulo Financiero

- **`Transaccion.model.js`**:
  - Registro inmutable de pagos/reembolsos ligados a una `Reserva`.
- **`Factura.model.js`**:
  - Documento fiscal generado con items detallados y un enlace referencial (`urlPDF`).

---

## 🛣️ FASE 3: Enrutador Principal

- Crear archivos base en `src/routes/` que exporten un `Router` de Express.
- En `index.js`, conectar todas las rutas usando un prefijo: `/api/auth`, `/api/clientes`, etc.

---

> [!NOTE]
> A medida que procedas a generar el código, asegúrate de utilizar JSDoc en las entidades principales y de priorizar la legibilidad del código. Utiliza inyección de dependencias o patrones funcionales cuando la lógica de la ruta crezca.
