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

  /// Message when filters return no results
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// Placeholder for book search input
  ///
  /// In en, this message translates to:
  /// **'Search books...'**
  String get searchBooks;

  /// Message when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No books found in this library matching your search.'**
  String get noBooksFoundSearch;

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
  /// **'Sent'**
  String get sentInvitations;

  /// Label for received invitations tab
  ///
  /// In en, this message translates to:
  /// **'Received'**
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

  /// Message when there are no shared libraries
  ///
  /// In en, this message translates to:
  /// **'No shared libraries'**
  String get noSharedLibraries;

  /// Label for more menu button
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// Book title label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Placeholder for title input
  ///
  /// In en, this message translates to:
  /// **'Enter title'**
  String get enterTitle;

  /// Placeholder for author input
  ///
  /// In en, this message translates to:
  /// **'Enter author'**
  String get enterAuthor;

  /// Label for title/author search option
  ///
  /// In en, this message translates to:
  /// **'Search by Title/Author'**
  String get searchByTitleAuthor;

  /// Label for manual book creation option
  ///
  /// In en, this message translates to:
  /// **'Create Manually'**
  String get createManually;

  /// Label for cover image URL input
  ///
  /// In en, this message translates to:
  /// **'Cover Image URL'**
  String get coverImageUrl;

  /// Placeholder for cover URL input
  ///
  /// In en, this message translates to:
  /// **'Enter cover image URL'**
  String get enterCoverUrl;

  /// Label for description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Placeholder for description input
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// Label for price field
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Placeholder for price input
  ///
  /// In en, this message translates to:
  /// **'Enter price'**
  String get enterPrice;

  /// Title for book edit screen
  ///
  /// In en, this message translates to:
  /// **'Edit Book Details'**
  String get editBookDetails;

  /// Label for required field
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Label for optional field
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// Error when title is empty
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// Error when author is empty
  ///
  /// In en, this message translates to:
  /// **'Author is required'**
  String get authorRequired;

  /// Error when ISBN is empty
  ///
  /// In en, this message translates to:
  /// **'ISBN is required'**
  String get isbnRequired;

  /// Error when pages is invalid
  ///
  /// In en, this message translates to:
  /// **'Total pages must be greater than 0'**
  String get pagesRequired;

  /// Error when price is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// Error when pages is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid number of pages'**
  String get invalidPages;

  /// Label for cover image preview
  ///
  /// In en, this message translates to:
  /// **'Cover Preview'**
  String get coverPreview;

  /// Message when no cover image is available
  ///
  /// In en, this message translates to:
  /// **'No cover image'**
  String get noCoverImage;

  /// Message shown while searching
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// Button to add book
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Button to save changes
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Error message when search fails
  ///
  /// In en, this message translates to:
  /// **'Error searching for book'**
  String get searchError;

  /// Error when no search fields are provided
  ///
  /// In en, this message translates to:
  /// **'Please provide at least one search field'**
  String get atLeastOneSearchField;

  /// Title for ISBN search screen
  ///
  /// In en, this message translates to:
  /// **'Search by ISBN'**
  String get searchByIsbn;

  /// OR separator text
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// Button label for adding book manually
  ///
  /// In en, this message translates to:
  /// **'Add Manually'**
  String get addManually;

  /// Button to mark a book as read
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// Label for book rating
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// Label for rating selector
  ///
  /// In en, this message translates to:
  /// **'Select Rating'**
  String get selectRating;

  /// Label for comment field
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// Placeholder for comment input
  ///
  /// In en, this message translates to:
  /// **'Enter your comment (optional)'**
  String get enterComment;

  /// Label for read date
  ///
  /// In en, this message translates to:
  /// **'Read Date'**
  String get readDate;

  /// Label for date picker
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Button to save reading status
  ///
  /// In en, this message translates to:
  /// **'Save Reading'**
  String get saveReading;

  /// Success message when reading is saved
  ///
  /// In en, this message translates to:
  /// **'Reading saved successfully!'**
  String get readingSaved;

  /// Error message when saving reading fails
  ///
  /// In en, this message translates to:
  /// **'Error saving reading'**
  String get readingError;

  /// Label for comments count
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// Label indicating partner has read the book
  ///
  /// In en, this message translates to:
  /// **'Read by Partner'**
  String get readByPartner;

  /// Title for book details screen
  ///
  /// In en, this message translates to:
  /// **'Book Details'**
  String get bookDetails;

  /// Button to mark a book as unread
  ///
  /// In en, this message translates to:
  /// **'Mark as Unread'**
  String get markAsUnread;

  /// Confirmation message for marking book as unread
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark this book as unread?'**
  String get confirmUnread;

  /// Success message when book is marked as unread
  ///
  /// In en, this message translates to:
  /// **'Book marked as unread'**
  String get bookMarkedAsUnread;

  /// Error message when marking book as unread fails
  ///
  /// In en, this message translates to:
  /// **'Error marking book as unread'**
  String get errorMarkingUnread;

  /// Button to confirm an action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Title for profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Title for settings section
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for first name input
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// Label for last name input
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Label for username input
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Placeholder for first name input
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get enterFirstName;

  /// Placeholder for last name input
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get enterLastName;

  /// Placeholder for username input
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get enterUsername;

  /// Label for default currency dropdown
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get defaultCurrency;

  /// Label for default language dropdown
  ///
  /// In en, this message translates to:
  /// **'Default Language'**
  String get defaultLanguage;

  /// Title for password change section
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Label for current password input
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// Label for new password input
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Label for confirm password input
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmPassword;

  /// Placeholder for current password input
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPassword;

  /// Placeholder for new password input
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// Placeholder for confirm password input
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get enterConfirmPassword;

  /// Error when passwords don't match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// Success message when password is changed
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get passwordChanged;

  /// Error message when password change fails
  ///
  /// In en, this message translates to:
  /// **'Error changing password'**
  String get passwordChangeError;

  /// Success message when profile is updated
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// Error message when profile update fails
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get profileUpdateError;

  /// Romanian Leu currency name
  ///
  /// In en, this message translates to:
  /// **'RON (Romanian Leu)'**
  String get ron;

  /// Euro currency name
  ///
  /// In en, this message translates to:
  /// **'EUR (Euro)'**
  String get eur;

  /// US Dollar currency name
  ///
  /// In en, this message translates to:
  /// **'USD (US Dollar)'**
  String get usd;

  /// Button to update profile
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// Badge text for books that are already owned
  ///
  /// In en, this message translates to:
  /// **'OWNED'**
  String get owned;

  /// Message shown on web when the barcode scanner is not available
  ///
  /// In en, this message translates to:
  /// **'Scanner not available on web'**
  String get scannerNotAvailableOnWeb;

  /// Instruction shown on web directing users to use mobile or add manually
  ///
  /// In en, this message translates to:
  /// **'Use the mobile app to scan barcodes, or add a book manually below.'**
  String get scannerWebFallbackMessage;
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
