importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

// Configuración pública de Firebase Web para EasyHome (easyhome-6ef93)
firebase.initializeApp({
  apiKey: "AIzaSyA5s9fcSOnNT681gv5bt2fiWO6D-OFqlhI",
  appId: "1:458450223719:web:13c343508d1aa29f108ac2",
  messagingSenderId: "458450223719",
  projectId: "easyhome-6ef93",
  authDomain: "easyhome-6ef93.firebaseapp.com",
  storageBucket: "easyhome-6ef93.firebasestorage.app",
  measurementId: "G-9PVY38E608"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Mensaje push recibido en segundo plano: ', payload);
  const notificationTitle = payload.notification?.title || payload.data?.title || 'EasyHome';
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
