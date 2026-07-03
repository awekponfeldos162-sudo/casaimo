import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const appName = 'CasaImo';
  static const appVersion = '1.0.0';

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusCircle = 100;

  static const double listingCardHeight = 220;
  static const double listingCardWidth = 200;
  static const double listingCardHeightFull = 280;

  static const String placeholderImage = 'https://via.placeholder.com/400x300';

  static const String colUsers = 'users';
  static const String colListings = 'listings';
  static const String colBookings = 'bookings';
  static const String colMessages = 'messages';
  static const String colReviews = 'reviews';
  static const String colCoupons = 'coupons';
  static const String colNotifications = 'notifications';
  static const String colAvailability = 'availability';
  static const String colPayouts = 'payouts';
  static const String colReports = 'reports';

  static const List<String> listingTypes = [
    'Chambre simple',
    'Chambre double',
    'Suite',
    'Studio',
    'Appartement',
    'Maison',
    'Villa',
    'Hôtel',
    'Résidence',
  ];

  static Map<String, IconData> get listingTypeIcons => const {
    'Chambre simple': Icons.single_bed_rounded,
    'Chambre double': Icons.bed_rounded,
    'Suite': Icons.king_bed_rounded,
    'Studio': Icons.apartment_rounded,
    'Appartement': Icons.domain_rounded,
    'Maison': Icons.house_rounded,
    'Villa': Icons.villa_rounded,
    'Hôtel': Icons.hotel_rounded,
    'Résidence': Icons.location_city_rounded,
  };

  static const List<String> amenities = [
    'WiFi', 'Parking', 'Climatisation', 'Piscine', 'Cuisine équipée', 'TV',
    'Salle de sport', 'Sécurité 24h/24', 'Ascenseur', 'Terrasse',
    'Vue mer', 'Animaux acceptés', 'Non-fumeur', 'Accessible PMR',
    'Réfrigérateur', 'Machine à laver', 'Fer à repasser', 'Coffre-fort',
    'Jacuzzi', 'Barbecue', 'Salle de réunion', 'CCTV',
  ];

  static const List<String> businessTypes = [
    'Particulier',
    'Hôtel',
    'Agence immobilière',
    'Résidence hôtelière',
    'Appartement meublé',
  ];

  static const int pageSize = 20;

  // Agora RTC — valeur chargée depuis .env (AGORA_APP_ID)
  static String get agoraAppId => dotenv.env['AGORA_APP_ID'] ?? '';

  // Google Maps — valeur chargée depuis .env (GOOGLE_MAPS_API_KEY)
  static String get mapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static bool get mapsEnabled => mapsApiKey.isNotEmpty;

  static const List<String> mobileMoneyProviders = [
    'MTN Mobile Money', 'Orange Money', 'Moov Money', 'Wave',
  ];
}
