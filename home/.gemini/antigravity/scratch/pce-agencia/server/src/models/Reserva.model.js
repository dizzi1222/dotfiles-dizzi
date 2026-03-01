const mongoose = require('mongoose');

/**
 * Esquema de reserva — entidad pivote del sistema.
 * @type {mongoose.Schema}
 */
const reservaSchema = new mongoose.Schema(
  {
    cliente: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Cliente',
      required: true,
    },
    empleado: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    itinerario: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Itinerario',
    },
    servicios: [
      {
        proveedor: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'Proveedor',
        },
        tipo: {
          type: String,
          enum: ['vuelo', 'hotel', 'actividad', 'otro'],
        },
        fechaInicio: { type: Date },
        fechaFin: { type: Date },
        precio: { type: Number, default: 0 },
        estado: {
          type: String,
          enum: ['pendiente', 'confirmado', 'cancelado'],
          default: 'pendiente',
        },
      },
    ],
    estadoGeneral: {
      type: String,
      enum: ['activa', 'completada', 'cancelada'],
      default: 'activa',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Reserva', reservaSchema);
