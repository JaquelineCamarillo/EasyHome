/**
 * Lógica pura para resolver destinatarios de notificaciones FCM en EasyHome.
 */

/**
 * Resuelve los destinatarios para la notificación de un nuevo producto agregado.
 * Excluye al autor que agregó el producto y a quienes no tengan fcmToken.
 *
 * @param {Array<{ uid: string, hogarId?: string, fcmToken?: string }>} usuariosHogar
 * @param {string} agregadoPor
 * @returns {Array<{ uid: string, token: string }>}
 */
function filtrarDestinatariosProducto(usuariosHogar, agregadoPor) {
  if (!Array.isArray(usuariosHogar)) return [];

  return usuariosHogar
    .filter((u) => {
      if (!u || !u.uid) return false;
      if (u.uid === agregadoPor) return false; // No notificar al autor
      if (!u.fcmToken || typeof u.fcmToken !== 'string' || u.fcmToken.trim() === '') {
        return false;
      }
      return true;
    })
    .map((u) => ({
      uid: u.uid,
      token: u.fcmToken.trim(),
    }));
}

/**
 * Resuelve el destinatario para un nuevo quehacer asignado.
 * Notifica únicamente al integrante asignado si es diferente a quien lo creó
 * y cuenta con fcmToken.
 *
 * @param {{ uid: string, fcmToken?: string } | null} usuarioAsignado
 * @param {string} creadoPor
 * @returns {{ uid: string, token: string } | null}
 */
function resolverDestinatarioQuehacer(usuarioAsignado, creadoPor) {
  if (!usuarioAsignado || !usuarioAsignado.uid) return null;
  if (usuarioAsignado.uid === creadoPor) return null; // No auto-notificar
  if (
    !usuarioAsignado.fcmToken ||
    typeof usuarioAsignado.fcmToken !== 'string' ||
    usuarioAsignado.fcmToken.trim() === ''
  ) {
    return null;
  }

  return {
    uid: usuarioAsignado.uid,
    token: usuarioAsignado.fcmToken.trim(),
  };
}

module.exports = {
  filtrarDestinatariosProducto,
  resolverDestinatarioQuehacer,
};
