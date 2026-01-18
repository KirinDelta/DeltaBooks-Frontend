# DeltaBooks Frontend - Complete Application Documentation

## Table of Contents
1. [Non-Technical Overview](#non-technical-overview)
2. [Technical Architecture](#technical-architecture)
3. [Application Structure](#application-structure)
4. [Data Models & Structures](#data-models--structures)
5. [State Management](#state-management)
6. [UI/UX Design System](#uiux-design-system)
7. [Screens & Components](#screens--components)
8. [Widgets](#widgets)
9. [API Integration](#api-integration)
10. [Localization](#localization)
11. [Assets & Resources](#assets--resources)
12. [Dependencies](#dependencies)
13. [Development Notes](#development-notes)

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
7. **Advanced Filtering**: Filter books by read/unread status, "In Circle" (read by partner), and search by title/author
8. **Sorting Options**: Sort books by recent, rating, pages, or title (ascending/descending)

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
- **Date Formatting**: `intl` package

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
- **Content Type**: `application/json`
- **Accept Header**: `application/json`

---

## Application Structure

### Directory Structure
```
lib/
├── l10n/                      # Localization files
│   ├── app_en.arb            # English translations
│   ├── app_ro.arb            # Romanian translations
│   ├── app_localizations.dart # Generated localization code
│   ├── app_localizations_en.dart
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
│   ├── profile_screen.dart
│   ├── scanner_screen.dart
│   ├── search_results_screen.dart
│   ├── share_library_screen.dart
│   └── stats_screen.dart
│
├── services/                  # API service layer
│   └── api_service.dart
│
├── theme/                     # Theme and styling
│   ├── app_colors.dart
│   └── app_images.dart
│
├── widgets/                   # Reusable widgets
│   ├── mark_as_read_sheet.dart
│   ├── pulsing_logo_loader.dart
│   └── user_avatar.dart
│
└── main.dart                  # Application entry point
```

---

## Data Models & Structures

### 1. User Model (`lib/models/user.dart`)
Represents a user in the system.

**Fields:**
- `id` (int): Unique user identifier
- `email` (String): User's email address
- `firstName` (String?, nullable): User's first name
- `lastName` (String?, nullable): User's last name
- `username` (String?, nullable): User's username

**JSON Structure:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "username": "johndoe"
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
        "email": "user@example.com",
        "first_name": "John",
        "last_name": "Doe"
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
- `firstName` (String?, nullable): User's first name
- `lastName` (String?, nullable): User's last name

**JSON Structure:**
```json
{
  "id": 1,
  "comment": "Really enjoyed this book!",
  "rating": 5,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe"
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
- `setLocaleProvider(LocaleProvider)`: Set locale provider reference

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
- `_isAscending` (bool): Sort direction (default: false/descending)

**Computed Properties:**
- `allLibraries`: Combined list of own + shared libraries (deduplicated)
- `selectedLibrary`: Returns selected library (own or shared)
- `isSharedLibrary(Library)`: Check if a library is shared
- `isAscending`: Returns current sort direction

**Methods:**
- `fetchLibraries()`: Fetch all libraries (own + shared)
- `createLibrary(String name, {String? description})`: Create new library
- `updateLibrary(int libraryId, String name, {String? description})`: Update library
- `deleteLibrary(int libraryId)`: Delete library
- `selectLibrary(Library library)`: Set selected library
- `clearSelection()`: Clear library selection
- `toggleSortDirection()`: Toggle between ascending and descending sort
- `filterBooksBySearch(List<Book> books, String query)`: Filter books by search query

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

## UI/UX Design System

### Color Palette (`lib/theme/app_colors.dart`)

The app uses a **"Deep Water"** inspired color scheme:

#### Primary Colors
- **deepSeaBlue** (`#1A365D`): Primary color for app bars, primary actions, buttons
- **deltaTeal** (`#2D3748`): Primary text and icons for high contrast
- **goldLeaf** (`#D69E2E`): Accent color for FAB, ratings, highlights, "READ" badges
- **riverMist** (`#E2E8F0`): Secondary elements, card backgrounds, borders, input fills

#### Semantic Colors
- **white** (`#FFFFFF`): Backgrounds, card colors
- **black** (`#000000`): Text (when needed)
- **scaffoldBackground** (`#F8FAFC`): Very light blue-grey scaffold background

#### Text Colors
- **textPrimary** (`deltaTeal` / `#2D3748`): Main text
- **textSecondary** (`#718096`): Secondary text
- **textTertiary** (`#A0AEC0`): Tertiary text, unselected navigation items

#### Border Colors
- **borderLight** (`riverMist` / `#E2E8F0`): Light borders
- **borderMedium** (`#CBD5E0`): Medium borders
- **borderDark** (`#A0AEC0`): Dark borders

#### Gradients
- **primaryGradient**: Linear gradient from `deepSeaBlue` to `deltaTeal` (top-left to bottom-right)
- **accentGradient**: Linear gradient from `deepSeaBlue` to `#2C5282` (top-left to bottom-right)

---

### Typography

**Font Sizes:**
- App Title: 18px (bold, white)
- Screen Titles: 20px (bold)
- Section Titles: 16px (bold)
- Body Text: 15px (regular)
- Secondary Text: 13px (regular)
- Small Text: 10-12px (regular)
- Avatar Initials: 35% of avatar size

**Font Weights:**
- Bold: 700 (titles, selected items)
- Semi-bold: 600 (section headers)
- Medium: 500 (body emphasis)
- Regular: 400 (body text)

---

### Spacing & Layout

#### Padding Values
- **Screen Padding**: 24px (login screen, modal content)
- **Card Padding**: 16px (book cards, list items)
- **Section Padding**: 16px horizontal, 8-12px vertical
- **Input Padding**: 16px horizontal, 16px vertical
- **Button Padding**: 24px horizontal, 16px vertical
- **Drawer Header**: 24px all sides
- **Modal Bottom Sheet**: 24px all sides

#### Margin Values
- **Card Margin**: 16px horizontal, 8px vertical
- **Element Spacing**: 4px, 8px, 12px, 16px, 24px, 32px
- **Section Spacing**: 24px between major sections
- **List Item Spacing**: 8px vertical

#### Border Radius
- **Cards**: 16px
- **Buttons**: 12px
- **Input Fields**: 12px
- **Chips/Badges**: 20px (rounded)
- **Avatar**: 50% (circular)
- **Modal Bottom Sheet**: 24px top corners
- **Book Cover**: 12px

#### Elevation & Shadows
- **Cards**: 2px elevation, shadow with 0.1 opacity
- **App Bar**: 0px elevation (flat)
- **Bottom Navigation**: 8px elevation
- **FAB**: 4px elevation
- **Drawer Logo Container**: 4px blur, 2px offset, 0.15 opacity

---

### Theme Configuration (`lib/main.dart`)

#### Material Design 3
- **Enabled**: `useMaterial3: true`

#### App Bar Theme
- **Background**: Deep Sea Blue (`#1A365D`)
- **Foreground**: White
- **Elevation**: 0 (flat design)
- **Title Alignment**: Left-aligned (not centered)
- **Surface Tint**: Transparent
- **Icon Color**: White

#### Card Theme
- **Elevation**: 2
- **Border Radius**: 16px
- **Border**: 1px light border (River Mist)
- **Background**: White
- **Margin**: 16px horizontal, 8px vertical
- **Shadow Color**: Delta Teal with 0.1 opacity

#### Button Theme
- **Elevation**: 0
- **Padding**: 24px horizontal, 16px vertical
- **Border Radius**: 12px
- **Background**: Deep Sea Blue
- **Foreground**: White

#### Input Field Theme
- **Filled**: true
- **Fill Color**: River Mist
- **Border Radius**: 12px
- **Border**: Light border (River Mist)
- **Focus Border**: Deep Sea Blue, 2px width
- **Content Padding**: 16px horizontal, 16px vertical

#### Bottom Navigation Theme
- **Background**: White
- **Selected Item Color**: Deep Sea Blue
- **Unselected Item Color**: Text Tertiary (`#A0AEC0`)
- **Elevation**: 8
- **Type**: Fixed (always visible)

#### Floating Action Button Theme
- **Background**: Gold Leaf (`#D69E2E`)
- **Foreground**: White
- **Elevation**: 4

#### Tab Bar Theme
- **Label Color**: Deep Sea Blue
- **Unselected Label Color**: Text Secondary (`#718096`)
- **Indicator Color**: White
- **Indicator Size**: Tab width

---

### Component Specifications

#### Book Card Layout
- **Structure**: Horizontal layout with cover, content, and badges
- **Cover Size**: 60px width × 90px height
- **Cover Border Radius**: 12px
- **Content Area**: Expanded, left-aligned
- **Vertical Divider**: 1px width, River Mist color, 12px horizontal margin
- **READ Badge**: Top-right positioned, Gold Leaf background, white text, 9px font, bold
- **Avatar Badges**: Bottom-right positioned, 24px size, circular, with shadow

#### App Bar Layout
- **Height**: Standard + 48px for library selector
- **Logo**: 45px height, centered horizontally
- **Title**: Below logo, 18px font, bold, white
- **Library Selector**: 48px height, white text, left-aligned with icon

#### Drawer Layout
- **Header**: Deep Sea Blue background, 24px padding
- **Logo Container**: 70px height, white background, 12px border radius, 10px padding, shadow
- **Logo**: Fits within container, centered
- **User Email**: Below logo, 18px font, white, centered
- **Menu Items**: Standard ListTile with icons

#### Bottom Navigation
- **Height**: Standard + SafeArea padding
- **Items**: 3 items (Library, Scanner, Statistics)
- **Item Layout**: Icon (24px) + Label (12px font) vertically stacked
- **Selected State**: Deep Sea Blue color, bold font, background with 0.1 opacity
- **Unselected State**: Text Tertiary color, normal font

#### Floating Filter Bar
- **Position**: Top of screen, fixed
- **Background**: White
- **Shadow**: 8px blur, 2px offset, 0.1 opacity
- **Collapsible**: Expandable/collapsible with animation
- **Search Bar**: Full width, River Mist fill, 12px border radius
- **Sort Options**: 4 chips in a row (Recent, Rating, Pages, Title)
- **Filter Chips**: Horizontal scrollable chips (Unread, Read, In Circle, Surprise Me)

---

## Screens & Components

### 1. LoginScreen (`lib/screens/login_screen.dart`)

**Purpose**: User authentication (login/register)

**Layout:**
- **Background**: Deep Sea Blue (`#1A365D`)
- **Content**: Centered white card with rounded corners
- **Card Width**: 85% of screen width
- **Card Border Radius**: 32px
- **Card Padding**: 32px all sides
- **Card Shadow**: 16px blur, 4px offset, 0.1 opacity

**Components:**
1. **Login Image** (Top)
   - Asset: `AppImages.login`
   - Height: 135px
   - Top Margin: 30px
   - Bottom Margin: 24px

2. **Email Input Field**
   - Label: "Email"
   - Fill Color: River Mist
   - Border Radius: 12px
   - Focus Border: Deep Sea Blue, 2px width

3. **Password Input Field**
   - Label: "Password"
   - Obscure Text: true
   - Same styling as email field
   - Spacing: 16px below email

4. **Login/Register Button**
   - Full width
   - Background: Deep Sea Blue
   - Foreground: White
   - Height: 52px
   - Border Radius: 12px
   - Spacing: 32px below password

5. **Toggle Link**
   - Text Button style
   - Toggles between login/register mode
   - Spacing: 16px below button

**Animations:**
- Fade-in animation on load (800ms duration, easeIn curve)

---

### 2. HomeScreen (`lib/screens/home_screen.dart`)

**Purpose**: Main navigation hub with bottom navigation bar

**Layout:**
- **App Bar**: Deep Sea Blue background with logo and library selector
- **Body**: IndexedStack with 3 tabs (Library, Scanner, Statistics)
- **Bottom Navigation**: Fixed bottom bar with 3 items

**App Bar Structure:**
1. **Logo Section** (Top)
   - Hero widget with tag 'app_logo'
   - Image: `AppImages.logo`
   - Height: 45px
   - Bottom Spacing: 8px

2. **Title**
   - Text: App title from localization
   - Font: 18px, bold, white
   - Below logo

3. **Library Selector** (Bottom Preferred Size)
   - Height: 48px
   - Background: Transparent (inherits app bar color)
   - Content: Row with icon, library name, dropdown arrow
   - Icon: Library books icon, 20px, white70
   - Text: Selected library name, 16px, white
   - Shared Indicator: "(Shared)" text if applicable, 12px, white70, italic
   - Dropdown Icon: Arrow down, 24px, white70
   - Tap Action: Opens library selector bottom sheet

**Drawer Menu:**
- **Header**: Deep Sea Blue background, 24px padding
  - Logo container: 70px height, white background, 12px radius, 10px padding, shadow
  - Logo: Centered, fits container
  - User email: 18px, white, centered, 20px below logo
- **Menu Items**:
  - My Libraries (Settings icon)
  - Share Library (Person add icon)
  - Invitations (Mail icon with badge if pending)
  - Profile (Person icon)
  - Divider
  - Logout (Logout icon, error color)

**Bottom Navigation:**
- **Background**: White
- **Shadow**: 10px blur, -2px offset, 0.05 opacity
- **Items**: 3 items in a row, space-around alignment
- **Item Structure**:
  - Container with padding (12px vertical)
  - Selected: Background with 0.1 opacity primary color, 8px border radius
  - Icon: 24px, selected = primary color, unselected = onSurfaceVariant
  - Label: 12px font, 4px below icon
  - Selected: Bold, primary color
  - Unselected: Normal, onSurfaceVariant color

**Tabs:**
1. **Library** (Index 0): LibraryScreen
2. **Scanner** (Index 1): ScannerScreen
3. **Statistics** (Index 2): StatsScreen

---

### 3. LibraryScreen (`lib/screens/library_screen.dart`)

**Purpose**: Displays books in the selected library with filtering and sorting

**Layout:**
- **Structure**: Stack with floating filter bar and scrollable book list
- **Filter Bar**: Fixed at top, collapsible
- **Book List**: Scrollable, with padding for filter bar when collapsed

**Floating Filter Bar:**
- **Position**: Top of screen
- **Background**: White
- **Shadow**: 8px blur, 2px offset, 0.1 opacity
- **Collapse/Expand Header**:
  - Padding: 16px horizontal, 12px vertical
  - Icon: Expand less/more, Delta Teal
  - Title: "Search & Filter", 16px, bold, Delta Teal
  - Active Indicators: Search query chip, filter count chip (when collapsed)

**Search Bar:**
- **Padding**: 16px horizontal, 8px vertical
- **Input**: Full width
  - Hint: "Search books..."
  - Prefix Icon: Search, Delta Teal
  - Suffix Icon: Clear button (when query exists)
  - Fill Color: River Mist with 0.5 opacity
  - Border Radius: 12px
  - Focus Border: Delta Teal, 2px width

**Sort Options:**
- **Container**: Full width, River Mist background (0.3 opacity), bottom border
- **Padding**: 16px horizontal, 8px vertical
- **Title**: "Sort By", 14px, bold, Delta Teal
- **Chips**: 4 chips in a row (Recent, Rating, Pages, Title)
  - Selected: Deep Sea Blue background (0.2 opacity), Deep Sea Blue border
  - Unselected: River Mist background (0.5 opacity), River Mist border
  - Icon: 16px, left of label
  - Direction Toggle: Arrow up/down icon when selected
  - Border Radius: 20px
  - Padding: 12px horizontal, 8px vertical

**Filter Chips:**
- **Container**: 16px horizontal, 12px vertical padding
- **Scroll Direction**: Horizontal
- **Chips**:
  - Unread: FilterChip, selected = Deep Sea Blue
  - Read: FilterChip, selected = Gold Leaf
  - In Circle: FilterChip, selected = Deep Sea Blue
  - Surprise Me: FilterChip with shuffle icon, Gold Leaf color
  - Spacing: 8px between chips

**Book Cards:**
- **Container**: White background, 16px border radius, 1px grey border
- **Margin**: 16px horizontal, 8px vertical
- **Shadow**: 12px blur, 4px offset, 0.05 opacity
- **Padding**: 16px all sides
- **Layout**: Row with cover, content, divider, spacer
- **Cover**:
  - Size: 60px × 90px
  - Border Radius: 12px
  - Fallback: Grey container with book icon
- **Sub-Cover Metadata**:
  - Pages count: 10px font, text tertiary, with menu_book icon
  - Width: 60px, centered
  - Spacing: 6px below cover
- **Content Area** (Expanded):
  - Title: 15px, bold, Delta Teal, max 2 lines, ellipsis
  - Author: 13px, text secondary, 4px below title
  - Rating Row: 8px below author
    - Stars: 5 stars, 14px, Gold Leaf color
    - Rating Value: 14px, Delta Teal, bold (if rating exists)
    - Comments: Chat bubble icon (14px) + count, 12px spacing from rating
- **Vertical Divider**: 1px, River Mist, 12px horizontal margin
- **Spacer**: 50px width for badges
- **READ Badge** (Positioned top-right):
  - Background: Gold Leaf
  - Text: "READ", 9px, bold, white
  - Padding: 8px horizontal, 4px vertical
  - Border Radius: 20px
  - Position: 8px from top and right
- **Avatar Badges** (Positioned bottom-right):
  - Size: 24px, circular
  - Background: Deep Sea Blue
  - Initials: White text, 35% of size
  - Shadow: 4px blur, 2px offset, 0.1 opacity
  - Spacing: 4px between avatars
  - Position: 8px from bottom and right

**Empty States:**
- **Empty Library**: Centered text, title large style
- **No Results**: Centered text, title large style
- **Loading**: Circular progress indicator, centered

**Pull to Refresh**: Enabled

---

### 4. BookDetailScreen (`lib/screens/book_detail_screen.dart`)

**Purpose**: Detailed view of a single book with metadata, comments, and actions

**Layout:**
- **App Bar**: Standard app bar with back button
- **Body**: Scrollable content with book details

**Components:**
1. **Book Cover** (Top)
   - Large cover image or placeholder
   - Centered horizontally
   - Border radius: 12px

2. **Book Metadata**:
   - Title: Large, bold
   - Author: Secondary text
   - Description: Body text
   - Pages: With icon
   - ISBN: Secondary text

3. **Reading Status**:
   - READ badge if read by user
   - Partner read indicator if read by others

4. **Rating Section**:
   - Average rating with stars
   - User's rating (if exists)

5. **Comments Section**:
   - Comment count
   - List of comments with user avatars
   - Each comment shows: user avatar, name, rating, comment text, date

6. **Action Buttons**:
   - Mark as Read (opens bottom sheet)
   - Mark as Unread (with confirmation)
   - Edit Book (if applicable)

**Mark as Read Sheet**:
- **Type**: Draggable bottom sheet
- **Initial Size**: 85% of screen
- **Min Size**: 50%
- **Max Size**: 95%
- **Background**: River Mist
- **Content**:
  - Handle bar: 40px width, 4px height, border medium color
  - Title: "Mark as Read", large, bold, Delta Teal
  - Book title: Body medium, text secondary
  - Rating selector: 5 stars, 40px size, Gold Leaf color
  - Comment field: Multi-line text field, 4 lines max, white background
  - Date picker: White container with calendar icon
  - Save button: Gold Leaf background, white text, full width, 16px vertical padding

---

### 5. ScannerScreen (`lib/screens/scanner_screen.dart`)

**Purpose**: Barcode/ISBN scanner using device camera

**Layout:**
- **Camera View**: Full screen camera preview
- **Overlay**: Instructions and manual entry option
- **Actions**: Manual entry button, cancel button

**Components:**
- Camera scanner view (mobile_scanner)
- Instruction text: "Scan the book's barcode"
- Manual entry button: Opens manual entry screen
- Cancel button: Returns to previous screen

---

### 6. ManualEntryScreen (`lib/screens/manual_entry_screen.dart`)

**Purpose**: Manual book search interface

**Layout:**
- **Search Options**: ISBN search or Title/Author search
- **Input Fields**: Based on selected search type
- **Search Button**: Triggers book search
- **Results**: Navigate to BookEditScreen with results

**Components:**
- Search type selector (ISBN or Title/Author)
- Input fields for selected search type
- Search button
- Loading indicator
- Error messages

---

### 7. BookEditScreen (`lib/screens/book_edit_screen.dart`)

**Purpose**: Edit book details before adding to library

**Layout:**
- **Form**: Scrollable form with book fields
- **Cover Preview**: Shows cover image if URL provided
- **Fields**: Title, Author, ISBN, Pages, Description, Cover URL, Price
- **Actions**: Add to Library button, Cancel button

**Components:**
- Text input fields for all book properties
- Cover image preview (if URL provided)
- Required/optional field indicators
- Validation messages
- Add/Save button

---

### 8. LibrariesScreen (`lib/screens/libraries_screen.dart`)

**Purpose**: Manage libraries (create, edit, delete)

**Layout:**
- **App Bar**: "My Libraries" title, create button
- **List**: List of user's libraries
- **Empty State**: Message to create first library

**Components:**
- Library list with name and description
- Create library button/form
- Edit library option
- Delete library option (with confirmation)
- Empty state message

---

### 9. ShareLibraryScreen (`lib/screens/share_library_screen.dart`)

**Purpose**: Share library with another user

**Layout:**
- **Search**: Email search input
- **User Display**: Shows found user
- **Actions**: Send invitation button

**Components:**
- Email search field
- User information display (if found)
- Send invitation button
- Success/error messages

---

### 10. InvitationsScreen (`lib/screens/invitations_screen.dart`)

**Purpose**: View sent and received invitations

**Layout:**
- **Tabs**: Sent and Received tabs
- **List**: List of invitations with status
- **Actions**: Accept, Reject, Cancel buttons

**Components:**
- Tab bar (Sent/Received)
- Invitation cards with:
  - Sender/Receiver email
  - Library name
  - Status badge
  - Action buttons (Accept/Reject/Cancel)
- Empty state message

---

### 11. StatsScreen (`lib/screens/stats_screen.dart`)

**Purpose**: Reading statistics and insights

**Layout:**
- **Cards**: Statistics cards in a grid
- **Metrics**: Total books, pages read, library value, etc.

**Components:**
- Statistic cards with icons and values
- Charts/graphs (if implemented)
- Loading state
- Error state

---

### 12. ProfileScreen (`lib/screens/profile_screen.dart`)

**Purpose**: User profile and settings

**Layout:**
- **Form**: User information form
- **Sections**: Personal info, preferences, password change

**Components:**
- First name, last name, username fields
- Default currency selector
- Default language selector
- Change password section
- Update profile button

---

## Widgets

### 1. PulsingLogoLoader (`lib/widgets/pulsing_logo_loader.dart`)

**Purpose**: Animated loading widget with pulsing logo

**Properties:**
- `size` (double): Logo size, default 60px
- `color` (Color?, nullable): Optional color tint

**Animation:**
- Duration: 1200ms
- Animation: Opacity and scale (0.7 to 1.0)
- Curve: easeInOut
- Repeats: Reverse loop

**Layout:**
- Centered logo
- Opacity animation
- Scale animation

---

### 2. UserAvatar (`lib/widgets/user_avatar.dart`)

**Purpose**: Circular avatar with user initials

**Properties:**
- `firstName` (String?, nullable): User's first name
- `lastName` (String?, nullable): User's last name
- `email` (String?, nullable): User's email (fallback)
- `size` (double): Avatar size, default 32px
- `fallbackText` (String?, nullable): Fallback text, default '?'

**Initials Logic:**
1. First name + Last name → "JD" (John Doe)
2. First name only → "J"
3. Last name only → "D"
4. Email → Extract from local part (e.g., "john.doe@email.com" → "JD")
5. Fallback → "?"

**Styling:**
- Background: Deep Sea Blue
- Text: White, 35% of size, medium weight
- Shape: Circle
- Letter spacing: 0.3
- Line height: 1.0

---

### 3. MarkAsReadSheet (`lib/widgets/mark_as_read_sheet.dart`)

**Purpose**: Bottom sheet for marking book as read with rating and comment

**Properties:**
- `book` (Book): Book to mark as read
- `libraryId` (int): Library ID

**Layout:**
- **Container**: River Mist background, 20px top border radius, 24px padding
- **Handle Bar**: 40px width, 4px height, border medium, centered, 16px bottom margin
- **Title**: "Mark as Read", title large, bold, Delta Teal
- **Book Title**: Body medium, text secondary, 8px below title
- **Rating Section**: 24px below book title
  - Label: "Select Rating", title small, bold, Delta Teal
  - Stars: 5 stars in a row, 40px size, Gold Leaf, centered, 12px below label
- **Comment Section**: 24px below rating
  - Label: "Comment", title small, bold, Delta Teal
  - Field: Multi-line (4 lines), white background, 12px border radius, 8px below label
- **Date Section**: 24px below comment
  - Label: "Read Date", title small, bold, Delta Teal
  - Picker: White container, 12px border radius, calendar icon, 8px below label
- **Save Button**: 24px below date, full width, Gold Leaf background, white text, 16px vertical padding, 12px border radius

**State:**
- Pre-populates with existing rating and comment if book is already read
- Default date: Current date
- Loading state during save

---

## API Integration

### API Service (`lib/services/api_service.dart`)

**Base Configuration:**
- **Base URL**: `http://localhost:3000`
- **Content Type**: `application/json`
- **Accept**: `application/json`
- **Authentication**: Bearer token in Authorization header

**Methods:**
- `post(String endpoint, Map<String, dynamic> body)`: POST request
- `get(String endpoint)`: GET request
- `put(String endpoint, Map<String, dynamic> body)`: PUT request
- `delete(String endpoint)`: DELETE request
- `patch(String endpoint, Map<String, dynamic> body)`: PATCH request

**Token Management:**
- Token retrieved from SharedPreferences (`'auth_token'`)
- Automatically included in headers if available

---

### API Endpoints

#### Authentication Endpoints

**POST `/users/sign_in`**
- User login
- Request: `{ "user": { "email": "...", "password": "..." } }`
- Response: User object + Authorization header with Bearer token

**POST `/users`**
- User registration
- Request: `{ "user": { "email": "...", "password": "..." } }`
- Response: User object + Authorization header with Bearer token

---

#### Library Endpoints

**GET `/api/v1/libraries`**
- Fetch all libraries (own + shared)
- Response: Array of Library objects with books

**POST `/api/v1/libraries`**
- Create a new library
- Request: `{ "library": { "name": "...", "description": "..." } }`
- Response: Created Library object

**PUT `/api/v1/libraries/:id`**
- Update a library
- Request: `{ "library": { "name": "...", "description": "..." } }`
- Response: Updated Library object

**DELETE `/api/v1/libraries/:id`**
- Delete a library
- Response: 200 or 204 on success

**POST `/api/v1/libraries/:libraryId/share_book`**
- Add a book to a library
- Request (New Book): `{ "isbn": "...", "title": "...", "author": "...", "cover_url": "...", "total_pages": ..., "description": "...", "price": ... }`
- Request (Existing Book): `{ "book_id": ..., "total_pages": ..., "price": ... }`
- Response: Success response with book data

---

#### Book Endpoints

**POST `/api/v1/books/find`**
- Find a book by ISBN
- Request: `{ "isbn": "..." }`
- Response: Book object

**POST `/api/v1/books/search`**
- Search for books by ISBN, title, or author
- Request: `{ "isbn": "..." }` OR `{ "title": "...", "author": "..." }`
- Response: Book object (404 if not found)

---

#### User Book Endpoints

**GET `/api/v1/user_books`**
- Fetch user's books
- Query Parameters:
  - `library_id` (optional): Filter by library ID
  - `partner` (optional, boolean): If `true`, fetch partner's books
- Response: Array of UserBook objects

**POST `/api/v1/user_books`**
- Create a new user_book relationship (mark book as read)
- Request: `{ "library_id": ..., "user_book": { "book_id": ..., "status": "finished", "rating": ..., "review": "...", "read_at": "...", "pages_read": ... } }`
- Response: Created UserBook object

**PUT `/api/v1/user_books/:id`**
- Update a user_book relationship
- Request: `{ "user_book": { "status": "...", "rating": ..., "review": "...", "read_at": "...", "pages_read": ... } }`
- Response: Updated UserBook object

**DELETE `/api/v1/user_books/:id`**
- Delete a user_book relationship (mark book as unread)
- Response: 200 or 204 on success

---

#### Invitation Endpoints

**GET `/api/v1/invitations`**
- Fetch invitations
- Query Parameters:
  - `type`: `'sent'` or `'received'`
- Response: Array of Invitation objects

**POST `/api/v1/invitations`**
- Send a library sharing invitation
- Request: `{ "invitation": { "receiver_id": ..., "library_id": ... } }`
- Response: Created Invitation object

**PUT `/api/v1/invitations/:id/accept`**
- Accept an invitation
- Request: `{}`
- Response: Updated Invitation object

**PUT `/api/v1/invitations/:id/reject`**
- Reject an invitation
- Request: `{}`
- Response: Updated Invitation object

**DELETE `/api/v1/invitations/:id`**
- Cancel an invitation
- Response: 200 or 204 on success

**GET `/api/v1/users/search`**
- Search for users by email
- Query Parameters:
  - `email`: User's email address
- Response: User object

---

## Localization

### Supported Languages
- **English (en)**: Default language
- **Romanian (ro)**: Secondary language

### Localization Files
- `lib/l10n/app_en.arb`: English translations (655 entries)
- `lib/l10n/app_ro.arb`: Romanian translations (166 entries)
- Generated files:
  - `app_localizations.dart`: Base localization class
  - `app_localizations_en.dart`: English implementation
  - `app_localizations_ro.dart`: Romanian implementation

### Usage
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.appTitle);
```

### Locale Switching
- Users can toggle language via drawer menu or profile screen
- Preference saved in SharedPreferences as `'locale'`
- Persists across app restarts
- Managed by `LocaleProvider`

### Key Localized Strings
- App title, navigation labels
- Form labels and placeholders
- Button labels
- Error messages
- Status labels
- Empty state messages
- Confirmation dialogs

---

## Assets & Resources

### Images (`lib/theme/app_images.dart`)

**Logo** (`assets/images/logo.png`)
- Used in: App bar, drawer header, loading states
- Format: PNG
- Display: Various sizes (45px in app bar, 70px container in drawer)

**Login Image** (`assets/images/login.png`)
- Used in: Login screen
- Format: PNG
- Display: 135px height, centered

### Asset Configuration (`pubspec.yaml`)
```yaml
flutter:
  assets:
    - assets/images/
```

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

## Navigation Structure

```
LoginScreen
    │
    ├─ (on login) ─→ HomeScreen
                          │
                          ├─ LibraryScreen (Tab 0)
                          │   └─ BookDetailScreen
                          │       ├─ MarkAsReadSheet (Modal)
                          │       └─ BookEditScreen
                          │
                          ├─ ScannerScreen (Tab 1)
                          │   └─ BookEditScreen
                          │
                          ├─ StatsScreen (Tab 2)
                          │
                          ├─ (Drawer) ─→ LibrariesScreen
                          │
                          ├─ (Drawer) ─→ ShareLibraryScreen
                          │
                          ├─ (Drawer) ─→ InvitationsScreen
                          │
                          └─ (Drawer) ─→ ProfileScreen
```

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
- Providers are initialized in `main.dart` using `MultiProvider`

### Error Handling
- API errors are handled in provider methods (typically returning `false` or `null`)
- User-facing error messages are displayed via `ScaffoldMessenger`
- Loading states are managed in providers to prevent UI blocking
- Network errors are caught and displayed appropriately

### Performance Considerations
- Books are included in library API responses (no separate fetch needed)
- IndexedStack used for bottom navigation (preserves tab state)
- Hero animations for logo transitions
- Pull-to-refresh for manual data updates
- Efficient list rendering with ListView.builder

### Security
- **Authentication**: Bearer token stored in SharedPreferences
- **Token Transmission**: Included in `Authorization` header
- **Token Format**: `Bearer <token>`
- **Data Transmission**: HTTP (development) / HTTPS (production recommended)

### Platform Support
- **iOS**: Full support (iOS-specific configurations in `ios/` directory)
- **Android**: Full support (Android-specific configurations)
- **Web**: Supported (web configurations in `web/` directory)
- **macOS**: Supported (macOS-specific configurations in `macos/` directory)

---

## Future Enhancements (Potential)

Based on the current structure, potential enhancements could include:

1. **Offline Support**: Cache books and libraries for offline access
2. **Book Recommendations**: Suggest books based on reading history
3. **Reading Goals**: Set and track reading goals
4. **Export/Import**: Export library data or import from other services
5. **Social Features**: Follow other users, see public libraries
6. **Enhanced Statistics**: More detailed reading analytics with charts
7. **Push Notifications**: Notify users of new invitations or comments
8. **Book Groups/Collections**: Organize books into custom collections
9. **Reading Streaks**: Track consecutive days of reading
10. **Dark Mode**: Add dark theme support
11. **Book Cover Upload**: Allow users to upload custom book covers
12. **Reading Progress Tracking**: Track current page while reading
13. **Book Notes**: Add private notes to books
14. **Reading Time Estimation**: Calculate estimated reading time
15. **Book Recommendations**: AI-powered book suggestions

---

*Documentation generated based on comprehensive codebase analysis. Last updated: 2024*
