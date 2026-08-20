const mongoose = require('mongoose');

/**
 * Esquema de itinerario con actividades geolocalizadas.
 * @type {mongoose.Schema}
 */
const itinerarioSchema = new mongoose.Schema(
  {
    titulo: {
      type: String,
      required: [true, 'El título es obligatorio'],
      trim: true,
    },
    descripcion: {
      type: String,
      default: '',
    },
    creadoPor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    actividades: [
      {
        nombre: { type: String, required: true },
        lugar: { type: String },
        coordenadas: {
          lat: { type: Number },
          lng: { type: Number },
        },
        hora: { type: String },
        notas: { type: String, default: '' },
      },
    ],
    duracionDias: {
      type: Number,
      default: 1,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Itinerario', itinerarioSchema);
