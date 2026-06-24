// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CasaImo';

  @override
  String get tagline => 'Your dream home, within reach';

  @override
  String get language => 'Language';

  @override
  String get languageFr => 'Français';

  @override
  String get languageEn => 'English';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get continueBtn => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get start => 'Get Started';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'City, district, property type…';

  @override
  String get noResults => 'No results';

  @override
  String get seeAll => 'See all';

  @override
  String get seeMore => 'See more';

  @override
  String get seeLess => 'See less';

  @override
  String get readMore => 'Read more';

  @override
  String get login => 'Log in';

  @override
  String get signup => 'Sign up';

  @override
  String get logout => 'Log out';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginSubtitle => 'Welcome! Log in to continue.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get orContinueWithEmail => 'or continue with email';

  @override
  String get email => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'No account?';

  @override
  String get alreadyAccount => 'Already have an account?';

  @override
  String get exploreWithoutAccount => 'Explore without account';

  @override
  String get chooseProfile => 'Who are you?';

  @override
  String get clientRole => 'I am a Guest';

  @override
  String get hostRole => 'I am a Host';

  @override
  String get clientSignupTitle => 'Guest Sign Up';

  @override
  String get hostSignupTitle => 'Host Sign Up';

  @override
  String get createAccount => 'Create my account';

  @override
  String get createHostAccount => 'Create my host account';

  @override
  String get fullName => 'Full name';

  @override
  String get phone => 'Phone';

  @override
  String get home => 'Home';

  @override
  String get favorites => 'Favorites';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get myBookings => 'My bookings';

  @override
  String get listingDetail => 'Property details';

  @override
  String get reserve => 'Book now';

  @override
  String get reservationTitle => 'Booking';

  @override
  String get stepDates => 'Dates & Guests';

  @override
  String get stepPayment => 'Summary & Payment';

  @override
  String get checkIn => 'Check-in';

  @override
  String get checkOut => 'Check-out';

  @override
  String get chooseDates => 'Choose your dates';

  @override
  String get travelers => 'Guests';

  @override
  String nights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '$count night',
    );
    return '$_temp0';
  }

  @override
  String get pricePerNight => '/ night';

  @override
  String get totalPrice => 'Total including all fees';

  @override
  String get cleaningFee => 'Cleaning fee';

  @override
  String get serviceFee => 'Service fee';

  @override
  String get confirmAndPay => 'Confirm and pay';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get paymentComplete => 'Payment Complete!';

  @override
  String get bookingConfirmed => 'Booking confirmed';

  @override
  String get bookingNumber => 'Booking reference';

  @override
  String get backToHome => 'Back to home';

  @override
  String get seeMyBookings => 'See my bookings';

  @override
  String get hostProfile => 'Host profile';

  @override
  String get seeProfile => 'See profile';

  @override
  String get sendMessage => 'Send message';

  @override
  String get call => 'Call';

  @override
  String get verified => 'Verified';

  @override
  String get notVerified => 'Not verified';

  @override
  String get description => 'Description';

  @override
  String get amenities => 'Amenities';

  @override
  String get reviews => 'Reviews';

  @override
  String get policy => 'Policy';

  @override
  String get cancellationPolicy => 'Cancellation';

  @override
  String get minStay => 'Min stay';

  @override
  String get maxStay => 'Max stay';

  @override
  String get bedrooms => 'bedrooms';

  @override
  String get bathrooms => 'bathrooms';

  @override
  String get maxGuests => 'max guests';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get myListings => 'My listings';

  @override
  String get addListing => 'Add listing';

  @override
  String get editListing => 'Edit listing';

  @override
  String get calendar => 'Calendar';

  @override
  String get earnings => 'Earnings';

  @override
  String step(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String get personalInfo => 'Personal information';

  @override
  String get businessInfo => 'Your business';

  @override
  String get summary => 'Summary';

  @override
  String get typeOfBusiness => 'Type of business';

  @override
  String get businessName => 'Business name';

  @override
  String get address => 'Address';

  @override
  String get securePayment => '100% secure payment · Encrypted data';

  @override
  String get errorFieldRequired => 'Please fill in all required fields';

  @override
  String get errorPasswordShort => 'Password too short (6 characters minimum)';

  @override
  String get errorLoginFailed => 'Incorrect email or password';

  @override
  String get errorSignupFailed => 'Registration failed. Email already in use?';

  @override
  String get errorGoogleFailed => 'Google sign-in failed';

  @override
  String get onboardingTag1 => 'Find your accommodation';

  @override
  String get onboardingTitle1 => 'Thousands of properties\nat your fingertips';

  @override
  String get onboardingSubtitle1 =>
      'Apartments, houses, villas… browse verified listings across West Africa.';

  @override
  String get onboardingTag2 => 'Simple booking';

  @override
  String get onboardingTitle2 => 'Book in a few clicks,\nanywhere';

  @override
  String get onboardingSubtitle2 =>
      'Choose your dates, guests and confirm your stay securely.';

  @override
  String get onboardingTag3 => 'Safe stay';

  @override
  String get onboardingTitle3 => 'Verified hosts,\nguaranteed stays';

  @override
  String get onboardingSubtitle3 =>
      'Every host is validated. Secure payment and support available 24/7.';
}
