require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');

// Importar rutas
const authRoutes = require('./routes/auth.routes');
const clientesRoutes = require('./routes/clientes.routes');
const proveedoresRoutes = require('./routes/proveedores.routes');
const itinerariosRoutes = require('./routes/itinerarios.routes');
const reservasRoutes = require('./routes/reservas.routes');
const transaccionesRoutes = require('./routes/transacciones.routes');
const facturasRoutes = require('./routes/facturas.routes');

const app = express();
const PORT = process.env.PORT || 4000;

// Middlewares globales
app.use(cors());
app.use(express.json());

// Rutas
app.use('/api/auth', authRoutes);
app.use('/api/clientes', clientesRoutes);
app.use('/api/proveedores', proveedoresRoutes);
app.use('/api/itinerarios', itinerariosRoutes);
app.use('/api/reservas', reservasRoutes);
app.use('/api/transacciones', transaccionesRoutes);
app.use('/api/facturas', facturasRoutes);

// Ruta raíz
app.get('/', (req, res) => {
  res.json({ message: 'API PCE-Agencia activa 🚀' });
});

// Manejo de errores global
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Error interno del servidor', error: err.message });
});

// Conectar a DB y levantar servidor
connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
  });
});
