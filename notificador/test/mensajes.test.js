const {
  construirMensajeProducto,
  construirMensajeQuehacer,
} = require('../src/mensajes');

describe('notificador/src/mensajes.js (#21)', () => {
  describe('construirMensajeProducto', () => {
    test('título "Nuevo producto en la lista" y cuerpo "<autor> agregó <producto>"', () => {
      const msg = construirMensajeProducto({
        nombreAutor: 'Jaqueline',
        nombreProducto: 'Detergente líquido',
        tokens: ['t1', 't2'],
      });

      expect(msg).not.toBeNull();
      expect(msg.tokens).toEqual(['t1', 't2']);
      expect(msg.notification.title).toBe('Nuevo producto en la lista');
      expect(msg.notification.body).toBe('Jaqueline agregó Detergente líquido');
      expect(msg.data.seccion).toBe('compras');
      expect(msg.data.tipo).toBe('producto_nuevo');
      expect(msg.data.click_action).toBe('FLUTTER_NOTIFICATION_CLICK');
    });

    test('usa texto por defecto si falta autor o producto', () => {
      const msg = construirMensajeProducto({
        nombreAutor: '',
        nombreProducto: null,
        tokens: ['t1'],
      });

      expect(msg.notification.body).toBe('Alguien agregó un producto');
    });

    test('devuelve null si no hay tokens', () => {
      expect(
        construirMensajeProducto({
          nombreAutor: 'Jaqueline',
          nombreProducto: 'Pan',
          tokens: [],
        })
      ).toBeNull();
    });
  });

  describe('construirMensajeQuehacer', () => {
    test('título "Te asignaron un quehacer" y cuerpo "<titulo>"', () => {
      const msg = construirMensajeQuehacer({
        titulo: 'Limpiar la cocina',
        fechaLimiteTexto: null,
        token: 'tok123',
      });

      expect(msg).not.toBeNull();
      expect(msg.tokens).toEqual(['tok123']);
      expect(msg.notification.title).toBe('Te asignaron un quehacer');
      expect(msg.notification.body).toBe('Limpiar la cocina');
      expect(msg.data.seccion).toBe('quehaceres');
      expect(msg.data.tipo).toBe('quehacer_nuevo');
    });

    test('agrega fecha límite al cuerpo si está presente', () => {
      const msg = construirMensajeQuehacer({
        titulo: 'Tirar la basura',
        fechaLimiteTexto: '2026-11-20',
        token: 'tok123',
      });

      expect(msg.notification.body).toBe('Tirar la basura (Fecha límite: 2026-11-20)');
    });

    test('devuelve null si el token es inválido o vacío', () => {
      expect(
        construirMensajeQuehacer({
          titulo: 'Pasear al perro',
          token: '   ',
        })
      ).toBeNull();
    });
  });
});
