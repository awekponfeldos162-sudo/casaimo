import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String id;
  final String hostId;
  final String hostName;
  final String hostAvatarUrl;
  final String hostPhone;
  final String hostEmail;
  final String hostBusinessType;
  final String hostBusinessAddress;
  final bool hostIsVerified;
  final String type;
  final String title;
  final String description;
  final String address;
  final String city;
  final double lat;
  final double lng;
  final List<String> amenities;
  final List<String> mediaUrls;
  final String videoUrl;
  final double pricePerNight;
  final double pricePerMonth;
  final double cleaningFee;
  final double serviceFeePercent;
  final String cancellationPolicy;
  final int minStay;
  final int maxStay;
  final int bedrooms;
  final int bathrooms;
  final int maxGuests;
  final double avgRating;
  final int reviewCount;
  final String status;
  final DateTime createdAt;

  const ListingModel({
    required this.id,
    required this.hostId,
    this.hostName = '',
    this.hostAvatarUrl = '',
    this.hostPhone = '',
    this.hostEmail = '',
    this.hostBusinessType = '',
    this.hostBusinessAddress = '',
    this.hostIsVerified = false,
    required this.type,
    required this.title,
    required this.description,
    required this.address,
    required this.city,
    required this.lat,
    required this.lng,
    required this.amenities,
    required this.mediaUrls,
    this.videoUrl = '',
    required this.pricePerNight,
    this.pricePerMonth = 0,
    required this.cleaningFee,
    required this.serviceFeePercent,
    required this.cancellationPolicy,
    required this.minStay,
    required this.maxStay,
    required this.bedrooms,
    required this.bathrooms,
    required this.maxGuests,
    required this.avgRating,
    required this.reviewCount,
    required this.status,
    required this.createdAt,
  });

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? '',
      hostAvatarUrl: data['hostAvatarUrl'] ?? '',
      hostPhone: data['hostPhone'] ?? '',
      hostEmail: data['hostEmail'] ?? '',
      hostBusinessType: data['hostBusinessType'] ?? '',
      hostBusinessAddress: data['hostBusinessAddress'] ?? '',
      hostIsVerified: data['hostIsVerified'] ?? false,
      type: data['type'] ?? 'Appartement',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      amenities: List<String>.from(data['amenities'] ?? []),
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      videoUrl: data['videoUrl'] ?? '',
      pricePerNight: (data['pricePerNight'] ?? 0.0).toDouble(),
      pricePerMonth: (data['pricePerMonth'] ?? 0.0).toDouble(),
      cleaningFee: (data['cleaningFee'] ?? 0.0).toDouble(),
      serviceFeePercent: (data['serviceFeePercent'] ?? 0.12).toDouble(),
      cancellationPolicy: data['cancellationPolicy'] ?? 'flexible',
      minStay: data['minStay'] ?? 1,
      maxStay: data['maxStay'] ?? 30,
      bedrooms: data['bedrooms'] ?? 1,
      bathrooms: data['bathrooms'] ?? 1,
      maxGuests: data['maxGuests'] ?? 2,
      avgRating: (data['avgRating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      status: data['status'] ?? 'published',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'hostId': hostId,
    'hostName': hostName,
    'hostAvatarUrl': hostAvatarUrl,
    'hostPhone': hostPhone,
    'hostEmail': hostEmail,
    'hostBusinessType': hostBusinessType,
    'hostBusinessAddress': hostBusinessAddress,
    'hostIsVerified': hostIsVerified,
    'type': type,
    'title': title,
    'description': description,
    'address': address,
    'city': city,
    'lat': lat,
    'lng': lng,
    'amenities': amenities,
    'mediaUrls': mediaUrls,
    'videoUrl': videoUrl,
    'pricePerNight': pricePerNight,
    'pricePerMonth': pricePerMonth,
    'cleaningFee': cleaningFee,
    'serviceFeePercent': serviceFeePercent,
    'cancellationPolicy': cancellationPolicy,
    'minStay': minStay,
    'maxStay': maxStay,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'maxGuests': maxGuests,
    'avgRating': avgRating,
    'reviewCount': reviewCount,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  };

  String get mainImage => mediaUrls.isNotEmpty ? mediaUrls.first : '';
  bool get isPublished => status == 'published';
  bool get hasVideo => videoUrl.isNotEmpty;

  ListingModel copyWith({
    String? type,
    String? title,
    String? description,
    String? address,
    String? city,
    double? lat,
    double? lng,
    List<String>? amenities,
    List<String>? mediaUrls,
    String? videoUrl,
    double? pricePerNight,
    double? pricePerMonth,
    double? cleaningFee,
    double? serviceFeePercent,
    String? cancellationPolicy,
    int? minStay,
    int? maxStay,
    int? bedrooms,
    int? bathrooms,
    int? maxGuests,
    double? avgRating,
    int? reviewCount,
    String? status,
  }) {
    return ListingModel(
      id: id,
      hostId: hostId,
      hostName: hostName,
      hostAvatarUrl: hostAvatarUrl,
      hostPhone: hostPhone,
      hostEmail: hostEmail,
      hostBusinessType: hostBusinessType,
      hostBusinessAddress: hostBusinessAddress,
      hostIsVerified: hostIsVerified,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      amenities: amenities ?? this.amenities,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      cleaningFee: cleaningFee ?? this.cleaningFee,
      serviceFeePercent: serviceFeePercent ?? this.serviceFeePercent,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      minStay: minStay ?? this.minStay,
      maxStay: maxStay ?? this.maxStay,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      maxGuests: maxGuests ?? this.maxGuests,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class ListingSamples {
  static List<ListingModel> get demos => [
    ListingModel(
      id: '1', hostId: 'host1', hostName: 'Golden Residences', type: 'Villa',
      title: 'Golden Gate Cottage',
      description: 'Golden Gate Cottage est un havre de charme niché au cœur de la ville, avec un intérieur chaleureux aux poutres en bois roux. Le jardin spacieux est une oasis sereine, ornée de massifs fleuris colorés.',
      address: 'Ulitsa Lenina, 25', city: 'Cotonou',
      lat: 6.3703, lng: 2.3912,
      amenities: ['WiFi', 'Parking', 'Climatisation', 'Piscine', 'Cuisine', 'CCTV'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800',
        'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
      ],
      pricePerNight: 45000, pricePerMonth: 900000, cleaningFee: 5000, serviceFeePercent: 0.12,
      cancellationPolicy: 'flexible', minStay: 1, maxStay: 30,
      bedrooms: 3, bathrooms: 2, maxGuests: 6,
      avgRating: 4.8, reviewCount: 124,
      status: 'published', createdAt: DateTime.now(),
    ),
    ListingModel(
      id: '2', hostId: 'host2', hostName: 'Lomé Prestige', type: 'Appartement',
      title: 'Luxe 1BR Hideaway',
      description: 'Appartement moderne en plein cœur de la ville avec vue panoramique. Idéal pour les voyageurs d\'affaires et les couples.',
      address: '15 Avenue des Cocotiers', city: 'Lomé',
      lat: 6.1375, lng: 1.2123,
      amenities: ['WiFi', 'Climatisation', 'TV', 'Cuisine', 'Sécurité 24h/24'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      ],
      pricePerNight: 28000, pricePerMonth: 500000, cleaningFee: 3000, serviceFeePercent: 0.12,
      cancellationPolicy: 'moderate', minStay: 2, maxStay: 14,
      bedrooms: 1, bathrooms: 1, maxGuests: 2,
      avgRating: 4.5, reviewCount: 89,
      status: 'published', createdAt: DateTime.now(),
    ),
    ListingModel(
      id: '3', hostId: 'host3', hostName: 'Abidjan Villas', type: 'Maison',
      title: 'Villa Bali Valli',
      description: 'Magnifique maison tropicale avec piscine privée et jardin luxuriant. Parfaite pour les familles et les groupes.',
      address: '8 Rue des Palmiers', city: 'Abidjan',
      lat: 5.3599, lng: -4.0082,
      amenities: ['WiFi', 'Piscine', 'Parking', 'Cuisine', 'Climatisation', 'Terrasse'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800',
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
      ],
      pricePerNight: 65000, pricePerMonth: 1200000, cleaningFee: 8000, serviceFeePercent: 0.12,
      cancellationPolicy: 'strict', minStay: 3, maxStay: 21,
      bedrooms: 4, bathrooms: 3, maxGuests: 8,
      avgRating: 4.9, reviewCount: 56,
      status: 'published', createdAt: DateTime.now(),
    ),
    ListingModel(
      id: '4', hostId: 'host4', hostName: 'Dakar Stays', type: 'Studio',
      title: 'Studio Cozy Centre-Ville',
      description: 'Studio confortable et bien équipé, idéalement situé au centre-ville. Accès facile à tous les transports.',
      address: '22 Boulevard de la Liberté', city: 'Dakar',
      lat: 14.6928, lng: -17.4467,
      amenities: ['WiFi', 'Climatisation', 'TV', 'Cuisine'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800',
      ],
      pricePerNight: 18000, pricePerMonth: 350000, cleaningFee: 2000, serviceFeePercent: 0.12,
      cancellationPolicy: 'flexible', minStay: 1, maxStay: 7,
      bedrooms: 1, bathrooms: 1, maxGuests: 2,
      avgRating: 4.3, reviewCount: 212,
      status: 'published', createdAt: DateTime.now(),
    ),
    ListingModel(
      id: '5', hostId: 'host5', hostName: 'Hôtel Elite Palace', type: 'Hôtel',
      title: 'Elite Unit - Roof Suite',
      description: 'Suite haut de gamme avec terrasse privative et vue sur la ville. Service hôtelier 5 étoiles inclus.',
      address: '1 Place de l\'Indépendance', city: 'Cotonou',
      lat: 6.3654, lng: 2.4183,
      amenities: ['WiFi', 'Piscine', 'Salle de sport', 'Parking', 'Climatisation', 'Ascenseur', 'Sécurité 24h/24'],
      mediaUrls: [
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
        'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800',
      ],
      pricePerNight: 120000, pricePerMonth: 0, cleaningFee: 0, serviceFeePercent: 0.10,
      cancellationPolicy: 'moderate', minStay: 1, maxStay: 30,
      bedrooms: 2, bathrooms: 2, maxGuests: 4,
      avgRating: 4.9, reviewCount: 340,
      status: 'published', createdAt: DateTime.now(),
    ),
  ];
}
