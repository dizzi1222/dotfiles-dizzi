const mongoose = require('mongoose');

/**
 * Esquema de proveedor de servicios turísticos.
 * @type {mongoose.Schema}
 */
const proveedorSchema = new mongoose.Schema(
  {
    nombre: {
      type: String,
      required: [true, 'El nombre del proveedor es obligatorio'],
      trim: true,
    },
    tipo: {
      type: String,
      enum: ['aerolinea', 'hotel', 'turismo', 'otro'],
      required: true,
    },
    contacto: {
      nombre: { type: String, trim: true },
      telefono: { type: String, trim: true },
      email: { type: String, trim: true, lowercase: true },
    },
    contrato: {
      type: String,
      default: '',
    },
    catalogo: [
      {
        servicio: { type: String, required: true },
        tarifa: { type: Number, required: true },
        moneda: { type: String, default: 'USD' },
      },
    ],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Proveedor', proveedorSchema);
