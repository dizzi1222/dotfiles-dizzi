const mongoose = require('mongoose');

/**
 * Esquema de factura con items detallados y referencia a PDF.
 * @type {mongoose.Schema}
 */
const facturaSchema = new mongoose.Schema(
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
    numero: {
      type: String,
      unique: true,
      required: [true, 'El número de factura es obligatorio'],
    },
    items: [
      {
        descripcion: { type: String, required: true },
        cantidad: { type: Number, default: 1 },
        precioUnitario: { type: Number, required: true },
        subtotal: { type: Number, required: true },
      },
    ],
    total: {
      type: Number,
      required: true,
    },
    estado: {
      type: String,
      enum: ['pendiente', 'pagada', 'cancelada'],
      default: 'pendiente',
    },
    urlPDF: {
      type: String,
      default: '',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Factura', facturaSchema);
