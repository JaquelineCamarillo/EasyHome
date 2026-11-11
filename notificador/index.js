/**
 * Notificador local para EasyHome (#21 - Push FCM sin Blaze / sin Cloud Functions).
 * Escucha cambios en tiempo real en Firestore y envía notificaciones FCM con Firebase Admin.
 */

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const { filtrarDestinatariosProducto, resolverDestinatarioQuehacer } = require('./src/destinatarios');
const { construirMensajeProducto, construirMensajeQuehacer } = require('./src/mensajes');
const { procesarTokensInvalidos } = require('./src/limpiezaTokens');

// 1. Carga de credenciales de cuenta de servicio
function inicializarFirebase() {
  const rutaDefaultKey = path.join(__dirname, 'serviceAccountKey.json');
  const rutaEnvKey = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const rutaFinal = rutaEnvKey || (fs.existsSync(rutaDefaultKey) ? rutaDefaultKey : null);

  if (!rutaFinal || !fs.existsSync(rutaFinal)) {
    console.error('\n❌ ERROR: No se encontró la llave de cuenta de servicio para Firebase Admin.');
    console.error('Para correr el notificador local de EasyHome necesitas:');
    console.error('1. Ir a la Consola de Firebase: https://console.firebase.google.com/project/easyhome-6ef93/settings/serviceaccounts/adminsdk');
    console.error('2. Hacer clic en "Generar nueva clave privada" y descargar el archivo JSON.');
    console.error('3. Renombrarlo a "serviceAccountKey.json" y colocarlo en la carpeta "notificador/"');
    console.error('   (o definir la variable de entorno GOOGLE_APPLICATION_CREDENTIALS con la ruta al archivo).');
    console.error('\n⚠️  IMPORTANTE: Este archivo contiene secretos y está ignorado en .gitignore. JAMÁS lo subas a GitHub.\n');
    process.exit(1);
  }

  const serviceAccount = JSON.parse(fs.readFileSync(rutaFinal, 'utf8'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id || 'easyhome-6ef93',
  });

  console.log(`✅ Firebase Admin inicializado exitosamente con el proyecto: ${serviceAccount.project_id || 'easyhome-6ef93'}`);
}

inicializarFirebase();

const db = admin.firestore();
const horaArranque = new Date();
const procesados = new Set();

console.log(`🕒 Notificador arrancado a las ${horaArranque.toISOString()}`);
console.log('📡 Escuchando colecciones "productos" y "quehaceres" en tiempo real...');
console.log('💡 Presiona Ctrl+C para detener el proceso cuando termines las pruebas.\n');

// 2. Escuchar colección "productos"
let primeraCargaProductos = true;
const unsubProductos = db.collection('productos').onSnapshot(
  async (snapshot) => {
    if (primeraCargaProductos) {
      // Ignorar documentos existentes antes del arranque
      snapshot.docs.forEach((d) => procesados.add(`prod_${d.id}`));
      primeraCargaProductos = false;
      console.log(`📦 Carga inicial de productos ignorada (${snapshot.size} productos existentes).`);
      return;
    }

    for (const change of snapshot.docChanges()) {
      if (change.type === 'added') {
        const id = change.doc.id;
        const clave = `prod_${id}`;
        if (procesados.has(clave)) continue;
        procesados.add(clave);

        const data = change.doc.data();
        if (!data) continue;

        // Validar si fue creado después del arranque
        const fechaCreacion = data.fechaCreacion?.toDate ? data.fechaCreacion.toDate() : null;
        if (fechaCreacion && fechaCreacion < horaArranque) {
          continue;
        }

        try {
          await manejarNuevoProducto(id, data);
        } catch (err) {
          console.error(`[Error producto ${id}]:`, err.message);
        }
      }
    }
  },
  (error) => {
    console.error('❌ Error en escucha de productos:', error.message);
  }
);

// 3. Escuchar colección "quehaceres"
let primeraCargaQuehaceres = true;
const unsubQuehaceres = db.collection('quehaceres').onSnapshot(
  async (snapshot) => {
    if (primeraCargaQuehaceres) {
      snapshot.docs.forEach((d) => procesados.add(`que_${d.id}`));
      primeraCargaQuehaceres = false;
      console.log(`📋 Carga inicial de quehaceres ignorada (${snapshot.size} quehaceres existentes).`);
      return;
    }

    for (const change of snapshot.docChanges()) {
      if (change.type === 'added') {
        const id = change.doc.id;
        const clave = `que_${id}`;
        if (procesados.has(clave)) continue;
        procesados.add(clave);

        const data = change.doc.data();
        if (!data) continue;

        try {
          await manejarNuevoQuehacer(id, data);
        } catch (err) {
          console.error(`[Error quehacer ${id}]:`, err.message);
        }
      }
    }
  },
  (error) => {
    console.error('❌ Error en escucha de quehaceres:', error.message);
  }
);

