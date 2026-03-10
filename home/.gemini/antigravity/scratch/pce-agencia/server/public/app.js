/**
 * PCE Agencia — Dashboard Frontend Application
 * @module app
 */

const API_BASE = '/api';

/** @type {string|null} */
let authToken = null;

/** @type {object|null} */
let currentUser = null;

/** @type {string} */
let activeSection = 'overview';

// ========== UTILITY FUNCTIONS ==========

/**
 * Realiza una petición autenticada a la API.
 * @param {string} endpoint - Ruta relativa de la API
 * @param {object} [options={}] - Opciones de fetch
 * @returns {Promise<any>}
 */
const apiFetch = async (endpoint, options = {}) => {
  const headers = { 'Content-Type': 'application/json', ...options.headers };
  if (authToken) {
    headers['Authorization'] = `Bearer ${authToken}`;
  }
  const res = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ message: 'Error desconocido' }));
    throw new Error(err.message);
  }
  return res.json();
};

/**
 * Formatea un monto a formato de moneda.
 * @param {number} amount
 * @param {string} [currency='USD']
 * @returns {string}
 */
const formatCurrency = (amount, currency = 'USD') =>
  new Intl.NumberFormat('es-VE', { style: 'currency', currency }).format(amount);

/**
 * Formatea una fecha ISO a formato legible.
 * @param {string} dateStr
 * @returns {string}
 */
const formatDate = (dateStr) => {
  if (!dateStr) return '—';
  return new Intl.DateTimeFormat('es-VE', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(new Date(dateStr));
};

/**
 * Muestra una notificación toast.
 * @param {string} message
 * @param {'success'|'error'|'info'} [type='info']
 */
const showToast = (message, type = 'info') => {
  const container = document.getElementById('toast-container');
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.textContent = message;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(30px)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
};

/**
 * Genera un badge HTML según el estado.
 * @param {string} status
 * @returns {string}
 */
const badge = (status) =>
  `<span class="badge badge-${status}">${status}</span>`;

// ========== AUTH ==========

const loginForm = document.getElementById('login-form');
const loginScreen = document.getElementById('login-screen');
const dashboard = document.getElementById('dashboard');
const loginError = document.getElementById('login-error');

loginForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = document.getElementById('login-email').value.trim();
  const password = document.getElementById('login-password').value;
  const btn = document.getElementById('login-btn');

  btn.disabled = true;
  btn.querySelector('span').textContent = 'Ingresando...';
  loginError.hidden = true;

  try {
    const data = await apiFetch('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });

    authToken = data.token;
    currentUser = data.usuario;

    document.getElementById('user-name').textContent = currentUser.nombre;
    document.getElementById('user-role').textContent = currentUser.rol;
    document.getElementById('user-avatar').textContent = currentUser.nombre.charAt(0).toUpperCase();

    loginScreen.hidden = true;
    dashboard.hidden = false;

    showToast(`¡Bienvenido, ${currentUser.nombre}!`, 'success');
    loadDashboard();
  } catch (err) {
    loginError.textContent = err.message;
    loginError.hidden = false;
  } finally {
    btn.disabled = false;
    btn.querySelector('span').textContent = 'Iniciar Sesión';
  }
});

// ========== LOGOUT ==========

document.getElementById('logout-btn').addEventListener('click', () => {
  authToken = null;
  currentUser = null;
  dashboard.hidden = true;
  loginScreen.hidden = false;
  showToast('Sesión cerrada', 'info');
});

// ========== NAVIGATION ==========

const navItems = document.querySelectorAll('.nav-item');
const sectionTitles = {
  overview: 'Resumen General',
  clientes: 'Gestión de Clientes',
  reservas: 'Gestión de Reservas',
  proveedores: 'Proveedores',
  itinerarios: 'Itinerarios de Viaje',
  transacciones: 'Registro de Transacciones',
  facturas: 'Facturas',
};

/**
 * Navega a una sección del dashboard.
 * @param {string} section
 */
const navigateTo = (section) => {
  activeSection = section;

  navItems.forEach((item) => item.classList.remove('active'));
  document.querySelector(`[data-section="${section}"]`)?.classList.add('active');

  document.querySelectorAll('.section').forEach((sec) => {
    sec.hidden = true;
    sec.classList.remove('active');
  });

  const target = document.getElementById(`section-${section}`);
  if (target) {
    target.hidden = false;
    target.classList.add('active');
  }

  document.getElementById('section-title').textContent = sectionTitles[section] || section;

  // Cerrar sidebar en móvil
  document.getElementById('sidebar').classList.remove('mobile-open');
};

