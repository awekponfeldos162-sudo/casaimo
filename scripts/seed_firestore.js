const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');

// Init with application default credentials (firebase CLI login)
initializeApp({ projectId: 'casaimo' });
const db = getFirestore();

const now = Timestamp.now();

// ─── USERS ────────────────────────────────────────────────────────
const users = [
  {
    id: 'host1',
    data: {
      email: 'host1@casaimo.com',
      name: 'Kofi Mensah',
      phone: '+22960000001',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      role: 'host',
      isVerified: true,
      favoriteIds: [],
      createdAt: now,
    },
  },
  {
    id: 'host2',
    data: {
      email: 'host2@casaimo.com',
      name: 'Aminata Diallo',
      phone: '+22890000002',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=200',
      role: 'host',
      isVerified: true,
      favoriteIds: [],
      createdAt: now,
    },
  },
  {
    id: 'host3',
    data: {
      email: 'host3@casaimo.com',
      name: 'Yao Kouassi',
      phone: '+22507000003',
      avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
      role: 'host',
      isVerified: true,
      favoriteIds: [],
      createdAt: now,
    },
  },
  {
    id: 'guest1',
    data: {
      email: 'guest1@casaimo.com',
      name: 'Marie Traoré',
      phone: '+22670000004',
      avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
      role: 'guest',
      isVerified: false,
      favoriteIds: ['listing1', 'listing3'],
      createdAt: now,
    },
  },
];

// ─── LISTINGS ─────────────────────────────────────────────────────
const listings = [
  {
    id: 'listing1',
    data: {
      hostId: 'host1',
      type: 'Villa',
      title: 'Golden Gate Cottage',
      description: 'Golden Gate Cottage est un havre de charme niché au cœur de la ville, avec un intérieur chaleureux aux poutres en bois roux. Le jardin spacieux est une oasis sereine, ornée de massifs fleuris colorés.',
      address: 'Ulitsa Lenina, 25',
      city: 'Cotonou',
      lat: 6.3703,
      lng: 2.3912,
      amenities: ['WiFi', 'Parking', 'Climatisation', 'Piscine', 'Cuisine', 'CCTV'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800',
        'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
      ],
      pricePerNight: 45000,
      cleaningFee: 5000,
      serviceFeePercent: 0.12,
      cancellationPolicy: 'flexible',
      minStay: 1,
      maxStay: 30,
      bedrooms: 3,
      bathrooms: 2,
      maxGuests: 6,
      avgRating: 4.8,
      reviewCount: 124,
      status: 'published',
      createdAt: now,
    },
  },
  {
    id: 'listing2',
    data: {
      hostId: 'host2',
      type: 'Appartement',
      title: 'Luxe 1BR Hideaway',
      description: 'Appartement moderne en plein cœur de la ville avec vue panoramique. Idéal pour les voyageurs d\'affaires et les couples.',
      address: '15 Avenue des Cocotiers',
      city: 'Lomé',
      lat: 6.1375,
      lng: 1.2123,
      amenities: ['WiFi', 'Climatisation', 'TV', 'Cuisine', 'Sécurité 24h/24'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      ],
      pricePerNight: 28000,
      cleaningFee: 3000,
      serviceFeePercent: 0.12,
      cancellationPolicy: 'moderate',
      minStay: 2,
      maxStay: 14,
      bedrooms: 1,
      bathrooms: 1,
      maxGuests: 2,
      avgRating: 4.5,
      reviewCount: 89,
      status: 'published',
      createdAt: now,
    },
  },
  {
    id: 'listing3',
    data: {
      hostId: 'host3',
      type: 'Maison',
      title: 'Villa Bali Valli',
      description: 'Magnifique maison tropicale avec piscine privée et jardin luxuriant. Parfaite pour les familles et les groupes.',
      address: '8 Rue des Palmiers',
      city: 'Abidjan',
      lat: 5.3599,
      lng: -4.0082,
      amenities: ['WiFi', 'Piscine', 'Parking', 'Cuisine', 'Climatisation', 'Terrasse'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800',
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      ],
      pricePerNight: 65000,
      cleaningFee: 8000,
      serviceFeePercent: 0.12,
      cancellationPolicy: 'strict',
      minStay: 3,
      maxStay: 21,
      bedrooms: 4,
      bathrooms: 3,
      maxGuests: 8,
      avgRating: 4.9,
      reviewCount: 56,
      status: 'published',
      createdAt: now,
    },
  },
  {
    id: 'listing4',
    data: {
      hostId: 'host1',
      type: 'Studio',
      title: 'Studio Cozy Centre-Ville',
      description: 'Studio confortable et bien équipé, idéalement situé au centre-ville. Accès facile à tous les transports.',
      address: '22 Boulevard de la Liberté',
      city: 'Dakar',
      lat: 14.6928,
      lng: -17.4467,
      amenities: ['WiFi', 'Climatisation', 'TV', 'Cuisine'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800',
      ],
      pricePerNight: 18000,
      cleaningFee: 2000,
      serviceFeePercent: 0.12,
      cancellationPolicy: 'flexible',
      minStay: 1,
      maxStay: 7,
      bedrooms: 1,
      bathrooms: 1,
      maxGuests: 2,
      avgRating: 4.3,
      reviewCount: 212,
      status: 'published',
      createdAt: now,
    },
  },
  {
    id: 'listing5',
    data: {
      hostId: 'host2',
      type: 'Hôtel',
      title: 'Elite Unit - Roof Suite',
      description: 'Suite haut de gamme avec terrasse privative et vue sur la ville. Service hôtelier 5 étoiles inclus.',
      address: "1 Place de l'Indépendance",
      city: 'Cotonou',
      lat: 6.3654,
      lng: 2.4183,
      amenities: ['WiFi', 'Piscine', 'Salle de sport', 'Parking', 'Climatisation', 'Ascenseur', 'Sécurité 24h/24'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
        'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800',
      ],
      pricePerNight: 120000,
      cleaningFee: 0,
      serviceFeePercent: 0.10,
      cancellationPolicy: 'moderate',
      minStay: 1,
      maxStay: 30,
      bedrooms: 2,
      bathrooms: 2,
      maxGuests: 4,
      avgRating: 4.9,
      reviewCount: 340,
      status: 'published',
      createdAt: now,
    },
  },
  {
    id: 'listing6',
    data: {
      hostId: 'host3',
      type: 'Appartement',
      title: 'Appart Vue Mer - Fidjrossè',
      description: 'Superbe appartement avec vue directe sur la mer. Accès plage à 50m. Cadre idéal pour un séjour relaxant en famille.',
      address: 'Boulevard de la Marina, Fidjrossè',
      city: 'Cotonou',
      lat: 6.3501,
      lng: 2.3890,
      amenities: ['WiFi', 'Climatisation', 'TV', 'Cuisine', 'Balcon', 'Vue mer'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1560185127-6a8e8a3e1a0b?w=800',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800',
      ],
      pricePerNight: 35000,
      cleaningFee: 4000,
      serviceFeePercent: 0.12,
      cancellationPolicy: 'flexible',
      minStay: 1,
      maxStay: 30,
      bedrooms: 2,
      bathrooms: 1,
      maxGuests: 4,
      avgRating: 4.7,
      reviewCount: 67,
      status: 'published',
      createdAt: now,
    },
  },
];

