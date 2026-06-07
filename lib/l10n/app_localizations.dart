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

  /// Tooltip for OCR camera button on a form field
  ///
  /// In en, this message translates to:
  /// **'Scan with camera'**
  String get scanFieldTooltip;

  /// Tooltip for barcode scanner button on ISBN field
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanBarcodeTip;

  /// Message shown while OCR is running
  ///
  /// In en, this message translates to:
  /// **'Extracting text...'**
  String get extractingText;

  /// Shown when OCR finds nothing
  ///
  /// In en, this message translates to:
  /// **'No text detected. Try again.'**
  String get noTextDetected;

  /// Hint shown inside the barcode scanner bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Point camera at barcode'**
  String get pointCameraAtBarcode;

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

  /// Button to add a book to a library
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
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

  /// Button to take a photo with the camera
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Button to pick an image from the gallery
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get chooseFromGallery;

  /// Message shown while image is uploading
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// Error message when image upload fails
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image. Please try again.'**
  String get imageUploadFailed;

  /// Label before the manual cover URL input
  ///
  /// In en, this message translates to:
  /// **'Or enter cover URL manually'**
  String get orEnterUrl;

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

  /// Error shown when the scanner fails to open the camera, typically due to missing permission
  ///
  /// In en, this message translates to:
  /// **'Camera access is required to scan barcodes. Please enable camera permission in your device settings.'**
  String get cameraPermissionDenied;

  /// Button label to retry a failed action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

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

  /// Wishlist tab label
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// Button to add a book to the wishlist
  ///
  /// In en, this message translates to:
  /// **'Add to Wishlist'**
  String get addToWishlist;

  /// Snackbar confirmation after adding to wishlist
  ///
  /// In en, this message translates to:
  /// **'Added to wishlist'**
  String get addedToWishlist;

  /// Button to remove a book from the wishlist
  ///
  /// In en, this message translates to:
  /// **'Remove from Wishlist'**
  String get removeFromWishlist;

  /// Snackbar confirmation after removing from wishlist
  ///
  /// In en, this message translates to:
  /// **'Removed from wishlist'**
  String get removedFromWishlist;

  /// Empty state message for the wishlist screen
  ///
  /// In en, this message translates to:
  /// **'Nothing on your wishlist yet.\nTap + to add a book you want to read.'**
  String get wishlistEmpty;

  /// CTA button to move a wishlist item into a library
  ///
  /// In en, this message translates to:
  /// **'I got it — add to library'**
  String get iGotIt;

  /// Snackbar confirmation after moving wishlist item to library
  ///
  /// In en, this message translates to:
  /// **'Book moved to library'**
  String get movedToLibrary;

  /// Low priority label
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// Medium priority label
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// High priority label
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// Priority field label
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// Note field label on wishlist entry
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get wishlistNote;

  /// Hint text for wishlist note field
  ///
  /// In en, this message translates to:
  /// **'e.g. saw this at the bookstore'**
  String get wishlistNoteHint;

  /// Title for the partner wishlist screen
  ///
  /// In en, this message translates to:
  /// **'Partner\'s Wishlist'**
  String get partnerWishlist;

  /// Snackbar when book is already wishlisted
  ///
  /// In en, this message translates to:
  /// **'Already in your wishlist'**
  String get alreadyInWishlist;

  /// Sort option: date added
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get sortByDate;

  /// Sort option: priority
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get sortByPriority;

  /// Sort option: title
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortByTitle;

  /// Sort button tooltip
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Generic remove button label
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Title for add book confirmation screen
  ///
  /// In en, this message translates to:
  /// **'Add Book'**
  String get addBook;

  /// Section header for destination picker on add book screen
  ///
  /// In en, this message translates to:
  /// **'Add to'**
  String get addTo;

  /// Section header for reading status picker on add book screen
  ///
  /// In en, this message translates to:
  /// **'Reading status'**
  String get readingStatus;

  /// Dashboard section header for in-progress books
  ///
  /// In en, this message translates to:
  /// **'Currently reading'**
  String get currentlyReading;

  /// Empty state for currently reading section
  ///
  /// In en, this message translates to:
  /// **'No books in progress'**
  String get noBooksInProgress;

  /// Dashboard stat card label for total money spent on books
  ///
  /// In en, this message translates to:
  /// **'Money spent'**
  String get moneySpent;

  /// Bottom nav tab label for the home/dashboard tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Bottom nav tab label for the library/shelves tab
  ///
  /// In en, this message translates to:
  /// **'Shelves'**
  String get shelves;

  /// Bottom nav tab label for the profile tab
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Tag shown on shared/partner libraries in the library selector
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shared;

  /// Tooltip for the settings icon that opens library management
  ///
  /// In en, this message translates to:
  /// **'Manage libraries'**
  String get manageLibraries;

  /// Menu item on the You screen that opens the profile editor
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Page count label, e.g. '312 pages'
  ///
  /// In en, this message translates to:
  /// **'{count} pages'**
  String pagesCount(int count);

  /// Button label to trigger the browser camera permission prompt
  ///
  /// In en, this message translates to:
  /// **'Enable Camera Access'**
  String get enableCameraAccess;

  /// Instruction shown on web before the camera permission prompt is triggered
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to allow camera access for scanning.'**
  String get tapToEnableCamera;

  /// Label for the admin panel entry point in the You screen
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// Section header for admin-related menu items
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminSection;

  /// Title for the admin users list screen
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// Title for the admin feature flags screen
  ///
  /// In en, this message translates to:
  /// **'Feature Flags'**
  String get adminFeatureFlags;

  /// Button to suspend a user account
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspend;

  /// Button to unsuspend a user account
  ///
  /// In en, this message translates to:
  /// **'Unsuspend'**
  String get unsuspend;

  /// Status label for a suspended user account
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// Status label for an active user account
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// Confirmation dialog message before suspending a user
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to suspend this user? They will lose access to the app.'**
  String get confirmSuspend;

  /// Confirmation dialog message before unsuspending a user
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unsuspend this user? They will regain access to the app.'**
  String get confirmUnsuspend;

  /// Explanation shown when trying to suspend an admin
  ///
  /// In en, this message translates to:
  /// **'Admin accounts cannot be suspended.'**
  String get cannotSuspendAdmin;

  /// Explanation shown when trying to suspend yourself
  ///
  /// In en, this message translates to:
  /// **'You cannot suspend your own account.'**
  String get cannotSuspendSelf;

  /// Placeholder for the admin user search field
  ///
  /// In en, this message translates to:
  /// **'Search by email...'**
  String get searchUsers;

  /// Label before the status filter chips on the admin users screen
  ///
  /// In en, this message translates to:
  /// **'Filter:'**
  String get filterByStatus;

  /// Title for the admin user detail screen
  ///
  /// In en, this message translates to:
  /// **'User Detail'**
  String get userDetail;

  /// Section header for the user's library memberships on the admin detail screen
  ///
  /// In en, this message translates to:
  /// **'Library Memberships'**
  String get libraryMemberships;

  /// Button to enable a feature flag for a specific user
  ///
  /// In en, this message translates to:
  /// **'Enable for user'**
  String get enableForUser;

  /// Badge/button showing a flag is currently enabled
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get disableFlag;

  /// Badge/button showing a flag is currently disabled
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get enableFlag;

  /// Filter chip label for showing users of all statuses
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allStatuses;

  /// Empty state message on the admin users screen
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsers;

  /// Badge shown on library memberships where the user is the library owner
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerBadge;

  /// Badge shown on library memberships where the user is a member
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberBadge;

  /// Title for the suspend user confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Suspend User'**
  String get suspendUser;

  /// Title for the unsuspend user confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Unsuspend User'**
  String get unsuspendUser;

  /// Snackbar message after successfully suspending a user
  ///
  /// In en, this message translates to:
  /// **'User suspended'**
  String get suspendSuccess;

  /// Snackbar message after successfully unsuspending a user
  ///
  /// In en, this message translates to:
  /// **'User unsuspended'**
  String get unsuspendSuccess;

  /// Error message when suspending a user fails
  ///
  /// In en, this message translates to:
  /// **'Error suspending user'**
  String get errorSuspending;

  /// Error message when unsuspending a user fails
  ///
  /// In en, this message translates to:
  /// **'Error unsuspending user'**
  String get errorUnsuspending;

  /// Label for the date a user joined, shown on the admin user detail screen
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedOn;

  /// Empty state message on the admin feature flags screen
  ///
  /// In en, this message translates to:
  /// **'No feature flags defined.'**
  String get noFeatureFlags;

  /// Short note on the feature flags screen explaining backend endpoints are not yet implemented
  ///
  /// In en, this message translates to:
  /// **'Backend endpoints required'**
  String get featureFlagsAdminNote;

  /// Detailed description on the feature flags screen explaining what is missing from the backend
  ///
  /// In en, this message translates to:
  /// **'Toggle and per-user actions require admin API endpoints (POST /admin/feature_flags/:name/enable|disable|enable_for_user) that are not yet implemented. Use the Flipper UI at /admin/flipper in the meantime.'**
  String get featureFlagsAdminDescription;

  /// State badge label when a feature flag is fully enabled
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get flagOn;

  /// State badge label when a feature flag is fully disabled
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get flagOff;

  /// State badge label when a feature flag is conditionally enabled (actors or percentage)
  ///
  /// In en, this message translates to:
  /// **'Conditional'**
  String get flagConditional;

  /// Button to enable a feature flag for all users
  ///
  /// In en, this message translates to:
  /// **'Enable globally'**
  String get enableGlobally;

  /// Button to disable a feature flag for all users
  ///
  /// In en, this message translates to:
  /// **'Disable globally'**
  String get disableGlobally;

  /// Button that opens the per-user enable/disable sheet for a feature flag
  ///
  /// In en, this message translates to:
  /// **'Manage users'**
  String get manageFlagActors;

  /// Label before the list of actors a flag is enabled for
  ///
  /// In en, this message translates to:
  /// **'Enabled for users:'**
  String get enabledForUsers;

  /// Button to disable a feature flag for a specific user
  ///
  /// In en, this message translates to:
  /// **'Disable for user'**
  String get disableForUser;

  /// Button/dialog title to set the percentage-of-actors gate on a feature flag
  ///
  /// In en, this message translates to:
  /// **'Set % of actors'**
  String get setPercentage;

  /// Hint text for the percentage input field
  ///
  /// In en, this message translates to:
  /// **'0–100'**
  String get percentageHint;

  /// Label showing the current percentage-of-actors gate value
  ///
  /// In en, this message translates to:
  /// **'{percentage}% of actors'**
  String percentageActors(int percentage);

  /// Snackbar message after successfully setting a percentage-of-actors gate
  ///
  /// In en, this message translates to:
  /// **'Percentage updated'**
  String get percentageUpdated;

  /// Snackbar message after clearing a percentage-of-actors gate
  ///
  /// In en, this message translates to:
  /// **'Percentage gate disabled'**
  String get percentageDisabled;

  /// Snackbar message after successfully toggling a feature flag globally
  ///
  /// In en, this message translates to:
  /// **'Flag updated'**
  String get flagUpdated;

  /// Snackbar message when a feature flag update fails
  ///
  /// In en, this message translates to:
  /// **'Error updating flag'**
  String get errorUpdatingFlag;

  /// Validation error shown when the percentage input is out of range
  ///
  /// In en, this message translates to:
  /// **'Enter a value between 0 and 100'**
  String get invalidPercentage;

  /// Snackbar shown after enabling a feature flag for a specific user
  ///
  /// In en, this message translates to:
  /// **'Enabled for {email}'**
  String enableForUserSuccess(String email);

  /// Snackbar shown after disabling a feature flag for a specific user
  ///
  /// In en, this message translates to:
  /// **'Disabled for {email}'**
  String disableForUserSuccess(String email);

  /// AppBar title shown when the user is picking from LLM-suggested candidates for a scanned ISBN
  ///
  /// In en, this message translates to:
  /// **'Select the correct book'**
  String get selectTheCorrectBook;

  /// Button shown in LLM-candidates mode to skip all suggestions and enter book details manually
  ///
  /// In en, this message translates to:
  /// **'None of these'**
  String get noneOfThese;
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
