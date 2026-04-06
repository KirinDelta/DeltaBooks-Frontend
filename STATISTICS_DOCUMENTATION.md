# Statistics Feature - Technical Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture & Design](#architecture--design)
3. [API Integration](#api-integration)
4. [Data Model](#data-model)
5. [UI Implementation](#ui-implementation)
6. [State Management](#state-management)
7. [Localization](#localization)
8. [Styling & Theming](#styling--theming)
9. [Error Handling](#error-handling)
10. [Navigation Integration](#navigation-integration)
11. [Technical Details](#technical-details)
12. [Future Enhancements](#future-enhancements)

---

## Overview

The Statistics feature in DeltaBooks provides users with comprehensive insights into their reading habits and library metrics. The feature displays aggregated statistics including pages read, library value, total books, and monthly reading progress. Statistics can be displayed for individual users as well as combined statistics from partner libraries in a shared library scenario.

### Key Features
- **Monthly Reading Progress**: Pages read by the current user in the current month
- **Total Library Value**: Combined monetary value of all books (in RON currency)
- **Total Books**: Count of all books in combined libraries
- **Total Pages Read**: Aggregate pages read across all libraries
- **Partner Statistics Support**: Backend provides separate user and partner statistics, enabling future partner-specific displays

### Location in Application
- **Screen File**: `lib/screens/stats_screen.dart`
- **Navigation Tab**: Third tab (Index 2) in the main bottom navigation bar
- **Navigation Icon**: Bar chart icon (`Icons.bar_chart`)
- **Access Point**: Accessible from the home screen via bottom navigation

---

## Architecture & Design

### Component Structure

```
StatsScreen (StatefulWidget)
├── State Management
│   ├── _stats (Map<String, dynamic>?)
│   └── _isLoading (bool)
├── Lifecycle Methods
│   ├── initState() - Triggers data loading
│   └── build() - Renders UI
├── Data Loading
│   └── _loadStats() - Async API call
└── UI Components
    ├── Loading State (CircularProgressIndicator)
    ├── Error State (Text with localized error message)
    └── Stats Display
        └── _buildStatCard() - Reusable stat card widget
```

### Design Pattern
- **StatefulWidget**: Manages local component state
- **Direct API Integration**: Uses `ApiService` directly (no provider pattern for statistics)
- **Stateless Display**: Stat cards are built as reusable stateless widgets
- **Declarative UI**: Flutter's reactive UI pattern with `setState()` for state updates

---

## API Integration

### Endpoint Details

**Endpoint**: `GET /api/v1/dashboard`

**Base URL**: `http://localhost:3000` (configurable in `ApiService`)

**Authentication**: Bearer token authentication required
- Token retrieved from `SharedPreferences` under key `'auth_token'`
- Sent in `Authorization` header as `Bearer {token}`

**HTTP Method**: `GET`

**Headers**:
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

### Response Structure

The API returns a JSON object with the following structure:

```json
{
  "user": {
    "pages_read": 450
  },
  "partner": {
    "pages_read": 320
  },
  "combined": {
    "money_spent": 1250.75,
    "total_books": 87,
    "pages_read": 15230
  }
}
```

#### Response Fields

**`user`** (Map<String, dynamic>?):
- `pages_read` (int?): Number of pages read by the current user this month

**`partner`** (Map<String, dynamic>?):
- `pages_read` (int?): Number of pages read by the partner this month (optional, for shared library scenarios)

**`combined`** (Map<String, dynamic>?):
- `money_spent` (double?): Total monetary value of all books in combined libraries (in RON)
- `total_books` (int?): Total count of books across all libraries
- `pages_read` (int?): Total pages read across all libraries (all-time)

### API Service Integration

**Service Class**: `ApiService` (`lib/services/api_service.dart`)

**Method Used**: `ApiService.get(String endpoint)`

**Implementation**:
```dart
final apiService = ApiService();
final response = await apiService.get('/api/v1/dashboard');
```

**Response Handling**:
- Success (200): JSON decoded and stored in `_stats` state
- Error: Loading state set to `false`, `_stats` remains `null`
- Network Exception: Caught silently, loading state updated

### Request Flow

```
User Opens Stats Screen
    ↓
initState() called
    ↓
_loadStats() invoked
    ↓
ApiService.get('/api/v1/dashboard')
    ↓
HTTP GET Request with Bearer Token
    ↓
Backend API Processes Request
    ↓
JSON Response Returned
    ↓
jsonDecode(response.body)
    ↓
setState() updates _stats and _isLoading
    ↓
UI Rebuilds with Statistics
```

---

## Data Model

### Statistics Data Structure

The statistics data is stored as a `Map<String, dynamic>?` in the screen's state. No dedicated model class exists currently, making the structure flexible but requiring careful null-safety handling.

#### Typed Data Access Pattern

The code uses safe navigation with null coalescing:

```dart
final combined = (_stats!['combined'] as Map<String, dynamic>?) ?? <String, dynamic>{};
final user = (_stats!['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
final partner = (_stats!['partner'] as Map<String, dynamic>?) ?? <String, dynamic>{};
```

#### Field Extraction

**User Statistics**:
- `user['pages_read']` → Pages read this month by current user

**Combined Statistics**:
- `combined['money_spent']` → Total library value (double, formatted as RON)
- `combined['total_books']` → Total book count (int)
- `combined['pages_read']` → Total pages read all-time (int)

**Partner Statistics** (Extracted but Not Currently Displayed):
- `partner['pages_read']` → Pages read this month by partner

#### Default Values

All statistics use null-safe defaults:
- Numeric values default to `0` or `0.0` if null
- Maps default to empty `Map<String, dynamic>` if null

---

## UI Implementation

### Screen Layout

```
StatsScreen
└── SingleChildScrollView (padding: 16)
    └── Column (crossAxisAlignment: stretch)
        ├── StatCard (Pages Read This Month - User)
        ├── SizedBox (height: 16)
        ├── StatCard (Total Library Value - Combined)
        ├── SizedBox (height: 16)
        ├── StatCard (Total Books - Combined)
        ├── SizedBox (height: 16)
        └── StatCard (Total Pages Read - Combined)
```

### State Rendering

#### Loading State
```dart
if (_isLoading) {
  return const Center(child: CircularProgressIndicator());
}
```

#### Error/Empty State
```dart
if (_stats == null) {
  return Center(child: Text(l10n.statsError));
}
```

#### Success State
Vertical stack of stat cards with consistent spacing.

### Stat Card Component

**Widget**: `_buildStatCard(BuildContext context, String title, String value, IconData icon)`

**Structure**:
```
Card
└── Container
    ├── Decoration
    │   ├── BorderRadius (16px)
    │   ├── Border (1px, borderLight color)
    │   └── LinearGradient (deepSeaBlue → deltaTeal, 10% → 5% opacity)
    └── Column (vertical)
        ├── Container (Icon Container)
        │   ├── Padding (12px all)
        │   ├── Decoration
        │   │   ├── Color (deepSeaBlue, 15% opacity)
        │   │   ├── Shape (circle)
        │   │   └── Border (1px, borderLight)
        │   └── Icon (32px size, deepSeaBlue color)
        ├── SizedBox (height: 16)
        ├── Text (Title) - titleMedium style, textSecondary color, centered
        ├── SizedBox (height: 8)
        └── Text (Value) - headlineMedium style, deepSeaBlue color, bold
```

#### Card Styling Details

**Card Container**:
- Padding: `24.0` all sides
- Border Radius: `16px` (rounded corners)
- Border: `1px` solid `AppColors.borderLight` (`#E2E8F0`)
- Background: Linear gradient
  - Start: `Color(0x1A1A365D)` (deepSeaBlue at 10% opacity)
  - End: `Color(0x0D2D3748)` (deltaTeal at 5% opacity)
  - Direction: Top-left to bottom-right

**Icon Container**:
- Padding: `12px` all sides
- Shape: Circle
- Background: `AppColors.deepSeaBlue` at 15% opacity
- Border: `1px` solid `AppColors.borderLight`
- Icon Size: `32px`
- Icon Color: `AppColors.deepSeaBlue`

**Title Text**:
- Style: `titleMedium` from theme
- Color: `AppColors.textSecondary` (`#718096`)
- Alignment: Center

**Value Text**:
- Style: `headlineMedium` from theme
- Color: `AppColors.deepSeaBlue` (`#1A365D`)
- Weight: Bold

### Displayed Statistics

1. **Pages Read This Month** (User)
   - Source: `user['pages_read'] ?? 0`
   - Icon: `Icons.book`
   - Label: `l10n.pagesReadThisMonth`

2. **Total Library Value** (Combined)
   - Source: `combined['money_spent'] ?? 0.0`
   - Format: `{value.toStringAsFixed(2)} RON`
   - Icon: `Icons.attach_money`
   - Label: `l10n.totalLibraryValue`

3. **Total Books** (Combined)
   - Source: `combined['total_books'] ?? 0`
   - Icon: `Icons.library_books`
   - Label: `l10n.totalBooks`

4. **Total Pages Read** (Combined)
   - Source: `combined['pages_read'] ?? 0`
   - Icon: `Icons.menu_book`
   - Label: `l10n.totalPagesRead`

### Spacing

- **Card Spacing**: `16px` between cards (`SizedBox(height: 16)`)
- **Screen Padding**: `16px` all sides on `SingleChildScrollView`
- **Card Internal Spacing**: 
  - Icon to Title: `16px`
  - Title to Value: `8px`

---

## State Management

### Current Approach

The statistics screen uses **local state management** with `StatefulWidget` and `setState()`. It does not use the Provider pattern like other screens in the application.

### State Variables

```dart
class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;  // Statistics data from API
  bool _isLoading = true;         // Loading state flag
}
```

### State Transitions

```
Initial State
    _stats = null
    _isLoading = true
        ↓
_loadStats() called
    _isLoading = true (setState)
        ↓
API Call in Progress
        ↓
Success: _stats = decoded JSON, _isLoading = false
Error: _stats = null, _isLoading = false
```

### State Updates

All state updates use `setState()`:
- Loading start: `setState(() => _isLoading = true)`
- Success: `setState(() { _stats = jsonDecode(response.body); _isLoading = false; })`
- Error: `setState(() => _isLoading = false)`

### Lifecycle Management

**initState()**: Called once when widget is inserted into the tree. Triggers `_loadStats()`.

**build()**: Called whenever state changes. Rebuilds UI based on current `_isLoading` and `_stats` values.

### Potential Improvements

Consider migrating to a `StatsProvider` using the Provider pattern for:
- Centralized state management
- State sharing across widgets
- Better error handling
- Caching and refresh capabilities

---

## Localization

### Localization Keys

All user-facing strings are localized through `AppLocalizations`:

| Key | English | Romanian |
|-----|---------|----------|
| `statistics` | "Statistics" | "Statistici" |
| `pagesReadThisMonth` | "Pages read this month" | - |
| `totalLibraryValue` | "Total library value (RON)" | - |
| `totalBooks` | "Total books" | - |
| `totalPagesRead` | "Total pages read" | - |
| `statsError` | "Error loading statistics" | "Eroare la încărcarea statisticilor" |

### Usage in Code

```dart
final l10n = AppLocalizations.of(context)!;

// Titles
l10n.pagesReadThisMonth
l10n.totalLibraryValue
l10n.totalBooks
l10n.totalPagesRead

// Error Message
l10n.statsError
```

### Localization Files

- **English**: `lib/l10n/app_en.arb`
- **Romanian**: `lib/l10n/app_ro.arb`

### Translation Status

- Full English translations available
- Partial Romanian translations (statsError available, stat labels may need translation)

---

## Styling & Theming

### Color Usage

All colors come from `AppColors` class (`lib/theme/app_colors.dart`):

| Usage | Color | Hex Value |
|-------|-------|-----------|
| Card Value Text | `AppColors.deepSeaBlue` | `#1A365D` |
| Card Icon | `AppColors.deepSeaBlue` | `#1A365D` |
| Card Title | `AppColors.textSecondary` | `#718096` |
| Icon Background | `AppColors.deepSeaBlue` (15% opacity) | `#1A365D` (0.15) |
| Card Border | `AppColors.borderLight` | `#E2E8F0` |
| Card Gradient Start | `deepSeaBlue` (10% opacity) | `#1A365D` (0.1) |
| Card Gradient End | `deltaTeal` (5% opacity) | `#2D3748` (0.05) |

### Typography

| Element | Theme Style | Size/Weight |
|---------|-------------|-------------|
| Title | `titleMedium` | Medium size, regular weight |
| Value | `headlineMedium` | Large size, **bold** weight |

### Design Consistency

The statistics screen follows the app's **"Deep Water"** color scheme:
- Primary: Deep Sea Blue (`#1A365D`)
- Secondary: Delta Teal (`#2D3748`)
- Accents: Subtle gradients and opacity variations
- Borders: Light, subtle borders using `borderLight`

### Responsive Design

- Uses `SingleChildScrollView` for vertical scrolling on smaller screens
- Cards stretch to full width (`crossAxisAlignment: CrossAxisAlignment.stretch`)
- Consistent padding and spacing scale

---

## Error Handling

### Current Implementation

Error handling is minimal and silent:

```dart
try {
  final apiService = ApiService();
  final response = await apiService.get('/api/v1/dashboard');
  if (response.statusCode == 200) {
    setState(() {
      _stats = jsonDecode(response.body);
      _isLoading = false;
    });
  }
} catch (e) {
  setState(() => _isLoading = false);
}
```

### Error Scenarios Handled

1. **Network Errors**: Caught in `catch` block, sets `_isLoading = false`
2. **Non-200 Status Codes**: No explicit handling, `_stats` remains `null`
3. **JSON Decode Errors**: Would throw, caught in `catch` block
4. **Null/Empty Response**: `_stats` remains `null`, error state displayed

### Error State Display

```dart
if (_stats == null) {
  return Center(child: Text(l10n.statsError));
}
```

### Limitations

- **No Error Details**: Users see generic error message
- **No Retry Mechanism**: User must navigate away and back to retry
- **No Network Status Check**: Doesn't distinguish network vs. server errors
- **Silent Failures**: Errors are caught but not logged or reported

### Recommended Improvements

1. **Specific Error Messages**: Differentiate network, server, and parsing errors
2. **Retry Button**: Allow users to retry failed requests
3. **Error Logging**: Log errors for debugging
4. **Status Code Handling**: Handle 401 (unauthorized), 500 (server error), etc.
5. **Snackbar Notifications**: Show transient error messages

---

## Navigation Integration

### Navigation Entry Point

The statistics screen is integrated into the main app navigation via `HomeScreen`:

**File**: `lib/screens/home_screen.dart`

**Navigation Setup**:
```dart
body: IndexedStack(
  index: _currentIndex,
  children: [
    LibraryScreen(key: _libraryScreenKey),
    const ScannerScreen(),
    const StatsScreen(),  // Index 2
  ],
)
```

**Bottom Navigation Bar**:
```dart
bottomNavigationBar: Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [
    _buildNavItem(Icons.library_books, l10n.myLibrary, 0),
    _buildNavItem(Icons.qr_code_scanner, l10n.scan, 1),
    _buildNavItem(Icons.bar_chart, l10n.statistics, 2),  // Stats tab
  ],
)
```

### Tab Index

- **Index 0**: Library Screen
- **Index 1**: Scanner Screen
- **Index 2**: **Statistics Screen**

### Navigation Behavior

- **Tab Preservation**: Uses `IndexedStack`, so state is preserved when switching tabs
- **Auto-refresh**: Statistics reload on every screen mount (`initState()` called)
- **No Parameters**: Screen accepts no constructor parameters

### Navigation Icon

- **Icon**: `Icons.bar_chart` (Material Design bar chart icon)
- **Label**: Localized "Statistics" text

---

## Technical Details

### Dependencies

**Core Flutter Packages**:
- `flutter/material.dart` - UI framework
- `dart:convert` - JSON decoding

**App Packages**:
- `deltabooks/l10n/app_localizations.dart` - Localization
- `../services/api_service.dart` - API communication
- `../theme/app_colors.dart` - Theme colors

**Note**: `provider` package is imported but not used in this screen.

### Memory Management

- **State Disposal**: No explicit cleanup needed (no streams or controllers)
- **API Service**: Created per request (lightweight, no state)
- **JSON Data**: Decoded and stored in memory (relatively small dataset)

### Performance Considerations

**Data Loading**:
- Loads on every screen mount (no caching)
- No debouncing or throttling
- Synchronous JSON decoding on main thread (acceptable for small responses)

**UI Rendering**:
- Stateless stat cards (efficient rebuilds)
- Simple layout (no complex widgets)
- Single `setState()` call per load cycle

**Optimization Opportunities**:
1. Cache statistics data between tab switches
2. Implement pull-to-refresh
3. Add loading skeleton instead of spinner
4. Lazy load statistics if data grows

### Code Quality

**Strengths**:
- Clean separation of concerns
- Reusable `_buildStatCard()` method
- Null-safe access patterns
- Consistent styling

**Areas for Improvement**:
1. Extract stat card to separate widget file
2. Add error handling and user feedback
3. Consider using a provider for state management
4. Add unit tests for data parsing
5. Type-safe model classes for statistics data

---

## Future Enhancements

### Planned/Recommended Features

1. **Enhanced Statistics Display**
   - Partner-specific statistics cards
   - Reading progress charts/graphs
   - Time-based statistics (daily, weekly, yearly)
   - Reading streak tracking

2. **Interactive Elements**
   - Pull-to-refresh gesture
   - Swipeable stat cards
   - Expandable detail views

3. **Advanced Metrics**
   - Average pages per book
   - Reading speed (pages per day/week)
   - Genre breakdown
   - Author statistics
   - Favorite genres/authors

4. **Visualizations**
   - Bar charts for monthly reading
   - Pie charts for genre distribution
   - Line graphs for reading trends
   - Progress indicators

5. **Comparison Features**
   - User vs. Partner comparison
   - Year-over-year comparisons
   - Library-to-library comparisons

6. **Data Export**
   - Export statistics to CSV/JSON
   - Share statistics screenshots
   - Email statistics reports

7. **State Management Improvements**
   - Migrate to `StatsProvider`
   - Add caching layer
   - Implement optimistic updates

8. **Error Handling Enhancements**
   - Retry mechanisms
   - Offline mode with cached data
   - Detailed error messages
   - Error reporting

9. **Performance Optimizations**
   - Lazy loading
   - Pagination for large datasets
   - Background data refresh
   - Skeleton loading states

10. **Accessibility**
    - Screen reader support
    - High contrast mode
    - Adjustable font sizes
    - Voice-over descriptions

---

## Summary

The Statistics feature provides a solid foundation for displaying user reading metrics. It integrates seamlessly with the existing app architecture, uses consistent styling, and supports localization. The implementation follows Flutter best practices with a clean, maintainable structure.

**Key Strengths**:
- Simple, focused implementation
- Consistent UI/UX with app design system
- Localization support
- Reusable card component

**Areas for Future Development**:
- Enhanced error handling
- Provider-based state management
- Additional statistics and visualizations
- Performance optimizations

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Maintained By**: DeltaBooks Development Team