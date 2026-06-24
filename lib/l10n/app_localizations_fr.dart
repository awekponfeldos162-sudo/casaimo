// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppL10nFr extends AppL10n {
  AppL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'CasaImo';

  @override
  String get tagline => 'Votre maison de rêve, à portée de main';

  @override
  String get language => 'Langue';

  @override
  String get languageFr => 'Français';

  @override
  String get languageEn => 'English';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get continueBtn => 'Continuer';

  @override
  String get back => 'Retour';

  @override
  String get close => 'Fermer';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';

  @override
  String get start => 'Commencer';

  @override
  String get search => 'Rechercher';

  @override
  String get searchHint => 'Ville, quartier, type de logement…';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get seeAll => 'Voir tout';

  @override
  String get seeMore => 'Voir plus';

  @override
  String get seeLess => 'Voir moins';

  @override
  String get readMore => 'Lire la suite';

  @override
  String get login => 'Se connecter';

  @override
  String get signup => 'S\'inscrire';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginSubtitle => 'Bienvenue ! Connectez-vous pour continuer.';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get orContinueWithEmail => 'ou continuer avec email';

  @override
  String get email => 'Adresse email';

  @override
  String get password => 'Mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get noAccount => 'Pas de compte ?';

  @override
  String get alreadyAccount => 'Déjà un compte ?';

  @override
  String get exploreWithoutAccount => 'Explorer sans compte';

  @override
  String get chooseProfile => 'Qui êtes-vous ?';

  @override
  String get clientRole => 'Je suis Client';

  @override
  String get hostRole => 'Je suis Propriétaire';

  @override
  String get clientSignupTitle => 'Inscription Client';

  @override
  String get hostSignupTitle => 'Inscription Propriétaire';

  @override
  String get createAccount => 'Créer mon compte';

  @override
  String get createHostAccount => 'Créer mon compte propriétaire';

  @override
  String get fullName => 'Nom complet';

  @override
  String get phone => 'Téléphone';

  @override
  String get home => 'Accueil';

  @override
  String get favorites => 'Favoris';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get notifications => 'Notifications';

  @override
  String get myBookings => 'Mes réservations';

  @override
  String get listingDetail => 'Détail du bien';

  @override
  String get reserve => 'Réserver maintenant';

  @override
  String get reservationTitle => 'Réservation';

  @override
  String get stepDates => 'Dates & Voyageurs';

  @override
  String get stepPayment => 'Récapitulatif & Paiement';

  @override
  String get checkIn => 'Arrivée';

  @override
  String get checkOut => 'Départ';

  @override
  String get chooseDates => 'Choisissez vos dates';

  @override
  String get travelers => 'Voyageurs';

  @override
  String nights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuits',
      one: '$count nuit',
    );
    return '$_temp0';
  }

  @override
  String get pricePerNight => '/ nuit';

  @override
  String get totalPrice => 'Total toutes charges comprises';

  @override
  String get cleaningFee => 'Frais de ménage';

  @override
  String get serviceFee => 'Frais de service';

  @override
  String get confirmAndPay => 'Confirmer et payer';

  @override
  String get paymentMethod => 'Mode de paiement';

  @override
  String get paymentComplete => 'Paiement Complet !';

  @override
  String get bookingConfirmed => 'Réservation confirmée';

  @override
  String get bookingNumber => 'N° de réservation';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get seeMyBookings => 'Voir mes réservations';

  @override
  String get hostProfile => 'Profil du propriétaire';

  @override
  String get seeProfile => 'Voir le profil';

  @override
  String get sendMessage => 'Envoyer un message';

  @override
  String get call => 'Appeler';

  @override
  String get verified => 'Vérifié';

  @override
  String get notVerified => 'Non vérifié';

  @override
  String get description => 'Description';

  @override
  String get amenities => 'Équipements';

  @override
  String get reviews => 'Avis';

  @override
  String get policy => 'Politique';

  @override
  String get cancellationPolicy => 'Annulation';

  @override
  String get minStay => 'Séjour min';

  @override
  String get maxStay => 'Séjour max';

  @override
  String get bedrooms => 'chambres';

  @override
  String get bathrooms => 'salles de bain';

  @override
  String get maxGuests => 'personnes max';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get myListings => 'Mes annonces';

  @override
  String get addListing => 'Ajouter une annonce';

  @override
  String get editListing => 'Modifier l\'annonce';

  @override
  String get calendar => 'Calendrier';

  @override
  String get earnings => 'Revenus';

  @override
  String step(int current, int total) {
    return 'Étape $current/$total';
  }

  @override
  String get personalInfo => 'Informations personnelles';

  @override
  String get businessInfo => 'Votre activité';

  @override
  String get summary => 'Récapitulatif';

  @override
  String get typeOfBusiness => 'Type d\'activité';

  @override
  String get businessName => 'Nom commercial';

  @override
  String get address => 'Adresse';

  @override
  String get securePayment => 'Paiement 100% sécurisé · Données chiffrées';

  @override
  String get errorFieldRequired =>
      'Veuillez remplir tous les champs obligatoires';

  @override
  String get errorPasswordShort =>
      'Mot de passe trop court (6 caractères minimum)';

  @override
  String get errorLoginFailed => 'Email ou mot de passe incorrect';

  @override
  String get errorSignupFailed => 'Inscription échouée. Email déjà utilisé ?';

  @override
  String get errorGoogleFailed => 'Connexion Google échouée';

  @override
  String get onboardingTag1 => 'Trouvez votre logement';

  @override
  String get onboardingTitle1 => 'Des milliers de biens\nà portée de main';

  @override
  String get onboardingSubtitle1 =>
      'Appartements, maisons, villas… explorez des annonces vérifiées partout en Afrique de l\'Ouest.';

  @override
  String get onboardingTag2 => 'Réservation simple';

  @override
  String get onboardingTitle2 => 'Réservez en quelques\nclics, partout';

  @override
  String get onboardingSubtitle2 =>
      'Choisissez vos dates, vos voyageurs et confirmez votre séjour en toute sécurité.';

  @override
  String get onboardingTag3 => 'Séjour sécurisé';

  @override
  String get onboardingTitle3 => 'Hôtes vérifiés,\nséjours garantis';

  @override
  String get onboardingSubtitle3 =>
      'Chaque propriétaire est validé. Paiement sécurisé et support disponible 24h/24.';
}