navItems.forEach((item) => {
  item.addEventListener('click', (e) => {
    e.preventDefault();
    const section = item.dataset.section;
    navigateTo(section);
  });
});

// Card links (Ver todas →)
document.querySelectorAll('.card-link').forEach((link) => {
  link.addEventListener('click', (e) => {
    e.preventDefault();
    navigateTo(link.dataset.goto);
  });
});

// ========== SIDEBAR TOGGLE ==========

document.getElementById('sidebar-toggle').addEventListener('click', () => {
  document.getElementById('sidebar').classList.toggle('collapsed');
});

document.getElementById('mobile-menu-btn').addEventListener('click', () => {
  document.getElementById('sidebar').classList.toggle('mobile-open');
});

// ========== DATE DISPLAY ==========

const updateDate = () => {
  const now = new Date();
  document.getElementById('topbar-date').textContent = new Intl.DateTimeFormat('es-VE', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  }).format(now);
};

updateDate();

// ========== LOAD DASHBOARD DATA ==========

/**
 * Carga todos los datos del dashboard.
 */
const loadDashboard = async () => {
  try {
    const [clientes, reservas, proveedores, itinerarios, transacciones, facturas] = await Promise.all([
      apiFetch('/clientes'),
      apiFetch('/reservas'),
      apiFetch('/proveedores'),
      apiFetch('/itinerarios'),
      apiFetch('/transacciones'),
      apiFetch('/facturas'),
    ]);

    renderStats(clientes, reservas, proveedores, transacciones, facturas);
    renderRecentReservas(reservas);
    renderRecentTransacciones(transacciones);
    renderClientes(clientes);
    renderReservas(reservas);
    renderProveedores(proveedores);
    renderItinerarios(itinerarios);
    renderTransacciones(transacciones);
    renderFacturas(facturas);

    setupSearch(clientes, reservas, proveedores, itinerarios, transacciones, facturas);
  } catch (err) {
    showToast('Error al cargar datos: ' + err.message, 'error');
  }
};

// ========== RENDER FUNCTIONS ==========

/**
 * Renderiza las tarjetas de estadísticas.
 */
const renderStats = (clientes, reservas, proveedores, transacciones, facturas) => {
  const totalIngresos = transacciones
    .filter((t) => t.tipo === 'pago')
    .reduce((sum, t) => sum + t.monto, 0);

  const reservasActivas = reservas.filter((r) => r.estadoGeneral === 'activa').length;
  const facturasPendientes = facturas.filter((f) => f.estado === 'pendiente').length;

  const stats = [
    { icon: '👥', value: clientes.length, label: 'Clientes' },
    { icon: '📅', value: reservasActivas, label: 'Reservas Activas' },
    { icon: '🏢', value: proveedores.length, label: 'Proveedores' },
    { icon: '💰', value: formatCurrency(totalIngresos), label: 'Ingresos Totales' },
    { icon: '📄', value: facturasPendientes, label: 'Facturas Pendientes' },
  ];

  document.getElementById('stats-grid').innerHTML = stats
    .map(
      (s) => `
    <div class="stat-card">
      <div class="stat-icon">${s.icon}</div>
      <div class="stat-value">${s.value}</div>
      <div class="stat-label">${s.label}</div>
    </div>
  `
    )
    .join('');
};

/**
 * Renderiza las reservas recientes en el resumen.
 */
const renderRecentReservas = (reservas) => {
  const container = document.getElementById('recent-reservas');
  if (reservas.length === 0) {
    container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">📅</div><p>No hay reservas</p></div>';
    return;
  }

  const statusIcons = { activa: '🔵', completada: '🟢', cancelada: '🔴' };

  container.innerHTML = reservas
    .slice(0, 5)
    .map(
      (r) => `
    <div class="reserva-item">
      <div class="reserva-icon ${r.estadoGeneral}">${statusIcons[r.estadoGeneral] || '⚪'}</div>
      <div class="reserva-info">
        <div class="name">${r.cliente?.nombre || 'Cliente'}</div>
        <div class="details">${r.itinerario?.titulo || 'Sin itinerario'} — ${r.servicios?.length || 0} servicios</div>
      </div>
      ${badge(r.estadoGeneral)}
    </div>
  `
    )
    .join('');
};

/**
 * Renderiza las transacciones recientes en el resumen.
 */
