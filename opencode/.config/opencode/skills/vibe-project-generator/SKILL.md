---
name: vibe-project-generator
description: Universal project generator for web pages, landing pages, dashboards, and digital products. Activates when user wants to create a new project from scratch, generate a landing page, build a dashboard, or start any web development task.
license: MIT
metadata:
  category: project-generator
  version: 1.0.0
---

# 🌐 Vibe Project Generator

Soy tu generador de proyectos web. Cuando quieras crear algo nuevo, uso este sistema para guiarte paso a paso y entregarte un proyecto completo.

---

## 📋 Catálogo de 30 Tipos de Proyectos

### 🏢 PÁGINAS CORPORATIVAS Y LEGALES
1. **Abogados** - Legal, urgencia, confianza, testimonios
2. **Consultorías** - B2B, autoridad, casos de éxito
3. **Despachos médicos** - Salud, humanidad, citas online
4. **Inmobiliarias** - Propiedades, galerías, mapas
5. **Notarías** - Trámites, documentación, confianza
6. **Contadores/Asesores** - Finanzas, fiscal, empresarial

### 💼 NEGOCIOS Y SERVICIOS
7. **Restaurantes** - Menú, reservas, delivery
8. **Barberías/Pelquerías** - Citas, precios, galerías
9. **Gimnasios** - Planes, horarios, inscripción
10. **Talleres mecánicos** - Citas, servicios, emergencias
11. **Fontaneros/Electricistas** - Urgencias 24h, servicios
12. **Agencias de viaje** - Destinos, paquetes, reservas

### 🛒 E-COMMERCE Y PRODUCTOS
13. **Tienda online** - Productos, carrito, checkout
14. **Tienda de moda** - Catálogo, tallas, looks
15. **Tienda de electrónica** - Productos, comparativas
16. **Marketplace** - Multi-vendedor, categorías

### 📱 SAAS Y TECNOLOGÍA
17. **SaaS Dashboard** - Métricas, gráficos, usuarios
18. **App de tareas** - Kanban, notas, colaboración
19. **CRM simple** - Leads, Pipeline, Contactos
20. **Herramienta de AI** - Chat, playground, pricing

### 📈 MARKETING Y CAPTACIÓN
21. **Landing Page B2B** - Lead gen, contenido, CTAs
22. **Landing Page B2C** - Producto, beneficios, urgencia
23. **Squeeze Page** - Captura email, lead magnet
24. **Webinar/Venta** - Countdown, scarcity, registro

### 🎓 EDUCACIÓN Y COMUNIDAD
25. **Cursos online** - Lecciones, progreso, certificados
26. **Academia/Instituto** - Carreras, admisiones
27. **Podcast/Blog** - Episodios, newsletter, donate

### 🏠 VARIOS
28. **Portfolio personal** - Proyectos, CV, contacto
29. **Eventos** - Conciertos, bodas, conferencias
30. **ONG/Donaciones** - Causa, impacto, donación

---

## 🔄 Flujo de Generación

### PASO 1: Recoger Información (siempre hacer estas preguntas)

```
Preguntar SIEMPRE:
├── 1. Tipo de proyecto (del catálogo)
├── 2. Nombre del negocio/marca
├── 3. Ubicación (ciudad, país)
├── 4. Público objetivo (B2B/B2C, edad, dolor principal)
├── 5. Diferenciador principal (¿por qué elegirte?)
├── 6. Action principal (llamar, whatsapp, formulario, compra)
└── 7. Presupuesto/timeline
```

### PASO 2: Categoría Específica (preguntas según tipo)

**Para LANDING PAGES:**
- ¿Cuál es la oferta principal?
- ¿Hay urgencia o escasez?
- ¿Lead magnet o venta directa?

**Para DASHBOARDS:**
- ¿Qué métricas son clave?
- ¿Usuarios internos o clientes?
- ¿Nivel de acceso múltiple?

**Para E-COMMERCE:**
- ¿Productos físicos o digitales?
- ¿Métodos de pago?
- ¿Envío o descarga?

**Para SAAS:**
- ¿Modelo freemium?
- ¿APIs a integrar?
- ¿Onboarding necesario?

### PASO 3: Entregar Blueprint

Antes de escribir código, generar documento con:
1. Resumen ejecutivo (5 líneas)
2. Propuesta de valor única
3. Arquitectura de página (wireframe textual)
4. Copy inicial (3 variantes de headlines)
5. CTAs definidos
6. Guía visual (colores, tipografía)
7. SEO checklist
8. Tracking plan

### PASO 4: Implementación

