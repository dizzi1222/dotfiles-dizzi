const mongoose = require('mongoose');

/**
 * Esquema de cliente vinculado a un usuario del sistema.
 * @type {mongoose.Schema}
 */
const clienteSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    nombre: {
      type: String,
      required: [true, 'El nombre del cliente es obligatorio'],
      trim: true,
    },
    telefono: {
      type: String,
      trim: true,
    },
    direccion: {
      type: String,
      trim: true,
    },
    preferenciasViaje: {
      type: [String],
      default: [],
    },
    historialViajes: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Reserva',
      },
    ],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Cliente', clienteSchema);