// ─── REVIEWS ──────────────────────────────────────────────────────
const reviews = [
  {
    id: 'review1',
    data: {
      listingId: 'listing1',
      guestId: 'guest1',
      guestName: 'Marie Traoré',
      guestAvatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
      bookingId: 'booking1',
      rating: 5,
      comment: 'Séjour parfait ! Le cottage est exactement comme sur les photos. Propriétaire très réactif. Je recommande vivement.',
      createdAt: now,
    },
  },
  {
    id: 'review2',
    data: {
      listingId: 'listing1',
      guestId: 'guest1',
      guestName: 'Jean-Pierre K.',
      guestAvatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
      bookingId: 'booking2',
      rating: 4.5,
      comment: 'Très bon rapport qualité-prix. Quartier calme et sécurisé. La piscine est un vrai plus !',
      createdAt: now,
    },
  },
  {
    id: 'review3',
    data: {
      listingId: 'listing3',
      guestId: 'guest1',
      guestName: 'Sophie L.',
      guestAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
      bookingId: 'booking3',
      rating: 5,
      comment: 'Villa magnifique, jardin tropical superbe. Nos enfants ont adoré la piscine. On reviendra !',
      createdAt: now,
    },
  },
];

// ─── SEED FUNCTION ─────────────────────────────────────────────────
async function seed() {
  console.log('🚀 Seeding Firestore for project: casaimo\n');

  // Users
  console.log('📋 Creating users...');
  for (const user of users) {
    await db.collection('users').doc(user.id).set(user.data);
    console.log(`  ✓ users/${user.id} (${user.data.name})`);
  }

  // Listings
  console.log('\n🏠 Creating listings...');
  for (const listing of listings) {
    await db.collection('listings').doc(listing.id).set(listing.data);
    console.log(`  ✓ listings/${listing.id} (${listing.data.title})`);
  }

  // Reviews
  console.log('\n⭐ Creating reviews...');
  for (const review of reviews) {
    await db.collection('reviews').doc(review.id).set(review.data);
    console.log(`  ✓ reviews/${review.id}`);
  }

  // Empty placeholder documents for bookings, messages, notifications
  console.log('\n📁 Creating empty placeholder collections...');
  await db.collection('bookings').doc('_placeholder').set({ _init: true, createdAt: now });
  console.log('  ✓ bookings/_placeholder');
  await db.collection('messages').doc('_placeholder').set({ _init: true, createdAt: now });
  console.log('  ✓ messages/_placeholder');
  await db.collection('notifications').doc('_placeholder').set({ _init: true, createdAt: now });
  console.log('  ✓ notifications/_placeholder');

  console.log('\n✅ Seed terminé avec succès !');
  console.log('   4 users | 6 listings | 3 reviews');
  console.log('   Firestore → https://console.firebase.google.com/project/casaimo/firestore\n');
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Erreur:', err.message);
  process.exit(1);
});
