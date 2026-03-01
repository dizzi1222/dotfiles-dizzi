const express = require('express');
const Cliente = require('../models/Cliente.model');
const { verificarToken } = require('../middleware/auth.middleware');

const router = express.Router();

/**
 * GET /api/clientes
 * Lista todos los clientes.
 */
router.get('/', verificarToken, async (req, res) => {
  try {
    const clientes = await Cliente.find().populate('user', 'nombre email');
    res.json(clientes);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener clientes.', error: error.message });
  }
});

/**
 * GET /api/clientes/:id
 * Obtiene un cliente por ID.
 */
router.get('/:id', verificarToken, async (req, res) => {
  try {
    const cliente = await Cliente.findById(req.params.id).populate('user', 'nombre email');
    if (!cliente) {
      return res.status(404).json({ message: 'Cliente no encontrado.' });
    }
    res.json(cliente);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener cliente.', error: error.message });
  }
});

/**
 * POST /api/clientes
 * Crea un nuevo cliente.
 */
router.post('/', verificarToken, async (req, res) => {
  try {
    const cliente = await Cliente.create(req.body);
    res.status(201).json(cliente);
  } catch (error) {
    res.status(500).json({ message: 'Error al crear cliente.', error: error.message });
  }
});

/**
 * PUT /api/clientes/:id
 * Actualiza un cliente existente.
 */
router.put('/:id', verificarToken, async (req, res) => {
  try {
    const cliente = await Cliente.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!cliente) {
      return res.status(404).json({ message: 'Cliente no encontrado.' });
    }
    res.json(cliente);
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar cliente.', error: error.message });
  }
});

/**
 * DELETE /api/clientes/:id
 * Elimina un cliente.
 */
router.delete('/:id', verificarToken, async (req, res) => {
  try {
    const cliente = await Cliente.findByIdAndDelete(req.params.id);
    if (!cliente) {
      return res.status(404).json({ message: 'Cliente no encontrado.' });
    }
    res.json({ message: 'Cliente eliminado correctamente.' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar cliente.', error: error.message });
  }
});

module.exports = router;
