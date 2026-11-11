/**
 * Limpieza de tokens FCM inválidos o desregistrados en Firestore.
 */

const CODIGOS_TOKEN_INVALIDO = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
  'messaging/invalid-argument',
]);

/**
 * Procesa la respuesta de sendEachForMulticast y borra tokens caducados o inválidos en Firestore.
 * No imprime tokens completos en consola por seguridad.
 *
 * @param {object} response
 * @param {Array<{ uid: string, token: string }>} destinatarios
 * @param {object} db Instancia de Firestore Admin
 * @returns {Promise<number>} Cantidad de tokens limpiados
 */
async function procesarTokensInvalidos(response, destinatarios, db) {
  if (!response || !Array.isArray(response.responses) || !Array.isArray(destinatarios)) {
    return 0;
  }

  let limpiados = 0;
  const operaciones = [];

  response.responses.forEach((res, index) => {
    if (!res.success && res.error) {
      const code = res.error.code;
      const destinatario = destinatarios[index];
      if (destinatario && CODIGOS_TOKEN_INVALIDO.has(code)) {
        console.warn(`[FCM] Token no registrado o inválido para usuario ${destinatario.uid} (${code}). Limpiando en Firestore...`);
        limpiados++;
        operaciones.push(
          db.collection('usuarios').doc(destinatario.uid).update({
            fcmToken: null,
          }).catch((err) => {
            console.error(`[FCM] Error al limpiar token de usuario ${destinatario.uid}:`, err.message);
          })
        );
      } else if (!res.success) {
        console.warn(`[FCM] Error no fatal al entregar notificación a usuario ${destinatario?.uid}: ${code}`);
      }
    }
  });

  if (operaciones.length > 0) {
    await Promise.all(operaciones);
  }

  return limpiados;
}

module.exports = {
  CODIGOS_TOKEN_INVALIDO,
  procesarTokensInvalidos,
};
