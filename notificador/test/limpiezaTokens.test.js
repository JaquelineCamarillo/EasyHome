const { procesarTokensInvalidos, CODIGOS_TOKEN_INVALIDO } = require('../src/limpiezaTokens');

describe('notificador/src/limpiezaTokens.js (#21)', () => {
  test('incluye códigos de FCM de token caducado o no registrado', () => {
    expect(CODIGOS_TOKEN_INVALIDO.has('messaging/registration-token-not-registered')).toBe(true);
    expect(CODIGOS_TOKEN_INVALIDO.has('messaging/invalid-registration-token')).toBe(true);
  });

  test('limpia en Firestore el fcmToken cuando FCM reporta fallo por token no registrado', async () => {
    const updateMock = jest.fn().mockResolvedValue({});
    const dbMock = {
      collection: jest.fn().mockReturnValue({
        doc: jest.fn().mockReturnValue({
          update: updateMock,
        }),
      }),
    };

    const destinatarios = [
      { uid: 'u1', token: 'tok_ok' },
      { uid: 'u2', token: 'tok_invalido' },
    ];

    const responseFCM = {
      responses: [
        { success: true },
        {
          success: false,
          error: { code: 'messaging/registration-token-not-registered' },
        },
      ],
    };

    const limpiados = await procesarTokensInvalidos(responseFCM, destinatarios, dbMock);
    expect(limpiados).toBe(1);
    expect(dbMock.collection).toHaveBeenCalledWith('usuarios');
    expect(updateMock).toHaveBeenCalledWith({ fcmToken: null });
  });

  test('no altera Firestore si todos los envíos fueron exitosos', async () => {
    const updateMock = jest.fn();
    const dbMock = {
      collection: jest.fn().mockReturnValue({
        doc: jest.fn().mockReturnValue({ update: updateMock }),
      }),
    };

    const destinatarios = [{ uid: 'u1', token: 'tok_valido' }];
    const responseFCM = { responses: [{ success: true }] };

    const limpiados = await procesarTokensInvalidos(responseFCM, destinatarios, dbMock);
    expect(limpiados).toBe(0);
    expect(updateMock).not.toHaveBeenCalled();
  });
});
