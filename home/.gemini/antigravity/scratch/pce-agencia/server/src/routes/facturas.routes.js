const express = require('express');
const Factura = require('../models/Factura.model');
const { verificarToken } = require('../middleware/auth.middleware');

const router = express.Router();

/**
 * GET /api/facturas
 * Lista todas las facturas.
 */
router.get('/', verificarToken, async (req, res) => {
  try {
    const facturas = await Factura.find()
      .populate('reserva', 'estadoGeneral')
      .populate('cliente', 'nombre');
    res.json(facturas);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener facturas.', error: error.message });
  }
});

/**
 * GET /api/facturas/:id
 * Obtiene una factura por ID.
 */
router.get('/:id', verificarToken, async (req, res) => {
  try {
    const factura = await Factura.findById(req.params.id)
      .populate('reserva')
      .populate('cliente', 'nombre');
    if (!factura) {
      return res.status(404).json({ message: 'Factura no encontrada.' });
    }
    res.json(factura);
  } catch (error) {
    res.status(500).json({ message: 'Error al obtener factura.', error: error.message });
  }
});

/**
 * POST /api/facturas
 * Crea una nueva factura.
 */
router.post('/', verificarToken, async (req, res) => {
  try {
    const factura = await Factura.create(req.body);
    res.status(201).json(factura);
  } catch (error) {
    res.status(500).json({ message: 'Error al crear factura.', error: error.message });
  }
});

/**
 * PUT /api/facturas/:id
 * Actualiza una factura existente.
 */
router.put('/:id', verificarToken, async (req, res) => {
  try {
    const factura = await Factura.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!factura) {
      return res.status(404).json({ message: 'Factura no encontrada.' });
    }
    res.json(factura);
  } catch (error) {
    res.status(500).json({ message: 'Error al actualizar factura.', error: error.message });
  }
});

/**
 * DELETE /api/facturas/:id
 * Elimina una factura.
 */
router.delete('/:id', verificarToken, async (req, res) => {
  try {
    const factura = await Factura.findByIdAndDelete(req.params.id);
    if (!factura) {
      return res.status(404).json({ message: 'Factura no encontrada.' });
    }
    res.json({ message: 'Factura eliminada correctamente.' });
  } catch (error) {
    res.status(500).json({ message: 'Error al eliminar factura.', error: error.message });
  }
});

module.exports = router;
