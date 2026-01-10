import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ro.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('ro')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'DeltaBooks'**
  String get appTitle;

  /// Label for user's own library
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get myLibrary;

  /// Label for partner's library
  ///
  /// In en, this message translates to:
  /// **'Partner\'s Library'**
  String get partnerLibrary;

  /// Label for scanning barcode
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// Label for statistics screen
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Logout button label
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Email input label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password input label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Login button label
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button label
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Error message for failed login
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// Error message for failed registration
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// Message when user's library is empty
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get emptyLibrary;

  /// Message when partner's library is empty
  ///
  /// In en, this message translates to:
  /// **'Partner\'s library is empty'**
  String get emptyPartnerLibrary;

  /// Instruction for scanning barcode
  ///
  /// In en, this message translates to:
  /// **'Scan the book\'s barcode'**
  String get scanBarcode;

  /// Label for manual ISBN input
  ///
  /// In en, this message translates to:
  /// **'Enter ISBN manually'**
  String get enterIsbnManually;

  /// ISBN input label
  ///
  /// In en, this message translates to:
  /// **'ISBN'**
  String get isbn;

  /// Placeholder for ISBN input
  ///
  /// In en, this message translates to:
  /// **'Enter ISBN'**
  String get enterIsbn;

  /// Search button label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Button to cancel invitation
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button to add book to library
  ///
  /// In en, this message translates to:
  /// **'Add to library'**
  String get addToLibrary;

  /// Author label
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// Pages label
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// Success message when book is added
  ///
  /// In en, this message translates to:
  /// **'Book added!'**
  String get bookAdded;

  /// Error message when adding book fails
  ///
  /// In en, this message translates to:
  /// **'Error adding book'**
  String get addError;

  /// Error message when book is not found
  ///
  /// In en, this message translates to:
  /// **'Book not found'**
  String get bookNotFound;

  /// Error message when ISBN is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter an ISBN'**
  String get enterIsbnError;

  /// Page label
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// Book status: currently reading
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// Book status: finished reading
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// Book status: not yet read
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// Statistics label
  ///
  /// In en, this message translates to:
  /// **'Pages read this month'**
  String get pagesReadThisMonth;

  /// Statistics label
  ///
  /// In en, this message translates to:
  /// **'Total library value (RON)'**
  String get totalLibraryValue;

  /// Statistics label
  ///
  /// In en, this message translates to:
  /// **'Total books'**
  String get totalBooks;

  /// Statistics label
  ///
  /// In en, this message translates to:
  /// **'Total pages read'**
  String get totalPagesRead;

  /// Error message for statistics
  ///
  /// In en, this message translates to:
  /// **'Error loading statistics'**
  String get statsError;

  /// Language label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Romanian language name
  ///
  /// In en, this message translates to:
  /// **'Romanian'**
  String get romanian;

  /// Text for register link
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Text for login link
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Button to share library with another user
  ///
  /// In en, this message translates to:
  /// **'Share Library'**
  String get shareLibrary;

  /// Title for searching user screen
  ///
  /// In en, this message translates to:
  /// **'Search User'**
  String get searchUser;

  /// Placeholder for email search
  ///
  /// In en, this message translates to:
  /// **'Search user by email'**
  String get searchUserByEmail;

  /// Error when user is not found
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// Button to send invitation
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get sendInvitation;

  /// Success message when invitation is sent
  ///
  /// In en, this message translates to:
  /// **'Invitation sent successfully!'**
  String get invitationSent;

  /// Error message when invitation fails
  ///
  /// In en, this message translates to:
  /// **'Error sending invitation'**
  String get invitationError;

  /// Title for invitations screen
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations;

  /// Label for sent invitations tab
  ///
  /// In en, this message translates to:
  /// **'Sent Invitations'**
  String get sentInvitations;

  /// Label for received invitations tab
  ///
  /// In en, this message translates to:
  /// **'Received Invitations'**
  String get receivedInvitations;

  /// Status label for pending invitations
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Status label for accepted invitations
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// Status label for rejected invitations
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// Button to accept invitation
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Button to reject invitation
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// Success message when invitation is accepted
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted!'**
  String get invitationAccepted;

  /// Message when invitation is rejected
  ///
  /// In en, this message translates to:
  /// **'Invitation rejected'**
  String get invitationRejected;

  /// Message when invitation is canceled
  ///
  /// In en, this message translates to:
  /// **'Invitation canceled'**
  String get invitationCanceled;

  /// Message when there are no invitations
  ///
  /// In en, this message translates to:
  /// **'No invitations'**
  String get noInvitations;

  /// Label showing who sent the invitation
  ///
  /// In en, this message translates to:
  /// **'Invite from'**
  String get inviteFrom;

  /// Label showing who received the invitation
  ///
  /// In en, this message translates to:
  /// **'Invite to'**
  String get inviteTo;

  /// Error when users are already partners
  ///
  /// In en, this message translates to:
  /// **'You are already partners'**
  String get alreadyPartner;

  /// Error when invitation already exists
  ///
  /// In en, this message translates to:
  /// **'Invitation already exists'**
  String get invitationExists;

  /// Label for library
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// Title for libraries screen
  ///
  /// In en, this message translates to:
  /// **'Libraries'**
  String get libraries;

  /// Label for library selection
  ///
  /// In en, this message translates to:
  /// **'Select Library'**
  String get selectLibrary;

  /// Error message when library is not selected
  ///
  /// In en, this message translates to:
  /// **'Please select a library first'**
  String get selectLibraryFirst;

  /// Button to create a new library
  ///
  /// In en, this message translates to:
  /// **'Create Library'**
  String get createLibrary;

  /// Label for library name input
  ///
  /// In en, this message translates to:
  /// **'Library Name'**
  String get libraryName;

  /// Label for library description input
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get libraryDescription;

  /// Message when user has no libraries
  ///
  /// In en, this message translates to:
  /// **'No libraries yet'**
  String get noLibraries;

  /// Message prompting user to create library
  ///
  /// In en, this message translates to:
  /// **'Create a library first to share it'**
  String get createLibraryFirst;

  /// Success message when library is created
  ///
  /// In en, this message translates to:
  /// **'Library created!'**
  String get libraryCreated;

  /// Error message when library creation fails
  ///
  /// In en, this message translates to:
  /// **'Error creating library'**
  String get libraryError;

  /// Title for my libraries list
  ///
  /// In en, this message translates to:
  /// **'My Libraries'**
  String get myLibraries;

  /// Button to delete library
  ///
  /// In en, this message translates to:
  /// **'Delete Library'**
  String get deleteLibrary;

  /// Button to edit library
  ///
  /// In en, this message translates to:
  /// **'Edit Library'**
  String get editLibrary;

  /// Message when library is deleted
  ///
  /// In en, this message translates to:
  /// **'Library deleted'**
  String get libraryDeleted;

  /// Message when library is updated
  ///
  /// In en, this message translates to:
  /// **'Library updated'**
  String get libraryUpdated;

  /// Error when library name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a library name'**
  String get enterLibraryName;

  /// Text showing which library the invitation is for
  ///
  /// In en, this message translates to:
  /// **'for library'**
  String get forLibrary;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ro'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ro':
      return AppLocalizationsRo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
