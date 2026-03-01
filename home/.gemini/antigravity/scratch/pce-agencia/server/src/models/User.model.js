const mongoose = require('mongoose');

/**
 * Esquema de usuario para autenticación y control de roles.
 * @type {mongoose.Schema}
 */
const userSchema = new mongoose.Schema(
  {
    nombre: {
      type: String,
      required: [true, 'El nombre es obligatorio'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'El email es obligatorio'],
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: [true, 'La contraseña es obligatoria'],
      minlength: 6,
    },
    rol: {
      type: String,
      enum: ['admin', 'empleado', 'cliente'],
      default: 'empleado',
    },
    activo: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