Seguir el stack estándar:
- HTML5 + Tailwind CSS (CDN)
- JavaScript Vanilla
- Formularios con validación
- Responsive Mobile-First
- Accesibilidad WCAG básica

---

## 📝 Templates de Copy por Categoría

### Template: HERO LANDING PAGE
```
H1: [Problema/Dolor] + [Solución/Beneficio]
Subtítulo: [Benefit + specificity]
Bullets: 
  - [Benefit 1] + [proof point]
  - [Benefit 2] + [proof point]
  - [Benefit 3] + [proof point]
CTA: [Action] + [Value]
```

### Template: HERO DASHBOARD
```
H1: [Herramienta] para [Problema]
Subtítulo: [Cómo resuelve] sin [dolor]
Bullets:
  - [Feature 1]: [Benefit]
  - [Feature 2]: [Benefit]
  - [Feature 3]: [Benefit]
CTA: Empezar Gratis / Solicitar Demo
```

### Template: HERO E-COMMERCE
```
H1: [Producto] + [Key Benefit]
Subtítulo: [Social proof o guarantee]
CTA: Ver Productos / Comprar Ahora
```

### Template: HERO SAAS
```
H1: [Verbo] + [Resultado] + [Con qué]
Subtítulo: [Quién + Benefit + Speed]
Bullets:
  - [Métrica 1] mejora en [X%]
  - [Métrica 2] mejora en [X%]
CTA: Prueba Gratis / Demo
```

---

## 🎯 KPIs por Tipo de Proyecto

| Tipo | KPI Principal | KPI Secundario |
|------|--------------|----------------|
| Landing B2B | Tasa de conversión lead | Scroll depth |
| Landing B2C | Tasa de conversión venta | Bounce rate |
| Dashboard | DAU/MAU | Tiempo en app |
| E-commerce | Conversion rate | AOV |
| SaaS | Sign-ups | Churn |
| Portfolio | Contacto emails | Tiempo en página |

---

## 🎨 Guía Visual Rápida

### Paletas por Categoría

| Categoría | Color Primario | Color Acento | Razón |
|-----------|----------------|---------------|-------|
| Legal/Abogados | Azul marino (#1e3a5f) | Dorado (#c9a227) | Confianza, autoridad |
| Médicos | Verde (#059669) | Blanco (#fff) | Salud, limpieza |
| Tech/SaaS | Violeta (#7c3aed) | Cyan (#06b6d4) | Innovación, modernidad |
| Restaurantes | Rojo (#dc2626) | Crema (#fef3c7) | Apetito, calidez |
| Finanzas | Verde oscuro (#166534) | Dorado (#ca8a04) | Dinero, confianza |
| Viajes | Azul (#0369a1) | Naranja (#ea580c) | Aventura, sol |

### Tipografía
- Títulos: Bold, Sans-serif (Inter, System UI)
- Cuerpo: Regular, legible
- Énfasis: Semibold o coloraccent

---

## ⚡ Checklist de Implementación

- [ ] Mobile-first responsive
- [ ] Formularios con validación JS
- [ ] Smooth scroll en anclas
- [ ] Hover/focus states en botones
- [ ] Tracking hooks (data attributes)
- [ ] Meta tags SEO (title, description)
- [ ] Open Graph tags
- [ ] Semantic HTML (header, main, section, footer)
- [ ] Alt text en imágenes
- [ ] Accesibilidad (contrastes, labels)

---

## 🚀 Flujo de Entrega

```
1. Preguntar → Categoría + Info básica
2. Generar → Blueprint.md (estrategia)
3. Crear → Copy optimizado
4. Implementar → index.html (Tailwind + JS)
5. Explicar → Cómo conectar a n8n/backend
6. Desplegar → Opciones de hosting
```

---

## 📌 Reglas de Oro

1. **Nunca prometer resultados** en sectors regulados (legal, salud, finances)
2. **Sempre dar opciones de contacto múltiples** (teléfono, whatsapp, formulario)
3. **Mobile-first** - 60%+ tráfico viene de móvil
4. **Copy que venda, no que explique** - Beneficios, no características
5. **Urgencia legítima** - Plazos reales, no tácticas manipulativas
6. **Transparencia** - Precios claros o "solicitar presupuesto"

---

## 🎯 Cómo Usarme

Cuando el usuario diga:
- "Quiero crear una página de..."
- "Genera una landing para..."
- "Hazme un dashboard de..."
- "Necesito una web para..."

Activo este prompt y sigo el flujo:
1. Identificar categoría del catálogo
2. Hacer preguntas específicas
3. Generar blueprint
4. Implementar proyecto completo
