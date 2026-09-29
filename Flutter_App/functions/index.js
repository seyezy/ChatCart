const { onValueWritten } = require('firebase-functions/v2/database');
const admin = require('firebase-admin');
admin.initializeApp();

exports.mirrorPresenceToFirestore = onValueWritten('/status/{uid}', async (event) => {
  const uid = event.params.uid;
  const value = event.data.after.val() || { state: 'offline', lastChanged: Date.now() };
  await admin.firestore().collection('users').doc(uid).set({
    isOnline: value.state === 'online',
    lastSeen: admin.firestore.Timestamp.fromMillis(Number(value.lastChanged || Date.now())),
  }, { merge: true });
});
