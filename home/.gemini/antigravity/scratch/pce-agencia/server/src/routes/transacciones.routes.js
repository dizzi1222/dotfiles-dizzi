const express = require('express');
const Transaccion = require('../models/Transaccion.model');
const { verificarToken } = require('../middleware/auth.middleware');

const router = express.Router();

/**
 * GET /api/transacciones
 * Lista todas las transacciones.
 */
router.get('/', verificarToken, async (req, res) => {
  try {
    const transacciones = await Transaccion.find()
      .populate('reserva', 'estadoGeneral')
      .populate('cliente', 'nombre');
    res.json(transacciones);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener transacciones.', error: error.message });
  }
});

/**
 * GET /api/transacciones/:id
 * Obtiene una transacción por ID.
 */
router.get('/:id', verificarToken, async (req, res) => {
  try {
    const transaccion = await Transaccion.findById(req.params.id)
      .populate('reserva')
      .populate('cliente', 'nombre');
    if (!transaccion) {
      return res.status(404).json({ message: 'Transacción no encontrada.' });
    }
    res.json(transaccion);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener transacción.', error: error.message });
  }
});

/**
 * POST /api/transacciones
 * Crea una nueva transacción.
 */
router.post('/', verificarToken, async (req, res) => {
  try {
    const transaccion = await Transaccion.create(req.body);
    res.status(201).json(transaccion);
  } catch (error) {
    res.status(500).json({ message: 'Error al crear transacción.', error: error.message });
  }
});

/**
 * PUT /api/transacciones/:id
 * Actualiza una transacción existente.
 */
router.put('/:id', verificarToken, async (req, res) => {
  try {
    const transaccion = await Transaccion.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!transaccion) {
      return res.status(404).json({ message: 'Transacción no encontrada.' });
    }
    res.json(transaccion);
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar transacción.', error: error.message });
  }
});

/**
 * DELETE /api/transacciones/:id
 * Elimina una transacción.
 */
router.delete('/:id', verificarToken, async (req, res) => {
  try {
    const transaccion = await Transaccion.findByIdAndDelete(req.params.id);
    if (!transaccion) {
      return res.status(404).json({ message: 'Transacción no encontrada.' });
    }
    res.json({ message: 'Transacción eliminada correctamente.' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar transacción.', error: error.message });
  }
});

module.exports = router;