async function manejarNuevoProducto(id, data) {
  const { hogarId, nombre, agregadoPor } = data;
  if (!hogarId || !nombre) {
    console.log(`[Producto ${id}] Incompleto, omitiendo notificación.`);
    return;
  }

  // Resolver nombre del autor
  let nombreAutor = 'Alguien';
  if (agregadoPor) {
    try {
      const autorDoc = await db.collection('usuarios').doc(agregadoPor).get();
      if (autorDoc.exists && autorDoc.data()?.nombre) {
        nombreAutor = autorDoc.data().nombre;
      }
    } catch (_) {}
  }

  // Buscar integrantes del hogar
  const integrantesSnap = await db
    .collection('usuarios')
    .where('hogarId', '==', hogarId)
    .get();

  const usuarios = integrantesSnap.docs.map((doc) => ({
    uid: doc.id,
    ...doc.data(),
  }));

  const destinatarios = filtrarDestinatariosProducto(usuarios, agregadoPor);
  if (destinatarios.length === 0) {
    console.log(`[Producto ${id}] No hay otros integrantes con fcmToken en el hogar ${hogarId}.`);
    return;
  }

  const tokens = destinatarios.map((d) => d.token);
  const mensaje = construirMensajeProducto({
    nombreAutor,
    nombreProducto: nombre,
    tokens,
  });

  if (!mensaje) return;

  const respuesta = await admin.messaging().sendEachForMulticast(mensaje);
  console.log(
    `🔔 [Producto notificado] "${nombre}" por ${nombreAutor} -> Éxito: ${respuesta.successCount}, Fallos: ${respuesta.failureCount}`
  );

  if (respuesta.failureCount > 0) {
    await procesarTokensInvalidos(respuesta, destinatarios, db);
  }
}

async function manejarNuevoQuehacer(id, data) {
  const { titulo, asignadoA, creadoPor, fechaLimite } = data;
  if (!titulo || !asignadoA) {
    console.log(`[Quehacer ${id}] Incompleto, omitiendo.`);
    return;
  }

  if (asignadoA === creadoPor) {
    console.log(`[Quehacer ${id}] Asignado al propio creador (${creadoPor}), no se notifica.`);
    return;
  }

  const usuarioDoc = await db.collection('usuarios').doc(asignadoA).get();
  if (!usuarioDoc.exists) {
    console.warn(`[Quehacer ${id}] Integrante asignado ${asignadoA} no existe en Firestore.`);
    return;
  }

  const destinatario = resolverDestinatarioQuehacer(
    { uid: usuarioDoc.id, ...usuarioDoc.data() },
    creadoPor
  );

  if (!destinatario) {
    console.log(`[Quehacer ${id}] Integrante ${asignadoA} no tiene token FCM registrado.`);
    return;
  }

  let fechaLimiteTexto = null;
  if (fechaLimite) {
    try {
      const fecha = fechaLimite.toDate ? fechaLimite.toDate() : new Date(fechaLimite);
      if (!isNaN(fecha.getTime())) {
        fechaLimiteTexto = fecha.toISOString().split('T')[0];
      }
    } catch (_) {}
  }

  const mensaje = construirMensajeQuehacer({
    titulo,
    fechaLimiteTexto,
    token: destinatario.token,
  });

  if (!mensaje) return;

  const respuesta = await admin.messaging().sendEachForMulticast(mensaje);
  console.log(
    `🔔 [Quehacer notificado] "${titulo}" asignado a ${asignadoA} -> Éxito: ${respuesta.successCount}, Fallos: ${respuesta.failureCount}`
  );

  if (respuesta.failureCount > 0) {
    await procesarTokensInvalidos(respuesta, [destinatario], db);
  }
}

// Cierre limpio al recibir señales del sistema
function cerrar() {
  console.log('\n🛑 Deteniendo notificador local de EasyHome...');
  try {
    unsubProductos();
    unsubQuehaceres();
  } catch (_) {}
  console.log('👋 Notificador detenido. ¡Hasta pronto!');
  process.exit(0);
}

process.on('SIGINT', cerrar);
process.on('SIGTERM', cerrar);