const renderRecentTransacciones = (transacciones) => {
  const container = document.getElementById('recent-transacciones');
  if (transacciones.length === 0) {
    container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">💰</div><p>No hay transacciones</p></div>';
    return;
  }

  const typeIcons = { pago: '💳', reembolso: '↩️', pago_proveedor: '🏢' };

  container.innerHTML = transacciones
    .slice(0, 5)
    .map(
      (t) => `
    <div class="transaction-item">
      <div class="transaction-left">
        <div class="transaction-type-icon ${t.tipo}">${typeIcons[t.tipo] || '💰'}</div>
        <span class="transaction-desc">${t.descripcion || t.tipo}</span>
      </div>
      <span class="transaction-amount ${t.tipo === 'reembolso' ? 'negative' : 'positive'}">
        ${t.tipo === 'reembolso' ? '-' : '+'}${formatCurrency(t.monto)}
      </span>
    </div>
  `
    )
    .join('');
};

/**
 * Renderiza la tabla de clientes.
 */
const renderClientes = (clientes) => {
  const tbody = document.getElementById('clientes-tbody');
  tbody.innerHTML = clientes
    .map(
      (c) => `
    <tr>
      <td><strong>${c.nombre}</strong></td>
      <td>${c.telefono || '—'}</td>
      <td>${c.direccion || '—'}</td>
      <td>${(c.preferenciasViaje || []).map((p) => `<span class="tag">${p}</span>`).join(' ') || '—'}</td>
      <td>${(c.historialViajes || []).length}</td>
    </tr>
  `
    )
    .join('');
};

/**
 * Renderiza la tabla de reservas.
 */
const renderReservas = (reservas) => {
  const tbody = document.getElementById('reservas-tbody');
  tbody.innerHTML = reservas
    .map(
      (r) => `
    <tr>
      <td><strong>${r.cliente?.nombre || '—'}</strong></td>
      <td>${r.empleado?.nombre || '—'}</td>
      <td>${r.itinerario?.titulo || '—'}</td>
      <td>${r.servicios?.length || 0} servicio(s)</td>
      <td>${badge(r.estadoGeneral)}</td>
      <td>${formatDate(r.createdAt)}</td>
    </tr>
  `
    )
    .join('');
};

/**
 * Renderiza las tarjetas de proveedores.
 */
const renderProveedores = (proveedores) => {
  const grid = document.getElementById('proveedores-grid');
  const typeIcons = { aerolinea: '✈️', hotel: '🏨', turismo: '🌴', otro: '📦' };

  grid.innerHTML = proveedores
    .map(
      (p) => `
    <div class="provider-card">
      <div class="provider-header">
        <div class="provider-icon ${p.tipo}">${typeIcons[p.tipo] || '📦'}</div>
        <div>
          <div class="provider-name">${p.nombre}</div>
          <div class="provider-type">${p.tipo}</div>
        </div>
      </div>
      ${
        p.contacto
          ? `
        <div class="provider-contact">
          ${p.contacto.nombre ? `<p>👤 ${p.contacto.nombre}</p>` : ''}
          ${p.contacto.telefono ? `<p>📞 ${p.contacto.telefono}</p>` : ''}
          ${p.contacto.email ? `<p>📧 ${p.contacto.email}</p>` : ''}
        </div>
      `
          : ''
      }
      ${
        p.catalogo && p.catalogo.length > 0
          ? `
        <div class="provider-catalog">
          <h4>Catálogo de Servicios</h4>
          ${p.catalogo
            .map(
              (c) => `
            <div class="catalog-item">
              <span class="service-name">${c.servicio}</span>
              <span class="service-price">${formatCurrency(c.tarifa, c.moneda || 'USD')}</span>
            </div>
          `
            )
            .join('')}
        </div>
      `
          : ''
      }
    </div>
  `
    )
    .join('');
};

/**
 * Renderiza los itinerarios con timeline.
 */
const renderItinerarios = (itinerarios) => {
  const list = document.getElementById('itinerarios-list');

  if (itinerarios.length === 0) {
    list.innerHTML = '<div class="empty-state"><div class="empty-state-icon">🗺️</div><p>No hay itinerarios</p></div>';
    return;
  }

  list.innerHTML = itinerarios
    .map(
      (it) => `
    <div class="itinerario-card">
      <div class="itinerario-header">
        <div>
          <div class="itinerario-title">${it.titulo}</div>
          <div class="itinerario-desc">${it.descripcion || ''}</div>
        </div>
        <div class="itinerario-meta">
          <span class="itinerario-days">🗓 ${it.duracionDias} día${it.duracionDias !== 1 ? 's' : ''}</span>
        </div>
      </div>
      <div class="activities-timeline">
        ${(it.actividades || [])
          .map(
            (a, i) => `
          <div class="activity-item">
            <div class="activity-dot">${i + 1}</div>
            <div class="activity-content">
              <h4>${a.nombre}</h4>
              <p>📍 ${a.lugar || '—'} ${a.hora ? `<span class="activity-time">⏰ ${a.hora}</span>` : ''}</p>
              ${a.notas ? `<p>💡 ${a.notas}</p>` : ''}
            </div>
          </div>
        `
          )
          .join('')}
      </div>
    </div>
  `
    )
    .join('');
};

