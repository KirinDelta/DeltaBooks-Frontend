# DeltaBooks Frontend - Complete Application Documentation

## Table of Contents
1. [Non-Technical Overview](#non-technical-overview)
2. [Technical Architecture](#technical-architecture)
3. [Data Models & Structures](#data-models--structures)
4. [API Endpoints](#api-endpoints)
5. [Application Structure](#application-structure)
6. [State Management](#state-management)
7. [UI/UX Design](#uiux-design)
8. [Localization](#localization)
9. [Dependencies](#dependencies)

---

## Non-Technical Overview

### What is DeltaBooks?
DeltaBooks is a **shared book management application designed for couples and partners** to collaboratively track and manage their personal book collections. The app allows users to:

- **Organize Books**: Create and manage personal libraries of books
- **Track Reading Progress**: Mark books as read, add ratings, and write reviews/comments
- **Share Libraries**: Share your library with a partner, allowing both users to see each other's books and reading status
- **Discover Books**: Scan ISBN barcodes or manually search for books to add to your collection
- **View Statistics**: See insights about your reading habits and library

### Key Features
1. **Multiple Libraries**: Users can create and manage multiple personal libraries
2. **Library Sharing**: Share libraries with partners via invitation system
3. **Book Discovery**: 
   - Scan ISBN barcodes using the device camera
   - Manual search by ISBN, title, or author
4. **Reading Tracking**: 
   - Mark books as read/unread
   - Add ratings (1-5 stars) and comments/reviews
   - Track which books you've read and which your partner has read
5. **Comments System**: View and add comments on books, see ratings from all users
6. **Bilingual Support**: Available in English and Romanian

### User Flow
1. User registers/logs in with email and password
2. Creates a library (or receives an invitation to a shared library)
3. Adds books by scanning barcodes or manual entry
4. Marks books as read, adds ratings and reviews
5. Shares library with partner via email invitation
6. Partner accepts invitation and can view the shared library
7. Both users can see each other's reading status and comments

---

## Technical Architecture

### Technology Stack
- **Framework**: Flutter (Dart SDK >= 3.0.0)
- **State Management**: Provider pattern
- **HTTP Client**: `http` package
- **Local Storage**: `shared_preferences`
- **Barcode Scanner**: `mobile_scanner` package
- **Internationalization**: Flutter's built-in `flutter_localizations`

### Architecture Pattern
The app follows the **Provider pattern** with a clear separation of concerns:

```
┌─────────────────────────────────────────┐
│           UI Layer (Screens)            │
│  (home_screen, library_screen, etc.)    │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│      State Management (Providers)       │
│  (auth_provider, book_provider, etc.)   │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│       Service Layer (API Service)       │
│      (api_service.dart - HTTP calls)    │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│         Backend API (REST API)          │
│        (http://localhost:3000)          │
└─────────────────────────────────────────┘
```

### Backend API Configuration
- **Base URL**: `http://localhost:3000`
- **Authentication**: Bearer token authentication (stored in SharedPreferences)
- **API Version**: `/api/v1/` prefix for most endpoints

---

## Data Models & Structures

### 1. User Model (`lib/models/user.dart`)
Represents a user in the system.

**Fields:**
- `id` (int): Unique user identifier
- `email` (String): User's email address

**JSON Structure:**
```json
{
  "id": 1,
  "email": "user@example.com"
}
```

---

### 2. Book Model (`lib/models/book.dart`)
Represents a book entity with metadata and reading status.

**Fields:**
- `id` (int?, nullable): Book identifier
- `isbn` (String): ISBN-10 or ISBN-13
- `title` (String): Book title
- `author` (String): Author name
- `coverUrl` (String?, nullable): URL to book cover image
- `totalPages` (int): Total number of pages
- `description` (String?, nullable): Book description
- `source` (String?, nullable): Source of book data - `'internal'`, `'google_books'`, or `'open_library'`
- `isReadByMe` (bool): Whether the current user has read this book
- `myRating` (int?, nullable): Current user's rating (1-5)
- `myComment` (String?, nullable): Current user's comment/review
- `averageRating` (double?, nullable): Average rating from all users
- `totalCommentsCount` (int): Total number of comments
- `isReadByOthers` (bool): Whether other users have read this book
- `comments` (List<BookComment>): Array of all comments from all users

**JSON Structure:**
```json
{
  "id": 1,
  "isbn": "978-0-123456-78-9",
  "title": "Book Title",
  "author": "Author Name",
  "cover_url": "https://example.com/cover.jpg",
  "total_pages": 350,
  "description": "Book description...",
  "source": "google_books",
  "is_read_by_me": true,
  "my_rating": 5,
  "my_comment": "Great book!",
  "average_rating": 4.5,
  "total_comments_count": 3,
  "is_read_by_others": true,
  "comments": [
    {
      "id": 1,
      "comment": "Excellent read!",
      "rating": 5,
      "user": {
        "id": 1,
        "email": "user@example.com"
      },
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

---

### 3. BookComment Model (`lib/models/book_comment.dart`)
Represents a comment/review on a book.

**Fields:**
- `id` (int): Comment identifier
- `comment` (String): Comment text
- `rating` (int?, nullable): Rating (1-5) provided by the user
- `user` (CommentUser): User who wrote the comment
- `createdAt` (DateTime): When the comment was created
- `updatedAt` (DateTime): When the comment was last updated

**CommentUser Nested Model:**
- `id` (int): User ID
- `email` (String): User email

**JSON Structure:**
```json
{
  "id": 1,
  "comment": "Really enjoyed this book!",
  "rating": 5,
  "user": {
    "id": 1,
    "email": "user@example.com"
  },
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

---

### 4. Library Model (`lib/models/library.dart`)
Represents a book library (collection).

**Fields:**
- `id` (int): Library identifier
- `name` (String): Library name
- `description` (String?, nullable): Library description
- `userId` (int): Owner's user ID
- `createdAt` (DateTime): Creation timestamp
- `updatedAt` (DateTime?, nullable): Last update timestamp
- `shared` (bool): Whether the library is shared with another user
- `books` (List<Book>): Array of books in the library

**JSON Structure:**
```json
{
  "id": 1,
  "name": "My Library",
  "description": "My personal book collection",
  "user_id": 1,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-02T00:00:00Z",
  "shared": false,
  "books": [
    {
      "id": 1,
      "isbn": "978-0-123456-78-9",
      "title": "Book Title",
      ...
    }
  ]
}
```

---

### 5. UserBook Model (`lib/models/user_book.dart`)
Represents the relationship between a user and a book, including reading status and personal metadata.

**Fields:**
- `id` (int): UserBook relationship identifier
- `book` (Book): The book object
- `status` (BookStatus enum): Reading status - `unread`, `reading`, or `finished`
- `rating` (int?, nullable): User's rating (1-5)
- `review` (String?, nullable): User's review text
- `pricePaid` (double?, nullable): Price paid for the book
- `currentPage` (int?, nullable): Current reading page

**BookStatus Enum:**
- `unread`: Book hasn't been started
- `reading`: Book is currently being read
- `finished`: Book has been completed

**JSON Structure:**
```json
{
  "id": 1,
  "book": {
    "id": 1,
    "isbn": "978-0-123456-78-9",
    "title": "Book Title",
    ...
  },
  "status": "finished",
  "rating": 5,
  "review": "Excellent book!",
  "price_paid": 19.99,
  "current_page": 350
}
```

---

### 6. Invitation Model (`lib/models/invitation.dart`)
Represents a library sharing invitation.

**Fields:**
- `id` (int): Invitation identifier
- `senderId` (int): ID of user who sent the invitation
- `receiverId` (int): ID of user who received the invitation
- `libraryId` (int): ID of the library being shared
- `senderEmail` (String): Email of the sender
- `receiverEmail` (String): Email of the receiver
- `libraryName` (String?, nullable): Name of the library being shared
- `status` (String): Invitation status - `'pending'`, `'accepted'`, or `'rejected'`
- `createdAt` (DateTime): When the invitation was created
- `updatedAt` (DateTime?, nullable): When the invitation was last updated

**Computed Properties:**
- `isPending`: Returns `true` if status is `'pending'`
- `isAccepted`: Returns `true` if status is `'accepted'`
- `isRejected`: Returns `true` if status is `'rejected'`

**JSON Structure:**
```json
{
  "id": 1,
  "sender_id": 1,
  "receiver_id": 2,
  "library_id": 1,
  "sender_email": "sender@example.com",
  "receiver_email": "receiver@example.com",
  "library_name": "My Library",
  "status": "pending",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": null
}
```

---

## API Endpoints

### Authentication Endpoints

#### POST `/users/sign_in`
User login.

**Request Body:**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}
```

**Response:** User object + Authorization header with Bearer token

---

#### POST `/users`
User registration.

**Request Body:**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}
```

**Response:** User object + Authorization header with Bearer token

---

### Library Endpoints

#### GET `/api/v1/libraries`
Fetch all libraries (own + shared).

**Query Parameters:** None

**Response:** Array of Library objects
```json
[
  {
    "id": 1,
    "name": "My Library",
    "user_id": 1,
    "shared": false,
    "books": [...],
    ...
  }
]
```

---

#### POST `/api/v1/libraries`
Create a new library.

**Request Body:**
```json
{
  "library": {
    "name": "Library Name",
    "description": "Optional description"
  }
}
```

**Response:** Created Library object

---

#### PUT `/api/v1/libraries/:id`
Update a library.

**Request Body:**
```json
{
  "library": {
    "name": "Updated Name",
    "description": "Updated description"
  }
}
```

**Response:** Updated Library object

---

#### DELETE `/api/v1/libraries/:id`
Delete a library.

**Response:** 200 or 204 on success

---

#### POST `/api/v1/libraries/:libraryId/share_book`
Add a book to a library (create new book or add existing).

**Request Body (New Book):**
```json
{
  "isbn": "978-0-123456-78-9",
  "title": "Book Title",
  "author": "Author Name",
  "cover_url": "https://example.com/cover.jpg",
  "total_pages": 350,
  "description": "Book description",
  "price": 19.99
}
```

**Request Body (Existing Book):**
```json
{
  "book_id": 1,
  "total_pages": 350,
  "price": 19.99
}
```

**Response:** Success response with book data

---

### Book Endpoints

#### POST `/api/v1/books/find`
Find a book by ISBN.

**Request Body:**
```json
{
  "isbn": "978-0-123456-78-9"
}
```

**Response:** Book object

---

#### POST `/api/v1/books/search`
Search for books by ISBN, title, or author.

**Request Body:**
```json
{
  "isbn": "978-0-123456-78-9"
}
```
OR
```json
{
  "title": "Book Title",
  "author": "Author Name"
}
```

**Response:** Book object (404 if not found)

---

### User Book Endpoints

#### GET `/api/v1/user_books`
Fetch user's books.

**Query Parameters:**
- `library_id` (optional): Filter by library ID
- `partner` (optional, boolean): If `true`, fetch partner's books instead

**Response:** Array of UserBook objects

---

#### POST `/api/v1/user_books`
Create a new user_book relationship (mark book as read).

**Request Body:**
```json
{
  "library_id": 1,
  "user_book": {
    "book_id": 1,
    "status": "finished",
    "rating": 5,
    "review": "Great book!",
    "read_at": "2024-01-01T00:00:00Z",
    "pages_read": 350
  }
}
```

**Response:** Created UserBook object

---

#### PUT `/api/v1/user_books/:id`
Update a user_book relationship.

**Request Body:**
```json
{
  "user_book": {
    "status": "finished",
    "rating": 5,
    "review": "Updated review",
    "read_at": "2024-01-01T00:00:00Z",
    "pages_read": 350
  }
}
```

**Response:** Updated UserBook object

---

#### DELETE `/api/v1/user_books/:id`
Delete a user_book relationship (mark book as unread).

**Response:** 200 or 204 on success

---

### Invitation Endpoints

#### GET `/api/v1/invitations`
Fetch invitations.

**Query Parameters:**
- `type`: `'sent'` or `'received'`

**Response:** Array of Invitation objects

---

#### POST `/api/v1/invitations`
Send a library sharing invitation.

**Request Body:**
```json
{
  "invitation": {
    "receiver_id": 2,
    "library_id": 1
  }
}
```

**Response:** Created Invitation object

---

#### PUT `/api/v1/invitations/:id/accept`
Accept an invitation.

**Request Body:** Empty object `{}`

**Response:** Updated Invitation object

---

#### PUT `/api/v1/invitations/:id/reject`
Reject an invitation.

**Request Body:** Empty object `{}`

**Response:** Updated Invitation object

---

#### DELETE `/api/v1/invitations/:id`
Cancel an invitation (delete).

**Response:** 200 or 204 on success

---

#### GET `/api/v1/users/search`
Search for users by email (for sending invitations).

**Query Parameters:**
- `email`: User's email address

**Response:** User object

---

## Application Structure

### Directory Structure
```
lib/
├── l10n/                      # Localization files
│   ├── app_en.arb            # English translations
│   ├── app_ro.arb            # Romanian translations
│   ├── app_localizations.dart # Generated localization code
│   └── app_localizations_en.dart
│   └── app_localizations_ro.dart
│
├── models/                    # Data models
│   ├── book.dart
│   ├── book_comment.dart
│   ├── invitation.dart
│   ├── library.dart
│   ├── user.dart
│   └── user_book.dart
│
├── providers/                 # State management (ChangeNotifiers)
│   ├── auth_provider.dart
│   ├── book_provider.dart
│   ├── invitation_provider.dart
│   ├── library_provider.dart
│   └── locale_provider.dart
│
├── screens/                   # UI screens/pages
│   ├── book_detail_screen.dart
│   ├── book_edit_screen.dart
│   ├── home_screen.dart
│   ├── invitations_screen.dart
│   ├── libraries_screen.dart
│   ├── library_screen.dart
│   ├── login_screen.dart
│   ├── manual_entry_screen.dart
│   ├── scanner_screen.dart
│   ├── share_library_screen.dart
│   └── stats_screen.dart
│
├── services/                  # API service layer
│   └── api_service.dart
│
├── theme/                     # Theme and styling
│   └── app_colors.dart
│
├── widgets/                   # Reusable widgets
│   └── mark_as_read_sheet.dart
│
└── main.dart                  # Application entry point
```

### Screen Descriptions

1. **LoginScreen** (`login_screen.dart`)
   - User authentication (login/register)
   - Email and password input
   - Navigation to HomeScreen on success

2. **HomeScreen** (`home_screen.dart`)
   - Main navigation hub with bottom navigation bar
   - Tab-based navigation: Library, Scanner, Statistics
   - Library selector in app bar
   - Drawer menu for settings and navigation

3. **LibraryScreen** (`library_screen.dart`)
   - Displays books in the selected library
   - Shows user's books and partner's books (if shared library)
   - Book cards with cover images, titles, authors
   - Reading status indicators

4. **BookDetailScreen** (`book_detail_screen.dart`)
   - Detailed view of a single book
   - Book metadata (title, author, description, pages)
   - Reading status, rating, and comments
   - Actions: Mark as read/unread, edit, view comments

5. **BookEditScreen** (`book_edit_screen.dart`)
   - Edit book details before adding to library
   - Manual entry form for book information
   - Add to library functionality

6. **ScannerScreen** (`scanner_screen.dart`)
   - Barcode/ISBN scanner using device camera
   - Scans ISBN and searches for book
   - Navigates to BookEditScreen with scanned book

7. **ManualEntryScreen** (`manual_entry_screen.dart`)
   - Manual book search interface
   - Search by ISBN, title, or author
   - Navigates to BookEditScreen with search results

8. **LibrariesScreen** (`libraries_screen.dart`)
   - Manage libraries (create, edit, delete)
   - List of all user's libraries
   - Library creation and editing forms

9. **ShareLibraryScreen** (`share_library_screen.dart`)
   - Share library with another user
   - Email search and user lookup
   - Send invitation functionality

10. **InvitationsScreen** (`invitations_screen.dart`)
    - View sent and received invitations
    - Accept/reject/cancel invitations
    - Pending invitations list

11. **StatsScreen** (`stats_screen.dart`)
    - Reading statistics and insights
    - Books read count, ratings, etc.

---

## State Management

The app uses the **Provider pattern** for state management. Each provider extends `ChangeNotifier` and manages state for a specific domain.

### Providers

#### 1. AuthProvider (`lib/providers/auth_provider.dart`)
Manages user authentication state.

**State:**
- `_user` (User?): Current authenticated user
- `_isAuthenticated` (bool): Authentication status

**Methods:**
- `login(String email, String password)`: Authenticate user
- `register(String email, String password)`: Register new user
- `logout()`: Clear authentication state
- `checkAuthStatus()`: Check if user is authenticated (via stored token)

**Storage:** Authentication token stored in SharedPreferences as `'auth_token'`

---

#### 2. BookProvider (`lib/providers/book_provider.dart`)
Manages book-related operations and state.

**State:**
- `_myBooks` (List<UserBook>): Current user's books
- `_partnerBooks` (List<UserBook>): Partner's books (for shared libraries)
- `_isLoading` (bool): Loading state

**Methods:**
- `fetchMyBooks({int? libraryId})`: Fetch user's books (optionally filtered by library)
- `fetchPartnerBooks({int? libraryId})`: Fetch partner's books
- `findBookByIsbn(String isbn)`: Find book by ISBN
- `searchBooks({String? isbn, String? title, String? author})`: Search for books
- `addBookToLibrary(...)`: Add book to a library (supports new or existing books)
- `markBookAsRead(...)`: Mark book as read with rating, comment, date
- `markBookAsUnread(...)`: Remove reading status from book

---

#### 3. LibraryProvider (`lib/providers/library_provider.dart`)
Manages library state and operations.

**State:**
- `_libraries` (List<Library>): User's own libraries
- `_sharedLibraries` (List<Library>): Libraries shared with user
- `_selectedLibrary` (Library?): Currently selected own library
- `_selectedSharedLibrary` (Library?): Currently selected shared library
- `_isLoading` (bool): Loading state

**Computed Properties:**
- `allLibraries`: Combined list of own + shared libraries (deduplicated)
- `selectedLibrary`: Returns selected library (own or shared)
- `isSharedLibrary(Library)`: Check if a library is shared

**Methods:**
- `fetchLibraries()`: Fetch all libraries (own + shared)
- `createLibrary(String name, {String? description})`: Create new library
- `updateLibrary(int libraryId, String name, {String? description})`: Update library
- `deleteLibrary(int libraryId)`: Delete library
- `selectLibrary(Library library)`: Set selected library
- `clearSelection()`: Clear library selection

---

#### 4. InvitationProvider (`lib/providers/invitation_provider.dart`)
Manages invitation state and operations.

**State:**
- `_sentInvitations` (List<Invitation>): Invitations sent by user
- `_receivedInvitations` (List<Invitation>): Invitations received by user
- `_isLoading` (bool): Loading state

**Computed Properties:**
- `pendingReceivedCount`: Count of pending received invitations

**Methods:**
- `fetchInvitations()`: Fetch sent and received invitations
- `searchUserByEmail(String email)`: Search for user by email
- `sendInvitation(int receiverId, int libraryId)`: Send library sharing invitation
- `acceptInvitation(int invitationId)`: Accept an invitation
- `rejectInvitation(int invitationId)`: Reject an invitation
- `cancelInvitation(int invitationId)`: Cancel a sent invitation

---

#### 5. LocaleProvider (`lib/providers/locale_provider.dart`)
Manages app language/locale.

**State:**
- `_locale` (Locale): Current locale (default: 'en')

**Methods:**
- `setLocale(Locale locale)`: Set app locale
- `toggleLocale()`: Toggle between English and Romanian
- `_loadLocale()`: Load saved locale from SharedPreferences

**Storage:** Locale preference stored in SharedPreferences as `'locale'`

---

## UI/UX Design

### Design System

#### Color Palette (`lib/theme/app_colors.dart`)
The app uses a "Deep Water" inspired color scheme:

**Primary Colors:**
- `deepSeaBlue` (#1A365D): Primary color for app bars, primary actions
- `deltaTeal` (#2D3748): Primary text and icons
- `goldLeaf` (#D69E2E): Accent color for FAB, ratings, highlights
- `riverMist` (#E2E8F0): Secondary elements, card backgrounds, borders

**Semantic Colors:**
- `white` (#FFFFFF): Backgrounds
- `black` (#000000): Text (when needed)

**Text Colors:**
- `textPrimary` (deltaTeal): Main text
- `textSecondary` (#718096): Secondary text
- `textTertiary` (#A0AEC0): Tertiary text

**Border Colors:**
- `borderLight` (riverMist): Light borders
- `borderMedium` (#CBD5E0): Medium borders
- `borderDark` (#A0AEC0): Dark borders

#### Theme Configuration (`lib/main.dart`)
- **Material Design 3**: Enabled
- **App Bar**: Deep Sea Blue background, white text, no elevation
- **Cards**: Rounded corners (16px), light elevation, white background
- **Buttons**: Rounded (12px), Deep Sea Blue background
- **Input Fields**: Rounded (12px), River Mist fill, Deep Sea Blue focus border
- **Bottom Navigation**: Fixed type, white background, Deep Sea Blue selected items
- **FAB**: Gold Leaf background

### Navigation Structure

```
LoginScreen
    │
    ├─ (on login) ─→ HomeScreen
                          │
                          ├─ LibraryScreen (Tab 0)
                          ├─ ScannerScreen (Tab 1)
                          └─ StatsScreen (Tab 2)
                          │
                          ├─ (Drawer) ─→ LibrariesScreen
                          ├─ (Drawer) ─→ ShareLibraryScreen
                          ├─ (Drawer) ─→ InvitationsScreen
                          │
                          ├─ (From LibraryScreen) ─→ BookDetailScreen
                          │                           ├─ BookEditScreen
                          │                           └─ MarkAsReadSheet (Modal)
                          │
                          ├─ (From ScannerScreen) ─→ BookEditScreen
                          └─ (From ManualEntry) ─→ BookEditScreen
```

---

## Localization

The app supports **English (en)** and **Romanian (ro)**.

### Localization Files
- `lib/l10n/app_en.arb`: English translations
- `lib/l10n/app_ro.arb`: Romanian translations
- Generated files: `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_ro.dart`

### Usage
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.appTitle);
```

### Locale Switching
Users can toggle language via the drawer menu. Preference is saved in SharedPreferences and persists across app restarts.

---

## Dependencies

### Production Dependencies (`pubspec.yaml`)

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Flutter framework |
| `flutter_localizations` | SDK | Internationalization support |
| `cupertino_icons` | ^1.0.6 | iOS-style icons |
| `provider` | ^6.1.1 | State management (Provider pattern) |
| `http` | ^1.1.2 | HTTP client for API calls |
| `mobile_scanner` | ^7.1.4 | Barcode/ISBN scanner |
| `shared_preferences` | ^2.2.2 | Local storage for tokens and preferences |
| `intl` | ^0.20.2 | Internationalization utilities |

### Development Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | SDK | Testing framework |
| `flutter_lints` | ^3.0.0 | Linting rules |

---

## Database Schema (Backend)

*Note: This is inferred from the API responses and data models. The actual database schema is managed by the backend.*

### Inferred Tables

#### `users`
- `id` (int, primary key)
- `email` (string, unique)
- `password_digest` (string) - hashed password

#### `books`
- `id` (int, primary key)
- `isbn` (string, unique)
- `title` (string)
- `author` (string)
- `cover_url` (string, nullable)
- `total_pages` (int)
- `description` (text, nullable)
- `source` (string, nullable) - 'internal', 'google_books', 'open_library'
- `created_at` (timestamp)
- `updated_at` (timestamp)

#### `libraries`
- `id` (int, primary key)
- `name` (string)
- `description` (text, nullable)
- `user_id` (int, foreign key → users.id)
- `shared` (boolean)
- `created_at` (timestamp)
- `updated_at` (timestamp, nullable)

#### `library_books` (Join Table)
- `id` (int, primary key)
- `library_id` (int, foreign key → libraries.id)
- `book_id` (int, foreign key → books.id)
- `total_pages` (int, nullable) - library-specific page count override
- `price` (decimal, nullable)
- `created_at` (timestamp)
- `updated_at` (timestamp)

#### `user_books`
- `id` (int, primary key)
- `user_id` (int, foreign key → users.id)
- `book_id` (int, foreign key → books.id)
- `library_id` (int, foreign key → libraries.id)
- `status` (string) - 'unread', 'reading', 'finished'
- `rating` (int, nullable) - 1-5
- `review` (text, nullable)
- `price_paid` (decimal, nullable)
- `current_page` (int, nullable)
- `read_at` (timestamp, nullable)
- `pages_read` (int, nullable)
- `created_at` (timestamp)
- `updated_at` (timestamp)

#### `book_comments`
- `id` (int, primary key)
- `book_id` (int, foreign key → books.id)
- `user_id` (int, foreign key → users.id)
- `comment` (text)
- `rating` (int, nullable) - 1-5
- `created_at` (timestamp)
- `updated_at` (timestamp)

#### `invitations`
- `id` (int, primary key)
- `sender_id` (int, foreign key → users.id)
- `receiver_id` (int, foreign key → users.id)
- `library_id` (int, foreign key → libraries.id)
- `status` (string) - 'pending', 'accepted', 'rejected'
- `created_at` (timestamp)
- `updated_at` (timestamp, nullable)

---

## External API Integration (Backend)

The backend integrates with external book data APIs (not directly from the frontend):

- **Google Books API**: Used for book metadata lookup
- **Open Library API**: Used as an alternative source for book data

The `Book` model's `source` field indicates which API was used to fetch the book data:
- `'internal'`: Book created manually
- `'google_books'`: Data from Google Books API
- `'open_library'`: Data from Open Library API

---

## Security

### Authentication
- **Method**: Bearer token authentication
- **Token Storage**: SharedPreferences (local device storage)
- **Token Transmission**: Included in `Authorization` header for authenticated requests
- **Token Format**: `Bearer <token>`

### Data Transmission
- **Protocol**: HTTP (development) / HTTPS (production recommended)
- **Content Type**: `application/json`
- **Accept Header**: `application/json`

---

## Development Notes

### API Base URL
Currently configured for local development: `http://localhost:3000`

For production deployment, update the base URL in `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://api.yourdomain.com';
```

### State Management Pattern
The app uses Provider pattern with `ChangeNotifier`:
- Providers extend `ChangeNotifier`
- UI widgets use `Consumer` or `Provider.of` to listen to changes
- `notifyListeners()` is called after state changes

### Error Handling
- API errors are handled in provider methods (typically returning `false` or `null`)
- User-facing error messages are displayed via `ScaffoldMessenger`
- Loading states are managed in providers to prevent UI blocking

---

## Future Enhancements (Potential)

Based on the current structure, potential enhancements could include:

1. **Offline Support**: Cache books and libraries for offline access
2. **Book Recommendations**: Suggest books based on reading history
3. **Reading Goals**: Set and track reading goals
4. **Export/Import**: Export library data or import from other services
5. **Social Features**: Follow other users, see public libraries
6. **Enhanced Statistics**: More detailed reading analytics
7. **Push Notifications**: Notify users of new invitations or comments
8. **Book Groups/Collections**: Organize books into custom collections
9. **Reading Streaks**: Track consecutive days of reading
10. **Dark Mode**: Add dark theme support

---

*Documentation generated based on codebase analysis. Last updated: 2024*
