const express = require('express');
const Proveedor = require('../models/Proveedor.model');
const { verificarToken } = require('../middleware/auth.middleware');

const router = express.Router();

/**
 * GET /api/proveedores
 * Lista todos los proveedores.
 */
router.get('/', verificarToken, async (req, res) => {
  try {
    const proveedores = await Proveedor.find();
    res.json(proveedores);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener proveedores.', error: error.message });
  }
});

/**
 * GET /api/proveedores/:id
 * Obtiene un proveedor por ID.
 */
router.get('/:id', verificarToken, async (req, res) => {
  try {
    const proveedor = await Proveedor.findById(req.params.id);
    if (!proveedor) {
      return res.status(404).json({ message: 'Proveedor no encontrado.' });
    }
    res.json(proveedor);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener proveedor.', error: error.message });
  }
});

/**
 * POST /api/proveedores
 * Crea un nuevo proveedor.
 */
router.post('/', verificarToken, async (req, res) => {
  try {
    const proveedor = await Proveedor.create(req.body);
    res.status(201).json(proveedor);
  } catch (error) {
    res.status(500).json({ message: 'Error al crear proveedor.', error: error.message });
  }
});

/**
 * PUT /api/proveedores/:id
 * Actualiza un proveedor existente.
 */
router.put('/:id', verificarToken, async (req, res) => {
  try {
    const proveedor = await Proveedor.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!proveedor) {
      return res.status(404).json({ message: 'Proveedor no encontrado.' });
    }
    res.json(proveedor);
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar proveedor.', error: error.message });
  }
});

/**
 * DELETE /api/proveedores/:id
 * Elimina un proveedor.
 */
router.delete('/:id', verificarToken, async (req, res) => {
  try {
    const proveedor = await Proveedor.findByIdAndDelete(req.params.id);
    if (!proveedor) {
      return res.status(404).json({ message: 'Proveedor no encontrado.' });
    }
    res.json({ message: 'Proveedor eliminado correctamente.' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar proveedor.', error: error.message });
  }
});

module.exports = router;
