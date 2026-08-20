const mongoose = require('mongoose');

/**
 * Esquema de transacción financiera vinculada a una reserva.
 * @type {mongoose.Schema}
 */
const transaccionSchema = new mongoose.Schema(
  {
    reserva: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Reserva',
      required: true,
    },
    cliente: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Cliente',
      required: true,
    },
    monto: {
      type: Number,
      required: [true, 'El monto es obligatorio'],
    },
    tipo: {
      type: String,
      enum: ['pago', 'reembolso', 'pago_proveedor'],
      required: true,
    },
    metodo: {
      type: String,
      enum: ['efectivo', 'tarjeta', 'transferencia'],
      required: true,
    },
    descripcion: {
      type: String,
      default: '',
    },
    fecha: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Transaccion', transaccionSchema);
