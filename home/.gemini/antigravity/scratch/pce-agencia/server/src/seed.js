const bcrypt = require('bcryptjs');
const User = require('./models/User.model');
const Cliente = require('./models/Cliente.model');
const Proveedor = require('./models/Proveedor.model');
const Itinerario = require('./models/Itinerario.model');
const Reserva = require('./models/Reserva.model');
const Transaccion = require('./models/Transaccion.model');
const Factura = require('./models/Factura.model');

/**
 * Inserta datos de demostración en la base de datos.
 * Solo ejecuta si la colección de usuarios está vacía.
 * @returns {Promise<void>}
 */
const seedData = async () => {
  const userCount = await User.countDocuments();
  if (userCount > 0) {
    console.log('📦 La DB ya tiene datos, omitiendo seed.');
    return;
  }

  console.log('🌱 Insertando datos de demostración...');

  const salt = await bcrypt.genSalt(10);
  const hashedPassword = await bcrypt.hash('admin123', salt);

  // Usuarios
  const admin = await User.create({
    nombre: 'Admin PCE',
    email: 'admin@pce.com',
    password: hashedPassword,
    rol: 'admin',
  });

  const empleado1 = await User.create({
    nombre: 'María García',
    email: 'maria@pce.com',
    password: hashedPassword,
    rol: 'empleado',
  });

  const empleado2 = await User.create({
    nombre: 'Carlos López',
    email: 'carlos@pce.com',
    password: hashedPassword,
    rol: 'empleado',
  });

  // Clientes
  const cliente1 = await Cliente.create({
    user: admin._id,
    nombre: 'Ana Martínez',
    telefono: '+58 412-555-0101',
    direccion: 'Av. Libertador, Caracas',
    preferenciasViaje: ['playa', 'aventura', 'gastronomía'],
  });

  const cliente2 = await Cliente.create({
    nombre: 'Roberto Fernández',
    telefono: '+58 414-555-0202',
    direccion: 'Calle 10, Maracaibo',
    preferenciasViaje: ['montaña', 'cultura'],
  });

  const cliente3 = await Cliente.create({
    nombre: 'Lucía Rodríguez',
    telefono: '+58 424-555-0303',
    direccion: 'Av. Las Americas, Mérida',
    preferenciasViaje: ['relax', 'spa', 'playa'],
  });

  const cliente4 = await Cliente.create({
    nombre: 'Pedro Hernández',
    telefono: '+58 416-555-0404',
    direccion: 'Calle Principal, Valencia',
    preferenciasViaje: ['turismo urbano', 'compras'],
  });

  // Proveedores
  const proveedor1 = await Proveedor.create({
    nombre: 'AeroCaribe Airlines',
    tipo: 'aerolinea',
    contacto: {
      nombre: 'José Ramírez',
      telefono: '+58 212-555-1001',
      email: 'ventas@aerocaribe.com',
    },
    contrato: 'Contrato vigente hasta 2027',
    catalogo: [
      { servicio: 'Vuelo Caracas → Cancún', tarifa: 450, moneda: 'USD' },
      { servicio: 'Vuelo Caracas → Miami', tarifa: 380, moneda: 'USD' },
      { servicio: 'Vuelo Caracas → Bogotá', tarifa: 220, moneda: 'USD' },
    ],
  });

  const proveedor2 = await Proveedor.create({
    nombre: 'Hotel Playa Azul',
    tipo: 'hotel',
    contacto: {
      nombre: 'Laura Mendoza',
      telefono: '+52 998-555-2002',
      email: 'reservas@playaazul.com',
    },
    contrato: 'Tarifa preferencial temporada baja',
    catalogo: [
      { servicio: 'Suite Vista al Mar (por noche)', tarifa: 180, moneda: 'USD' },
      { servicio: 'Habitación Estándar (por noche)', tarifa: 95, moneda: 'USD' },
      { servicio: 'Paquete All-Inclusive (por noche)', tarifa: 250, moneda: 'USD' },
    ],
  });

  const proveedor3 = await Proveedor.create({
    nombre: 'Caribe Adventures',
    tipo: 'turismo',
    contacto: {
      nombre: 'Miguel Torres',
      telefono: '+52 998-555-3003',
      email: 'info@caribeadventures.com',
    },
    catalogo: [
      { servicio: 'Tour Chichén Itzá', tarifa: 75, moneda: 'USD' },
      { servicio: 'Snorkeling Isla Mujeres', tarifa: 60, moneda: 'USD' },
      { servicio: 'Cenote Excursión', tarifa: 45, moneda: 'USD' },
    ],
  });

  // Itinerarios
  const itinerario1 = await Itinerario.create({
    titulo: 'Escapada Cancún 5 Días',
    descripcion: 'Paquete completo de playa y aventura en la Riviera Maya',
    creadoPor: empleado1._id,
    duracionDias: 5,
    actividades: [
      { nombre: 'Llegada y Check-in', lugar: 'Aeropuerto Cancún', coordenadas: { lat: 21.0365, lng: -86.8770 }, hora: '14:00', notas: 'Transfer incluido' },
      { nombre: 'Día de Playa', lugar: 'Playa Delfines', coordenadas: { lat: 21.0779, lng: -86.7833 }, hora: '10:00', notas: 'Toallas y sombrilla incluidas' },
      { nombre: 'Tour Chichén Itzá', lugar: 'Chichén Itzá', coordenadas: { lat: 20.6843, lng: -88.5677 }, hora: '07:00', notas: 'Incluye almuerzo buffet' },
      { nombre: 'Snorkeling', lugar: 'Isla Mujeres', coordenadas: { lat: 21.2320, lng: -86.7310 }, hora: '09:00', notas: 'Equipo proporcionado' },
      { nombre: 'Día libre y Salida', lugar: 'Hotel Playa Azul', coordenadas: { lat: 21.1333, lng: -86.7500 }, hora: '12:00', notas: 'Checkout a las 12:00' },
    ],
  });

  const itinerario2 = await Itinerario.create({
    titulo: 'Miami Shopping Weekend',
    descripcion: 'Fin de semana de compras y entretenimiento en Miami',
    creadoPor: empleado2._id,
    duracionDias: 3,
    actividades: [
      { nombre: 'Llegada a Miami', lugar: 'Aeropuerto MIA', coordenadas: { lat: 25.7959, lng: -80.2870 }, hora: '11:00' },
      { nombre: 'Sawgrass Mills Outlet', lugar: 'Sunrise, FL', coordenadas: { lat: 26.1510, lng: -80.3229 }, hora: '10:00' },
      { nombre: 'South Beach Walk', lugar: 'Miami Beach', coordenadas: { lat: 25.7826, lng: -80.1341 }, hora: '17:00' },
    ],
  });

  // Reservas
  const reserva1 = await Reserva.create({
    cliente: cliente1._id,
    empleado: empleado1._id,
    itinerario: itinerario1._id,
    servicios: [
      { proveedor: proveedor1._id, tipo: 'vuelo', fechaInicio: new Date('2026-04-15'), fechaFin: new Date('2026-04-15'), precio: 450, estado: 'confirmado' },
      { proveedor: proveedor2._id, tipo: 'hotel', fechaInicio: new Date('2026-04-15'), fechaFin: new Date('2026-04-20'), precio: 900, estado: 'confirmado' },
      { proveedor: proveedor3._id, tipo: 'actividad', fechaInicio: new Date('2026-04-17'), fechaFin: new Date('2026-04-17'), precio: 75, estado: 'confirmado' },
    ],
    estadoGeneral: 'activa',
  });

  const reserva2 = await Reserva.create({
    cliente: cliente2._id,
    empleado: empleado2._id,
    itinerario: itinerario2._id,
    servicios: [
      { proveedor: proveedor1._id, tipo: 'vuelo', fechaInicio: new Date('2026-05-01'), fechaFin: new Date('2026-05-01'), precio: 380, estado: 'pendiente' },
    ],
    estadoGeneral: 'activa',
  });

  const reserva3 = await Reserva.create({
    cliente: cliente3._id,
    empleado: empleado1._id,
    itinerario: itinerario1._id,
    servicios: [
      { proveedor: proveedor1._id, tipo: 'vuelo', fechaInicio: new Date('2026-03-10'), fechaFin: new Date('2026-03-10'), precio: 450, estado: 'confirmado' },
      { proveedor: proveedor2._id, tipo: 'hotel', fechaInicio: new Date('2026-03-10'), fechaFin: new Date('2026-03-15'), precio: 1250, estado: 'confirmado' },
    ],
    estadoGeneral: 'completada',
  });

  // Transacciones
  await Transaccion.create({
    reserva: reserva1._id,
    cliente: cliente1._id,
    monto: 1425,
    tipo: 'pago',
    metodo: 'tarjeta',
    descripcion: 'Pago total paquete Cancún',
  });

  await Transaccion.create({
    reserva: reserva2._id,
    cliente: cliente2._id,
    monto: 190,
    tipo: 'pago',
    metodo: 'transferencia',
    descripcion: 'Adelanto 50% vuelo Miami',
  });

  await Transaccion.create({
    reserva: reserva3._id,
    cliente: cliente3._id,
    monto: 1700,
    tipo: 'pago',
    metodo: 'tarjeta',
    descripcion: 'Pago total paquete Cancún Premium',
  });

  await Transaccion.create({
    reserva: reserva1._id,
    cliente: cliente1._id,
    monto: 525,
    tipo: 'pago_proveedor',
    metodo: 'transferencia',
    descripcion: 'Pago a AeroCaribe - Vuelo CCS-CUN',
  });

  // Facturas
  await Factura.create({
    reserva: reserva1._id,
    cliente: cliente1._id,
    numero: 'FAC-2026-0001',
    items: [
      { descripcion: 'Vuelo Caracas → Cancún', cantidad: 1, precioUnitario: 450, subtotal: 450 },
      { descripcion: 'Hotel Playa Azul (5 noches)', cantidad: 5, precioUnitario: 180, subtotal: 900 },
      { descripcion: 'Tour Chichén Itzá', cantidad: 1, precioUnitario: 75, subtotal: 75 },
    ],
    total: 1425,
    estado: 'pagada',
  });

  await Factura.create({
    reserva: reserva2._id,
    cliente: cliente2._id,
    numero: 'FAC-2026-0002',
    items: [
      { descripcion: 'Vuelo Caracas → Miami', cantidad: 1, precioUnitario: 380, subtotal: 380 },
    ],
    total: 380,
    estado: 'pendiente',
  });

  await Factura.create({
    reserva: reserva3._id,
    cliente: cliente3._id,
    numero: 'FAC-2026-0003',
    items: [
      { descripcion: 'Vuelo Caracas → Cancún', cantidad: 1, precioUnitario: 450, subtotal: 450 },
      { descripcion: 'Hotel Playa Azul All-Inclusive (5 noches)', cantidad: 5, precioUnitario: 250, subtotal: 1250 },
    ],
    total: 1700,
    estado: 'pagada',
  });

  // Actualizar historial de viajes de clientes
  await Cliente.findByIdAndUpdate(cliente1._id, { $push: { historialViajes: reserva1._id } });
  await Cliente.findByIdAndUpdate(cliente2._id, { $push: { historialViajes: reserva2._id } });
  await Cliente.findByIdAndUpdate(cliente3._id, { $push: { historialViajes: reserva3._id } });

  console.log('✅ Datos de demostración insertados correctamente.');
  console.log('   📧 Login: admin@pce.com / admin123');
};

module.exports = seedData;
