const jwt = require('jsonwebtoken');

/**
 * Middleware para verificar token JWT.
 * Extrae el token del header Authorization (Bearer <token>).
 * @param {import('express').Request} req
 * @param {import('express').Response} res
 * @param {import('express').NextFunction} next
 */
const verificarToken = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Acceso denegado. Token no proporcionado.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.usuario = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Token inválido o expirado.' });
  }
};

/**
 * Middleware para verificar que el usuario tenga un rol permitido.
 * @param  {...string} roles - Roles permitidos
 * @returns {import('express').RequestHandler}
 */
const verificarRol = (...roles) => {
  return (req, res, next) => {
    if (!req.usuario || !roles.includes(req.usuario.rol)) {
      return res.status(403).json({ message: 'No tienes permisos para esta acción.' });
    }
    next();
  };
};

module.exports = { verificarToken, verificarRol };
