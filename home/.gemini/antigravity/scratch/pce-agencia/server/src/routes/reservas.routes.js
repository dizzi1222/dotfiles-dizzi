const express = require('express');
const Reserva = require('../models/Reserva.model');
const { verificarToken } = require('../middleware/auth.middleware');

const router = express.Router();

/**
 * GET /api/reservas
 * Lista todas las reservas con populate de referencias.
 */
router.get('/', verificarToken, async (req, res) => {
  try {
    const reservas = await Reserva.find()
      .populate('cliente', 'nombre')
      .populate('empleado', 'nombre email')
      .populate('itinerario', 'titulo');
    res.json(reservas);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener reservas.', error: error.message });
  }
});

/**
 * GET /api/reservas/:id
 * Obtiene una reserva por ID.
 */
router.get('/:id', verificarToken, async (req, res) => {
  try {
    const reserva = await Reserva.findById(req.params.id)
      .populate('cliente', 'nombre telefono')
      .populate('empleado', 'nombre email')
      .populate('itinerario')
      .populate('servicios.proveedor', 'nombre tipo');
    if (!reserva) {
      return res.status(404).json({ message: 'Reserva no encontrada.' });
    }
    res.json(reserva);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener reserva.', error: error.message });
  }
});

/**
 * POST /api/reservas
 * Crea una nueva reserva.
 */
router.post('/', verificarToken, async (req, res) => {
  try {
    const reserva = await Reserva.create({ ...req.body, empleado: req.usuario.id });
    res.status(201).json(reserva);
  } catch (error) {
    res.status(500).json({ message: 'Error al crear reserva.', error: error.message });
  }
});

/**
 * PUT /api/reservas/:id
 * Actualiza una reserva existente.
 */
router.put('/:id', verificarToken, async (req, res) => {
  try {
    const reserva = await Reserva.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!reserva) {
      return res.status(404).json({ message: 'Reserva no encontrada.' });
    }
    res.json(reserva);
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar reserva.', error: error.message });
  }
});

/**
 * DELETE /api/reservas/:id
 * Elimina una reserva.
 */
router.delete('/:id', verificarToken, async (req, res) => {
  try {
    const reserva = await Reserva.findByIdAndDelete(req.params.id);
    if (!reserva) {
      return res.status(404).json({ message: 'Reserva no encontrada.' });
    }
    res.json({ message: 'Reserva eliminada correctamente.' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar reserva.', error: error.message });
  }
});

module.exports = router;
