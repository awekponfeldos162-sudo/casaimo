import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Nom de l'application
  ///
  /// In fr, this message translates to:
  /// **'CasaImo'**
  String get appName;

  /// Slogan de l'application
  ///
  /// In fr, this message translates to:
  /// **'Votre maison de rêve, à portée de main'**
  String get tagline;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageFr.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFr;

  /// No description provided for @languageEn.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @continueBtn.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueBtn;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get start;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Ville, quartier, type de logement…'**
  String get searchHint;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResults;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get seeAll;

  /// No description provided for @seeMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir plus'**
  String get seeMore;

  /// No description provided for @seeLess.
  ///
  /// In fr, this message translates to:
  /// **'Voir moins'**
  String get seeLess;

  /// No description provided for @readMore.
  ///
  /// In fr, this message translates to:
  /// **'Lire la suite'**
  String get readMore;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signup;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue ! Connectez-vous pour continuer.'**
  String get loginSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @orContinueWithEmail.
  ///
  /// In fr, this message translates to:
  /// **'ou continuer avec email'**
  String get orContinueWithEmail;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas de compte ?'**
  String get noAccount;

  /// No description provided for @alreadyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get alreadyAccount;

  /// No description provided for @exploreWithoutAccount.
  ///
  /// In fr, this message translates to:
  /// **'Explorer sans compte'**
  String get exploreWithoutAccount;

  /// No description provided for @chooseProfile.
  ///
  /// In fr, this message translates to:
  /// **'Qui êtes-vous ?'**
  String get chooseProfile;

  /// No description provided for @clientRole.
  ///
  /// In fr, this message translates to:
  /// **'Je suis Client'**
  String get clientRole;

  /// No description provided for @hostRole.
  ///
  /// In fr, this message translates to:
  /// **'Je suis Propriétaire'**
  String get hostRole;

  /// No description provided for @clientSignupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscription Client'**
  String get clientSignupTitle;

  /// No description provided for @hostSignupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscription Propriétaire'**
  String get hostSignupTitle;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get createAccount;

  /// No description provided for @createHostAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte propriétaire'**
  String get createHostAccount;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @favorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// No description provided for @messages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @myBookings.
  ///
  /// In fr, this message translates to:
  /// **'Mes réservations'**
  String get myBookings;

  /// No description provided for @listingDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail du bien'**
  String get listingDetail;

  /// No description provided for @reserve.
  ///
  /// In fr, this message translates to:
  /// **'Réserver maintenant'**
  String get reserve;

  /// No description provided for @reservationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservation'**
  String get reservationTitle;

  /// No description provided for @stepDates.
  ///
  /// In fr, this message translates to:
  /// **'Dates & Voyageurs'**
  String get stepDates;

  /// No description provided for @stepPayment.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif & Paiement'**
  String get stepPayment;

  /// No description provided for @checkIn.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get checkOut;

  /// No description provided for @chooseDates.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez vos dates'**
  String get chooseDates;

  /// No description provided for @travelers.
  ///
  /// In fr, this message translates to:
  /// **'Voyageurs'**
  String get travelers;

  /// No description provided for @nights.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{{count} nuit} other{{count} nuits}}'**
  String nights(int count);

  /// No description provided for @pricePerNight.
  ///
  /// In fr, this message translates to:
  /// **'/ nuit'**
  String get pricePerNight;

  /// No description provided for @totalPrice.
  ///
  /// In fr, this message translates to:
  /// **'Total toutes charges comprises'**
  String get totalPrice;

  /// No description provided for @cleaningFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais de ménage'**
  String get cleaningFee;

  /// No description provided for @serviceFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais de service'**
  String get serviceFee;

  /// No description provided for @confirmAndPay.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer et payer'**
  String get confirmAndPay;

  /// No description provided for @paymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get paymentMethod;

  /// No description provided for @paymentComplete.
  ///
  /// In fr, this message translates to:
  /// **'Paiement Complet !'**
  String get paymentComplete;

  /// No description provided for @bookingConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Réservation confirmée'**
  String get bookingConfirmed;

  /// No description provided for @bookingNumber.
  ///
  /// In fr, this message translates to:
  /// **'N° de réservation'**
  String get bookingNumber;

  /// No description provided for @backToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;

  /// No description provided for @seeMyBookings.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes réservations'**
  String get seeMyBookings;

  /// No description provided for @hostProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil du propriétaire'**
  String get hostProfile;

  /// No description provided for @seeProfile.
  ///
  /// In fr, this message translates to:
  /// **'Voir le profil'**
  String get seeProfile;

  /// No description provided for @sendMessage.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un message'**
  String get sendMessage;

  /// No description provided for @call.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get call;

  /// No description provided for @verified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get verified;

  /// No description provided for @notVerified.
  ///
  /// In fr, this message translates to:
  /// **'Non vérifié'**
  String get notVerified;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @amenities.
  ///
  /// In fr, this message translates to:
  /// **'Équipements'**
  String get amenities;

  /// No description provided for @reviews.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get reviews;

  /// No description provided for @policy.
  ///
  /// In fr, this message translates to:
  /// **'Politique'**
  String get policy;

  /// No description provided for @cancellationPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Annulation'**
  String get cancellationPolicy;

  /// No description provided for @minStay.
  ///
  /// In fr, this message translates to:
  /// **'Séjour min'**
  String get minStay;

  /// No description provided for @maxStay.
  ///
  /// In fr, this message translates to:
  /// **'Séjour max'**
  String get maxStay;

  /// No description provided for @bedrooms.
  ///
  /// In fr, this message translates to:
  /// **'chambres'**
  String get bedrooms;

  /// No description provided for @bathrooms.
  ///
  /// In fr, this message translates to:
  /// **'salles de bain'**
  String get bathrooms;

  /// No description provided for @maxGuests.
  ///
  /// In fr, this message translates to:
  /// **'personnes max'**
  String get maxGuests;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboard;

  /// No description provided for @myListings.
  ///
  /// In fr, this message translates to:
  /// **'Mes annonces'**
  String get myListings;

  /// No description provided for @addListing.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une annonce'**
  String get addListing;

  /// No description provided for @editListing.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'annonce'**
  String get editListing;

  /// No description provided for @calendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get calendar;

  /// No description provided for @earnings.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get earnings;

  /// No description provided for @step.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current}/{total}'**
  String step(int current, int total);

  /// No description provided for @personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfo;

  /// No description provided for @businessInfo.
  ///
  /// In fr, this message translates to:
  /// **'Votre activité'**
  String get businessInfo;

  /// No description provided for @summary.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get summary;

  /// No description provided for @typeOfBusiness.
  ///
  /// In fr, this message translates to:
  /// **'Type d\'activité'**
  String get typeOfBusiness;

  /// No description provided for @businessName.
  ///
  /// In fr, this message translates to:
  /// **'Nom commercial'**
  String get businessName;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @securePayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement 100% sécurisé · Données chiffrées'**
  String get securePayment;

  /// No description provided for @errorFieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs obligatoires'**
  String get errorFieldRequired;

  /// No description provided for @errorPasswordShort.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe trop court (6 caractères minimum)'**
  String get errorPasswordShort;

  /// No description provided for @errorLoginFailed.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect'**
  String get errorLoginFailed;

  /// No description provided for @errorSignupFailed.
  ///
  /// In fr, this message translates to:
  /// **'Inscription échouée. Email déjà utilisé ?'**
  String get errorSignupFailed;

  /// No description provided for @errorGoogleFailed.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google échouée'**
  String get errorGoogleFailed;

  /// No description provided for @onboardingTag1.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez votre logement'**
  String get onboardingTag1;

  /// No description provided for @onboardingTitle1.
  ///
  /// In fr, this message translates to:
  /// **'Des milliers de biens\nà portée de main'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In fr, this message translates to:
  /// **'Appartements, maisons, villas… explorez des annonces vérifiées partout en Afrique de l\'Ouest.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTag2.
  ///
  /// In fr, this message translates to:
  /// **'Réservation simple'**
  String get onboardingTag2;

  /// No description provided for @onboardingTitle2.
  ///
  /// In fr, this message translates to:
  /// **'Réservez en quelques\nclics, partout'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez vos dates, vos voyageurs et confirmez votre séjour en toute sécurité.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTag3.
  ///
  /// In fr, this message translates to:
  /// **'Séjour sécurisé'**
  String get onboardingTag3;

  /// No description provided for @onboardingTitle3.
  ///
  /// In fr, this message translates to:
  /// **'Hôtes vérifiés,\nséjours garantis'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In fr, this message translates to:
  /// **'Chaque propriétaire est validé. Paiement sécurisé et support disponible 24h/24.'**
  String get onboardingSubtitle3;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'fr':
      return AppL10nFr();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
