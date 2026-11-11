const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'easyhome-seguridad-test';

jest.setTimeout(30000);

describe('Reglas de Seguridad Firestore EasyHome (#22)', () => {
  let testEnv;

  beforeAll(async () => {
    const rules = fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8');
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: rules,
      },
    });
  }, 30000);

  afterAll(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  }, 30000);

  beforeEach(async () => {
    if (testEnv) {
      await testEnv.clearFirestore();
    }
  }, 15000);

  // --- SECCIÓN 1: Control de Acceso y Peticiones No Autenticadas ---
  describe('Acceso no autenticado y regla catch-all', () => {
    test('rechaza lectura no autenticada en cualquier colección', async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      await assertFails(db.collection('usuarios').doc('u1').get());
      await assertFails(db.collection('hogares').doc('h1').get());
      await assertFails(db.collection('productos').doc('p1').get());
      await assertFails(db.collection('quehaceres').doc('q1').get());
    });

    test('rechaza escritura no autenticada en cualquier colección', async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      await assertFails(db.collection('usuarios').doc('u1').set({ nombre: 'X' }));
      await assertFails(db.collection('hogares').doc('h1').set({ nombre: 'X' }));
      await assertFails(db.collection('productos').doc('p1').set({ nombre: 'X' }));
    });

    test('regla catch-all bloquea colecciones no declaradas', async () => {
      const authDb = testEnv.authenticatedContext('userA').firestore();
      await assertFails(authDb.collection('secretos').doc('s1').get());
      await assertFails(authDb.collection('secretos').doc('s1').set({ dato: 'confidencial' }));
      await assertFails(authDb.collection('logs_sistema').doc('l1').get());
    });

    test('codigosInvitacion no puede listarse', async () => {
      const authDb = testEnv.authenticatedContext('userA').firestore();
      await assertFails(authDb.collection('codigosInvitacion').get());
    });
  });

  // --- SECCIÓN 2: Usuarios y Elevación de Privilegios ---
  describe('Colección usuarios (RBAC y perfil)', () => {
    test('un usuario solo puede crear su propio documento con rol no-admin y sin hogar', async () => {
      const authDb = testEnv.authenticatedContext('userA').firestore();
      // Correcto: perfil base
      await assertSucceeds(
        authDb.collection('usuarios').doc('userA').set({
          nombre: 'Ana Torres',
          esAdministrador: false,
          hogarId: null,
        })
      );

      // Falla: intentar crearse como administrador directamente
      const authDbMal = testEnv.authenticatedContext('userMal').firestore();
      await assertFails(
        authDbMal.collection('usuarios').doc('userMal').set({
          nombre: 'Hacker',
          esAdministrador: true,
          hogarId: null,
        })
      );

      // Falla: crear documento para otro uid
      await assertFails(
        authDb.collection('usuarios').doc('otroUser').set({
          nombre: 'Impostor',
          esAdministrador: false,
          hogarId: null,
        })
      );
    });

    test('un usuario común NO puede auto-promoverse a administrador', async () => {
      // Fixture: usuario en hogar como miembro común
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('usuarios').doc('userComun').set({
          nombre: 'Carlos',
          esAdministrador: false,
          hogarId: 'hogar1',
        });
      });

      const authDb = testEnv.authenticatedContext('userComun').firestore();
      await assertFails(
        authDb.collection('usuarios').doc('userComun').update({
          esAdministrador: true,
        })
      );
    });

    test('un usuario puede actualizar su fcmToken sin alterar otros campos', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('usuarios').doc('userA').set({
          nombre: 'Ana',
          esAdministrador: false,
          hogarId: 'hogar1',
          fcmToken: 'token_viejo',
        });
      });

      const authDb = testEnv.authenticatedContext('userA').firestore();
      await assertSucceeds(
        authDb.collection('usuarios').doc('userA').update({
          fcmToken: 'token_nuevo_fcm_12345',
        })
      );
    });

    test('un usuario puede actualizar su perfil básico (nombre, avatarColor, fcmToken)', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('usuarios').doc('userA').set({
          nombre: 'Ana',
          avatarColor: '0xFF234E3F',
          esAdministrador: false,
          hogarId: 'hogar1',
        });
      });

      const authDb = testEnv.authenticatedContext('userA').firestore();
      await assertSucceeds(
        authDb.collection('usuarios').doc('userA').update({
          nombre: 'Ana Sofía',
          avatarColor: '0xFF1E88E5',
        })
      );
    });
  });

  // --- SECCIÓN 3: Hogares y Códigos ---
  describe('Colección hogares', () => {
    test('crear hogar exige creadoPor igual al auth.uid, nombre válido y código de 6 caracteres', async () => {
      const authDb = testEnv.authenticatedContext('creador1').firestore();

      // Éxito: datos correctos
      await assertSucceeds(
        authDb.collection('hogares').doc('hogarNuevo').set({
          nombre: 'Mi Casa',
          creadoPor: 'creador1',
          codigoInvitacion: 'A3F9K2',
        })
      );

      // Falla: creadoPor ajeno
      await assertFails(
        authDb.collection('hogares').doc('hogarInvalido1').set({
          nombre: 'Mi Casa',
          creadoPor: 'otroUsuario',
          codigoInvitacion: 'A3F9K2',
        })
      );

      // Falla: nombre demasiado largo (> 30 chars)
      await assertFails(
        authDb.collection('hogares').doc('hogarInvalido2').set({
          nombre: 'A'.repeat(35),
          creadoPor: 'creador1',
          codigoInvitacion: 'A3F9K2',
        })
      );

      // Falla: código inválido (longitud diferente a 6)
      await assertFails(
        authDb.collection('hogares').doc('hogarInvalido3').set({
          nombre: 'Mi Casa',
          creadoPor: 'creador1',
          codigoInvitacion: 'CORTO',
        })
      );
    });

    test('integrante del hogar puede leer su hogar pero un usuario ajeno no', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('hogares').doc('hogar1').set({
          nombre: 'Casa 1',
          creadoPor: 'admin1',
          codigoInvitacion: 'AAA111',
        });
        await adminDb.collection('usuarios').doc('miembro1').set({
          nombre: 'Miembro',
          hogarId: 'hogar1',
          esAdministrador: false,
        });
        await adminDb.collection('usuarios').doc('ajeno1').set({
          nombre: 'Ajeno',
          hogarId: 'hogar2',
          esAdministrador: false,
        });
      });

      const dbMiembro = testEnv.authenticatedContext('miembro1').firestore();
      await assertSucceeds(dbMiembro.collection('hogares').doc('hogar1').get());

      const dbAjeno = testEnv.authenticatedContext('ajeno1').firestore();
      await assertFails(dbAjeno.collection('hogares').doc('hogar1').get());
    });
  });

  // --- SECCIÓN 4: Productos y Validación de Entrada ---
  describe('Colección productos (aislamiento y validaciones)', () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('usuarios').doc('userHogar1').set({
          nombre: 'Ana',
          hogarId: 'hogar1',
          esAdministrador: false,
        });
        await adminDb.collection('usuarios').doc('userHogar2').set({
          nombre: 'Beto',
          hogarId: 'hogar2',
          esAdministrador: false,
        });
      });
    });

    test('integrante crea producto con campos válidos', async () => {
      const db = testEnv.authenticatedContext('userHogar1').firestore();
      await assertSucceeds(
        db.collection('productos').doc('prod1').set({
          hogarId: 'hogar1',
          agregadoPor: 'userHogar1',
          nombre: 'Leche deslactosada',
          cantidad: 2,
          comprado: false,
          fechaCreacion: new Date().toISOString(),
        })
      );
    });

    test('rechaza producto con cantidad menor o igual a 0', async () => {
      const db = testEnv.authenticatedContext('userHogar1').firestore();
      await assertFails(
        db.collection('productos').doc('prodInvalidoCant').set({
          hogarId: 'hogar1',
          agregadoPor: 'userHogar1',
          nombre: 'Pan',
          cantidad: 0,
          comprado: false,
          fechaCreacion: new Date().toISOString(),
        })
      );
    });

    test('rechaza producto con nombre menor a 2 caracteres', async () => {
      const db = testEnv.authenticatedContext('userHogar1').firestore();
      await assertFails(
        db.collection('productos').doc('prodInvalidoNom').set({
          hogarId: 'hogar1',
          agregadoPor: 'userHogar1',
          nombre: 'X',
          cantidad: 1,
          comprado: false,
          fechaCreacion: new Date().toISOString(),
        })
      );
    });

    test('rechaza producto con campos adicionales no permitidos (hasOnly)', async () => {
      const db = testEnv.authenticatedContext('userHogar1').firestore();
      await assertFails(
        db.collection('productos').doc('prodExtra').set({
          hogarId: 'hogar1',
          agregadoPor: 'userHogar1',
          nombre: 'Manzanas',
          cantidad: 5,
          comprado: false,
          fechaCreacion: new Date().toISOString(),
          campoInyectado: 'malicioso',
        })
      );
    });

    test('aislamiento cruzado: usuario de hogar 2 no puede leer ni modificar productos de hogar 1', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('productos').doc('prodHogar1').set({
          hogarId: 'hogar1',
          agregadoPor: 'userHogar1',
          nombre: 'Huevos',
          cantidad: 12,
          comprado: false,
        });
      });

      const dbAjeno = testEnv.authenticatedContext('userHogar2').firestore();
      await assertFails(dbAjeno.collection('productos').doc('prodHogar1').get());
      await assertFails(
        dbAjeno.collection('productos').doc('prodHogar1').update({ comprado: true })
      );
      await assertFails(dbAjeno.collection('productos').doc('prodHogar1').delete());
    });
  });

  // --- SECCIÓN 5: Quehaceres y Roles (Admin vs Responsable) ---
  describe('Colección quehaceres', () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const adminDb = context.firestore();
        await adminDb.collection('usuarios').doc('adminH1').set({
          nombre: 'Admin Hogar 1',
          hogarId: 'hogar1',
          esAdministrador: true,
        });
        await adminDb.collection('usuarios').doc('miembroH1').set({
          nombre: 'Miembro Hogar 1',
          hogarId: 'hogar1',
          esAdministrador: false,
        });
        await adminDb.collection('usuarios').doc('ajenoH2').set({
          nombre: 'Ajeno Hogar 2',
          hogarId: 'hogar2',
          esAdministrador: true,
        });
      });
    });

    test('solo el administrador del hogar puede crear quehaceres', async () => {
      const dbAdmin = testEnv.authenticatedContext('adminH1').firestore();
      const dbMiembro = testEnv.authenticatedContext('miembroH1').firestore();

      // Admin crea con éxito
      await assertSucceeds(
        dbAdmin.collection('quehaceres').doc('q1').set({
          hogarId: 'hogar1',
          creadoPor: 'adminH1',
          asignadoA: 'miembroH1',
          titulo: 'Lavar la loza',
          hecho: false,
          fechaLimite: null,
          recurrente: true,
        })
      );

      // Miembro no admin falla
      await assertFails(
        dbMiembro.collection('quehaceres').doc('q2').set({
          hogarId: 'hogar1',
          creadoPor: 'miembroH1',
          asignadoA: 'miembroH1',
          titulo: 'Pasear al perro',
          hecho: false,
          fechaLimite: null,
          recurrente: false,
        })
      );
    });

    test('rechaza quehacer con título > 120 caracteres', async () => {
      const dbAdmin = testEnv.authenticatedContext('adminH1').firestore();
      await assertFails(
        dbAdmin.collection('quehaceres').doc('qLargo').set({
          hogarId: 'hogar1',
          creadoPor: 'adminH1',
          asignadoA: 'miembroH1',
          titulo: 'T'.repeat(125),
          hecho: false,
          fechaLimite: null,
          recurrente: false,
        })
      );
    });

    test('responsable asignado solo puede marcar "hecho", no cambiar título', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('quehaceres').doc('qAsignado').set({
          hogarId: 'hogar1',
          creadoPor: 'adminH1',
          asignadoA: 'miembroH1',
          titulo: 'Barrer la sala',
          hecho: false,
          fechaLimite: null,
          recurrente: false,
        });
      });

      const dbMiembro = testEnv.authenticatedContext('miembroH1').firestore();

      // Éxito: marcar hecho
      await assertSucceeds(
        dbMiembro.collection('quehaceres').doc('qAsignado').update({
          hecho: true,
        })
      );

      // Falla: intentar alterar título
      await assertFails(
        dbMiembro.collection('quehaceres').doc('qAsignado').update({
          titulo: 'Hacer nada',
        })
      );
    });

    test('solo el administrador puede eliminar quehaceres', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('quehaceres').doc('qBorrar').set({
          hogarId: 'hogar1',
          creadoPor: 'adminH1',
          asignadoA: 'miembroH1',
          titulo: 'Sacar basura',
          hecho: false,
          fechaLimite: null,
          recurrente: false,
        });
      });

      const dbMiembro = testEnv.authenticatedContext('miembroH1').firestore();
      await assertFails(dbMiembro.collection('quehaceres').doc('qBorrar').delete());

      const dbAdmin = testEnv.authenticatedContext('adminH1').firestore();
      await assertSucceeds(dbAdmin.collection('quehaceres').doc('qBorrar').delete());
    });

    test('aislamiento cruzado en quehaceres', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('quehaceres').doc('qHogar1').set({
          hogarId: 'hogar1',
          creadoPor: 'adminH1',
          asignadoA: 'miembroH1',
          titulo: 'Limpiar baño',
          hecho: false,
          fechaLimite: null,
          recurrente: false,
        });
      });

      const dbAjeno = testEnv.authenticatedContext('ajenoH2').firestore();
      await assertFails(dbAjeno.collection('quehaceres').doc('qHogar1').get());
      await assertFails(
        dbAjeno.collection('quehaceres').doc('qHogar1').update({ hecho: true })
      );
    });
  });
});
