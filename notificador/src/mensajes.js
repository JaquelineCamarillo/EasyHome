/**
 * Construcción y formato determinista de mensajes FCM para EasyHome.
 */

/**
 * Construye el mensaje multicast para notificación de nuevo producto.
 * @param {{ nombreAutor: string, nombreProducto: string, tokens: string[] }} params
 * @returns {object | null}
 */
function construirMensajeProducto({ nombreAutor, nombreProducto, tokens }) {
  if (!tokens || !Array.isArray(tokens) || tokens.length === 0) return null;

  const autor = nombreAutor && nombreAutor.trim() ? nombreAutor.trim() : 'Alguien';
  const producto = nombreProducto && nombreProducto.trim() ? nombreProducto.trim() : 'un producto';

  return {
    tokens,
    notification: {
      title: 'Nuevo producto en la lista',
      body: `${autor} agregó ${producto}`,
    },
    data: {
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      seccion: 'compras',
      tipo: 'producto_nuevo',
    },
  };
}

/**
 * Construye el mensaje multicast para notificación de nuevo quehacer asignado.
 * @param {{ titulo: string, fechaLimiteTexto?: string | null, token: string }} params
 * @returns {object | null}
 */
function construirMensajeQuehacer({ titulo, fechaLimiteTexto, token }) {
  if (!token || typeof token !== 'string' || token.trim() === '') return null;

  const tituloLimpio = titulo && titulo.trim() ? titulo.trim() : 'Quehacer asignado';
  let cuerpo = tituloLimpio;
  if (fechaLimiteTexto && typeof fechaLimiteTexto === 'string' && fechaLimiteTexto.trim() !== '') {
    cuerpo += ` (Fecha límite: ${fechaLimiteTexto.trim()})`;
  }

  return {
    tokens: [token.trim()],
    notification: {
      title: 'Te asignaron un quehacer',
      body: cuerpo,
    },
    data: {
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      seccion: 'quehaceres',
      tipo: 'quehacer_nuevo',
    },
  };
}

module.exports = {
  construirMensajeProducto,
  construirMensajeQuehacer,
};
