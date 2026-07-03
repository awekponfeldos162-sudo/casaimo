const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');
const jwt = require('jsonwebtoken');

admin.initializeApp();
setGlobalOptions({ region: 'europe-west1' });

const db = admin.firestore();

// In production: store this in Firebase Secret Manager via --set-secrets
const JWT_SECRET = process.env.JWT_SECRET || 'casaimo-qr-secret-2025';

// ─── createBooking ────────────────────────────────────────────────────────────
// Called by guest after selecting dates. Simulates payment and creates booking
// with status pending_approval. Sends in-app notification to host.
exports.createBooking = onCall({ enforceAppCheck: false }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Non authentifié');

  const { listingId, checkIn, checkOut, guests } = request.data;
  if (!listingId || !checkIn || !checkOut || !guests) {
    throw new HttpsError('invalid-argument', 'Données manquantes');
  }

  const listingDoc = await db.collection('listings').doc(listingId).get();
  if (!listingDoc.exists) throw new HttpsError('not-found', 'Bien introuvable');
  const listing = listingDoc.data();

  const userDoc = await db.collection('users').doc(uid).get();
  const user = userDoc.exists ? userDoc.data() : {};

  const checkInDate = new Date(checkIn);
  const checkOutDate = new Date(checkOut);
  const nights = Math.round((checkOutDate - checkInDate) / 86400000);
  if (nights < 1) throw new HttpsError('invalid-argument', 'Dates invalides');

  const pricePerNight = listing.pricePerNight || 0;
  const cleaningFee = listing.cleaningFee || 0;
  const serviceFeePercent = listing.serviceFeePercent || 0.05;
  const sub = pricePerNight * nights;
  const svc = Math.round(sub * serviceFeePercent);
  const total = sub + cleaningFee + svc;

  const bookingRef = db.collection('bookings').doc();
  await bookingRef.set({
    listingId,
    listingTitle: listing.title || '',
    listingImage: (listing.mediaUrls || [])[0] || '',
    guestId: uid,
    guestName: user.name || '',
    guestAvatar: user.avatarUrl || '',
    hostId: listing.hostId || '',
    checkIn: admin.firestore.Timestamp.fromDate(checkInDate),
    checkOut: admin.firestore.Timestamp.fromDate(checkOutDate),
    guests,
    pricePerNight,
    cleaningFee,
    serviceFee: svc,
    total,
    status: 'pending_approval',
    qrToken: null,
    rejectionReason: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Notify host
  await db.collection('notifications').add({
    userId: listing.hostId,
    type: 'new_booking',
    title: 'Nouvelle demande de réservation',
    body: `${user.name || 'Un voyageur'} souhaite réserver "${listing.title}"`,
    bookingId: bookingRef.id,
    listingId,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { bookingId: bookingRef.id };
});

// ─── approveBooking ───────────────────────────────────────────────────────────
// Called by host to approve a pending booking.
// Generates a signed JWT → stored as qrToken in the booking document.
exports.approveBooking = onCall({ enforceAppCheck: false }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Non authentifié');

  const { bookingId } = request.data;
  if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId manquant');

  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingDoc = await bookingRef.get();
  if (!bookingDoc.exists) throw new HttpsError('not-found', 'Réservation introuvable');

  const booking = bookingDoc.data();
  if (booking.hostId !== uid) throw new HttpsError('permission-denied', 'Non autorisé');
  if (booking.status !== 'pending_approval') {
    throw new HttpsError('failed-precondition', `Statut actuel: ${booking.status}`);
  }

  const checkOutDate = booking.checkOut.toDate();
  const expiry = new Date(checkOutDate);
  expiry.setDate(expiry.getDate() + 1);
  const expiresIn = Math.max(3600, Math.floor((expiry - Date.now()) / 1000));

  const payload = {
    bookingId,
    guestId: booking.guestId,
    listingId: booking.listingId,
    checkIn: booking.checkIn.toDate().toISOString(),
    checkOut: checkOutDate.toISOString(),
  };
  const qrToken = jwt.sign(payload, JWT_SECRET, { expiresIn });

  await bookingRef.update({
    status: 'confirmed',
    qrToken,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await db.collection('notifications').add({
    userId: booking.guestId,
    type: 'booking_confirmed',
    title: '✅ Réservation confirmée !',
    body: `Votre réservation pour "${booking.listingTitle}" a été acceptée. Votre ticket QR est prêt.`,
    bookingId,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

// ─── rejectBooking ────────────────────────────────────────────────────────────
// Called by host to reject a pending booking.
exports.rejectBooking = onCall({ enforceAppCheck: false }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Non authentifié');

  const { bookingId, reason } = request.data;
  if (!bookingId) throw new HttpsError('invalid-argument', 'bookingId manquant');

  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingDoc = await bookingRef.get();
  if (!bookingDoc.exists) throw new HttpsError('not-found', 'Réservation introuvable');

  const booking = bookingDoc.data();
  if (booking.hostId !== uid) throw new HttpsError('permission-denied', 'Non autorisé');
  if (booking.status !== 'pending_approval') {
    throw new HttpsError('failed-precondition', `Statut actuel: ${booking.status}`);
  }

  await bookingRef.update({
    status: 'rejected',
    rejectionReason: reason || 'Aucune raison fournie',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await db.collection('notifications').add({
    userId: booking.guestId,
    type: 'booking_rejected',
    title: 'Réservation refusée',
    body: `Votre réservation pour "${booking.listingTitle}" n'a pas pu être acceptée.`,
    bookingId,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

// ─── verifyCheckIn ────────────────────────────────────────────────────────────
// Called by host when scanning a guest's QR code.
// Verifies the JWT signature and marks the booking as checked_in.
exports.verifyCheckIn = onCall({ enforceAppCheck: false }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Non authentifié');

  const { qrToken } = request.data;
  if (!qrToken) throw new HttpsError('invalid-argument', 'Token QR manquant');

  let payload;
  try {
    payload = jwt.verify(qrToken, JWT_SECRET);
  } catch (e) {
    if (e.name === 'TokenExpiredError') {
      throw new HttpsError('invalid-argument', 'QR code expiré');
    }
    throw new HttpsError('invalid-argument', 'QR code invalide');
  }

  const { bookingId } = payload;
  const bookingRef = db.collection('bookings').doc(bookingId);
  const bookingDoc = await bookingRef.get();
  if (!bookingDoc.exists) throw new HttpsError('not-found', 'Réservation introuvable');

  const booking = bookingDoc.data();
  if (booking.hostId !== uid) {
    throw new HttpsError('permission-denied', 'Ce QR code ne vous appartient pas');
  }
  if (booking.status === 'checked_in') {
    throw new HttpsError('already-exists', 'Voyageur déjà enregistré');
  }
  if (booking.status !== 'confirmed') {
    throw new HttpsError('failed-precondition', `Statut invalide: ${booking.status}`);
  }

  await bookingRef.update({
    status: 'checked_in',
    checkedInAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    guestName: booking.guestName,
    guestAvatar: booking.guestAvatar,
    listingTitle: booking.listingTitle,
    checkIn: booking.checkIn.toDate().toISOString(),
    checkOut: booking.checkOut.toDate().toISOString(),
    guests: booking.guests,
    total: booking.total,
  };
});
