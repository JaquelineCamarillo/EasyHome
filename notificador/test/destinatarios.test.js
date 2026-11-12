const {
  filtrarDestinatariosProducto,
  resolverDestinatarioQuehacer,
} = require('../src/destinatarios');

describe('notificador/src/destinatarios.js (#21)', () => {
  describe('filtrarDestinatariosProducto', () => {
    const integrantes = [
      { uid: 'user_1', fcmToken: 'token_1' },
      { uid: 'user_2', fcmToken: 'token_2' },
      { uid: 'user_3', fcmToken: null },
      { uid: 'user_4', fcmToken: '' },
    ];

    test('excluye al autor que agregó el producto', () => {
      const destinatarios = filtrarDestinatariosProducto(integrantes, 'user_1');
      expect(destinatarios).toHaveLength(1);
      expect(destinatarios[0].uid).toBe('user_2');
      expect(destinatarios[0].token).toBe('token_2');
    });

    test('no incluye usuarios sin token ni con token vacío', () => {
      const destinatarios = filtrarDestinatariosProducto(integrantes, 'user_2');
      expect(destinatarios).toHaveLength(1);
      expect(destinatarios[0].uid).toBe('user_1');
    });

    test('hogar sin otros integrantes devuelve array vacío', () => {
      const soloUno = [{ uid: 'user_1', fcmToken: 'tok1' }];
      expect(filtrarDestinatariosProducto(soloUno, 'user_1')).toEqual([]);
    });

    test('tolera entradas nulas o listas vacías sin fallar', () => {
      expect(filtrarDestinatariosProducto(null, 'u1')).toEqual([]);
      expect(filtrarDestinatariosProducto(undefined, 'u1')).toEqual([]);
      expect(filtrarDestinatariosProducto([], 'u1')).toEqual([]);
    });
  });

  describe('resolverDestinatarioQuehacer', () => {
    test('notifica únicamente al integrante asignado si es distinto del creador', () => {
      const asignado = { uid: 'u_hijo', fcmToken: 'token_hijo' };
      const resultado = resolverDestinatarioQuehacer(asignado, 'u_mama');
      expect(resultado).toEqual({
        uid: 'u_hijo',
        token: 'token_hijo',
      });
    });

    test('si asignado == creador, no se auto-notifica (devuelve null)', () => {
      const creadorYAsignado = { uid: 'u_mama', fcmToken: 'token_mama' };
      expect(resolverDestinatarioQuehacer(creadorYAsignado, 'u_mama')).toBeNull();
    });

    test('si el asignado no tiene token registrado, devuelve null', () => {
      expect(resolverDestinatarioQuehacer({ uid: 'u2', fcmToken: null }, 'u1')).toBeNull();
      expect(resolverDestinatarioQuehacer({ uid: 'u2', fcmToken: '   ' }, 'u1')).toBeNull();
    });

    test('tolera asignado nulo o indefinido', () => {
      expect(resolverDestinatarioQuehacer(null, 'u1')).toBeNull();
      expect(resolverDestinatarioQuehacer(undefined, 'u1')).toBeNull();
    });
  });
});
