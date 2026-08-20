const express = require('express');
const Itinerario = require('../models/Itinerario.model');
const { verificarToken } = require('../middleware/auth.middleware');

const router = express.Router();

/**
 * GET /api/itinerarios
 * Lista todos los itinerarios.
 */
router.get('/', verificarToken, async (req, res) => {
  try {
    const itinerarios = await Itinerario.find().populate('creadoPor', 'nombre email');
    res.json(itinerarios);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener itinerarios.', error: error.message });
  }
});

/**
 * GET /api/itinerarios/:id
 * Obtiene un itinerario por ID.
 */
router.get('/:id', verificarToken, async (req, res) => {
  try {
    const itinerario = await Itinerario.findById(req.params.id).populate('creadoPor', 'nombre email');
    if (!itinerario) {
      return res.status(404).json({ message: 'Itinerario no encontrado.' });
    }
    res.json(itinerario);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener itinerario.', error: error.message });
  }
});

/**
 * POST /api/itinerarios
 * Crea un nuevo itinerario.
 */
router.post('/', verificarToken, async (req, res) => {
  try {
    const itinerario = await Itinerario.create({ ...req.body, creadoPor: req.usuario.id });
    res.status(201).json(itinerario);
  } catch (error) {
    res.status(500).json({ message: 'Error al crear itinerario.', error: error.message });
  }
});

/**
 * PUT /api/itinerarios/:id
 * Actualiza un itinerario existente.
 */
router.put('/:id', verificarToken, async (req, res) => {
  try {
    const itinerario = await Itinerario.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!itinerario) {
      return res.status(404).json({ message: 'Itinerario no encontrado.' });
    }
    res.json(itinerario);
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar itinerario.', error: error.message });
  }
});

/**
 * DELETE /api/itinerarios/:id
 * Elimina un itinerario.
 */
router.delete('/:id', verificarToken, async (req, res) => {
  try {
    const itinerario = await Itinerario.findByIdAndDelete(req.params.id);
    if (!itinerario) {
      return res.status(404).json({ message: 'Itinerario no encontrado.' });
    }
    res.json({ message: 'Itinerario eliminado correctamente.' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar itinerario.', error: error.message });
  }
});

module.exports = router;
