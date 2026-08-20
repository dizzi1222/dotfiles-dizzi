const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User.model');

const router = express.Router();

/**
 * POST /api/auth/register
 * Registra un nuevo usuario.
 */
router.post('/register', async (req, res) => {
  try {
    const { nombre, email, password, rol } = req.body;

    const existente = await User.findOne({ email });
    if (existente) {
      return res.status(400).json({ message: 'El email ya está registrado.' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const usuario = await User.create({
      nombre,
      email,
      password: hashedPassword,
      rol,
    });

    const token = jwt.sign(
      { id: usuario._id, rol: usuario.rol },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({ token, usuario: { id: usuario._id, nombre, email, rol: usuario.rol } });
  } catch (error) {
    res.status(500).json({ message: 'Error al registrar usuario.', error: error.message });
  }
});

/**
 * POST /api/auth/login
 * Inicia sesión y devuelve un JWT.
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const usuario = await User.findOne({ email });
    if (!usuario) {
      return res.status(400).json({ message: 'Credenciales inválidas.' });
    }

    const passwordValido = await bcrypt.compare(password, usuario.password);
    if (!passwordValido) {
      return res.status(400).json({ message: 'Credenciales inválidas.' });
    }

    const token = jwt.sign(
      { id: usuario._id, rol: usuario.rol },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({ token, usuario: { id: usuario._id, nombre: usuario.nombre, email: usuario.email, rol: usuario.rol } });
  } catch (error) {
    res.status(500).json({ message: 'Error al iniciar sesión.', error: error.message });
  }
});

module.exports = router;
