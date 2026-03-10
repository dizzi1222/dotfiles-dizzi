const mongoose = require("mongoose");

/**
 * Conecta a MongoDB. Usa mongodb-memory-server si MONGO_URI contiene "localhost"
 * y la conexión falla, o si USE_MEMORY_DB está habilitado.
 * @returns {Promise<void>}
 */
const connectDB = async () => {
  const useMemory = process.env.USE_MEMORY_DB === 'true';

  if (useMemory) {
    try {
      const { MongoMemoryServer } = require('mongodb-memory-server');
      const mongod = await MongoMemoryServer.create();
      const uri = mongod.getUri();
      await mongoose.connect(uri);
      console.log(`✅ MongoDB en memoria conectado: ${uri}`);
      return;
    } catch (error) {
      console.error(`❌ Error al iniciar MongoDB en memoria: ${error.message}`);
      process.exit(1);
    }
  }

  try {
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log(`✅ MongoDB conectado: ${conn.connection.host}`);
  } catch (error) {
    console.log('⚠️  MongoDB local no disponible, intentando con MongoDB en memoria...');
    try {
      const { MongoMemoryServer } = require('mongodb-memory-server');
      const mongod = await MongoMemoryServer.create();
      const uri = mongod.getUri();
      await mongoose.connect(uri);
      console.log(`✅ MongoDB en memoria conectado (fallback): ${uri}`);
    } catch (memError) {
      console.error(`❌ Error de conexión a MongoDB: ${error.message}`);
      console.error(`❌ Tampoco se pudo iniciar MongoDB en memoria: ${memError.message}`);
      process.exit(1);
    }
  }
};

module.exports = connectDB;