/**
 * Renderiza la tabla de transacciones.
 */
const renderTransacciones = (transacciones) => {
  const tbody = document.getElementById('transacciones-tbody');
  const typeLabels = { pago: '💳 Pago cliente', reembolso: '↩️ Reembolso', pago_proveedor: '🏢 Pago proveedor' };

  tbody.innerHTML = transacciones
    .map(
      (t) => `
    <tr>
      <td>${formatDate(t.fecha || t.createdAt)}</td>
      <td>${badge(t.tipo)}</td>
      <td class="transaction-amount ${t.tipo === 'reembolso' ? 'negative' : 'positive'}">
        ${t.tipo === 'reembolso' ? '-' : '+'}${formatCurrency(t.monto)}
      </td>
      <td>${t.metodo}</td>
      <td>${t.descripcion || '—'}</td>
    </tr>
  `
    )
    .join('');
};

/**
 * Renderiza la tabla de facturas.
 */
const renderFacturas = (facturas) => {
  const tbody = document.getElementById('facturas-tbody');

  tbody.innerHTML = facturas
    .map(
      (f) => `
    <tr>
      <td><strong>${f.numero}</strong></td>
      <td>${f.cliente?.nombre || '—'}</td>
      <td>${f.items?.length || 0} item(s)</td>
      <td><strong>${formatCurrency(f.total)}</strong></td>
      <td>${badge(f.estado)}</td>
      <td>${formatDate(f.createdAt)}</td>
    </tr>
  `
    )
    .join('');
};

// ========== SEARCH ==========

/**
 * Configura la búsqueda global.
 */
const setupSearch = (clientes, reservas, proveedores, itinerarios, transacciones, facturas) => {
  const searchInput = document.getElementById('search-input');

  searchInput.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();

    if (!query) {
      renderClientes(clientes);
      renderReservas(reservas);
      renderProveedores(proveedores);
      renderItinerarios(itinerarios);
      renderTransacciones(transacciones);
      renderFacturas(facturas);
      return;
    }

    const filteredClientes = clientes.filter(
      (c) =>
        c.nombre?.toLowerCase().includes(query) ||
        c.telefono?.toLowerCase().includes(query) ||
        c.direccion?.toLowerCase().includes(query)
    );

    const filteredReservas = reservas.filter(
      (r) =>
        r.cliente?.nombre?.toLowerCase().includes(query) ||
        r.empleado?.nombre?.toLowerCase().includes(query) ||
        r.itinerario?.titulo?.toLowerCase().includes(query) ||
        r.estadoGeneral?.toLowerCase().includes(query)
    );

    const filteredProveedores = proveedores.filter(
      (p) =>
        p.nombre?.toLowerCase().includes(query) ||
        p.tipo?.toLowerCase().includes(query)
    );

    const filteredItinerarios = itinerarios.filter(
      (it) =>
        it.titulo?.toLowerCase().includes(query) ||
        it.descripcion?.toLowerCase().includes(query)
    );

    const filteredTransacciones = transacciones.filter(
      (t) =>
        t.descripcion?.toLowerCase().includes(query) ||
        t.tipo?.toLowerCase().includes(query) ||
        t.metodo?.toLowerCase().includes(query)
    );

    const filteredFacturas = facturas.filter(
      (f) =>
        f.numero?.toLowerCase().includes(query) ||
        f.estado?.toLowerCase().includes(query)
    );

    renderClientes(filteredClientes);
    renderReservas(filteredReservas);
    renderProveedores(filteredProveedores);
    renderItinerarios(filteredItinerarios);
    renderTransacciones(filteredTransacciones);
    renderFacturas(filteredFacturas);
  });
};

// ========== KEYBOARD SHORTCUTS ==========

document.addEventListener('keydown', (e) => {
  // Ctrl+K para buscar
  if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
    e.preventDefault();
    document.getElementById('search-input')?.focus();
  }

  // Escape para cerrar modal
  if (e.key === 'Escape') {
    const overlay = document.getElementById('modal-overlay');
    if (!overlay.hidden) {
      overlay.hidden = true;
    }
  }
});

// ========== MODAL ==========

document.getElementById('modal-close')?.addEventListener('click', () => {
  document.getElementById('modal-overlay').hidden = true;
});

document.getElementById('modal-overlay')?.addEventListener('click', (e) => {
  if (e.target === e.currentTarget) {
    e.target.hidden = true;
  }
});
