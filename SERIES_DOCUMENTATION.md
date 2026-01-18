# Series Documentation

This document provides comprehensive documentation of every place where Series (or anything related to series) is being shown and how it's loaded in the DeltaBooks frontend application.

## Table of Contents

1. [Data Model](#data-model)
2. [UI Display Locations](#ui-display-locations)
3. [Data Loading](#data-loading)
4. [Data Saving/Updating](#data-savingupdating)
5. [Search Functionality](#search-functionality)
6. [API Endpoints](#api-endpoints)

---

## Data Model

### Book Model (`lib/models/book.dart`)

The `Book` class contains the following series-related fields:

```dart
final String? seriesName;
```

**Location**: Line 41 in `lib/models/book.dart`

**Parsing Logic**: 
- The series name is parsed from JSON in the `Book.fromJson()` factory method (line 151)
- It accepts either `series` or `series_name` from the API response:
  ```dart
  seriesName: json['series'] as String? ?? json['series_name'] as String?,
  ```

**Note**: The `seriesName` field is nullable, meaning a book may or may not have a series name.

### Library-Specific Series Fields

In addition to the global `seriesName` field on the Book model, there are library-specific series fields that can be set per library:

- **`series_name`**: Library-specific override for series name (stored in `library_book` association)
- **`series_volume`**: Library-specific series volume (e.g., "Volume 1", "Book 2")

These library-specific fields are handled through the `BookProvider.updateBookInLibrary()` method and are stored separately from the global book series name.

---

## UI Display Locations

### 1. Book Detail Screen (`lib/screens/book_detail_screen.dart`)

**Location**: Lines 516-538

**Display Format**:
- Series name is displayed as a RichText widget with italicized series name
- Format: "Part of the [Series Name] series"
- Only shown if `book.seriesName != null && book.seriesName!.isNotEmpty`

**Code Snippet**:
```dart
// Series Name (if available)
if (book.seriesName != null && book.seriesName!.isNotEmpty) ...[
  RichText(
    text: TextSpan(
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      children: [
        const TextSpan(text: 'Part of the '),
        TextSpan(
          text: book.seriesName!,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const TextSpan(text: ' series'),
      ],
    ),
  ),
  const SizedBox(height: 8),
],
```

**When Loaded**: 
- The book data (including series name) is loaded when the `BookDetailScreen` is initialized
- The book object is passed as a parameter to the screen
- If in library mode, the book data is refreshed when the library changes via `_onLibraryChanged()` listener

---

### 2. Library Screen (`lib/screens/library_screen.dart`)

**Location**: Lines 397-421

**Display Format**:
- Series name is displayed in the book list item card
- Format: "📚 Series: [Series Name]"
- Shown below the author name
- Only displayed if `book.seriesName != null && book.seriesName!.isNotEmpty`
- Text is truncated with ellipsis if too long

**Code Snippet**:
```dart
// Series name (if available)
if (book.seriesName != null && book.seriesName!.isNotEmpty) ...[
  const SizedBox(height: 2),
  Row(
    children: [
      Text(
        '📚 ',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 14,
            ),
      ),
      Expanded(
        child: Text(
          'Series: ${book.seriesName!}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  ),
],
```

**When Loaded**:
- Books are loaded as part of the library object from the API
- The library's books list is accessed via `selectedLibrary?.books ?? []`
- Books are refreshed when:
  - Library is selected/changed
  - Library details are fetched via `fetchLibraries()` or `fetchLibraryDetails()`
  - User returns from book detail screen

---

### 3. Search Results Screen (`lib/screens/search_results_screen.dart`)

**Location**: Lines 227-251

**Display Format**:
- Series name is displayed in search result cards
- Format: "📚 Series: [Series Name]"
- Shown below the author name, similar to library screen
- Only displayed if `book.seriesName != null && book.seriesName!.isNotEmpty`
- Text is truncated with ellipsis if too long

**Code Snippet**:
```dart
// Series name (if available)
if (book.seriesName != null && book.seriesName!.isNotEmpty) ...[
  const SizedBox(height: 4),
  Row(
    children: [
      Text(
        '📚 ',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 14,
            ),
      ),
      Expanded(
        child: Text(
          'Series: ${book.seriesName!}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  ),
],
```

**When Loaded**:
- Books are passed to the screen via the `books` parameter
- These books come from the search API response (see [Data Loading - Search](#data-loading---search))

---

### 4. Book Edit Screen (`lib/screens/book_edit_screen.dart`)

**Location**: Lines 580-629

**Display Format**:
- Series Name input field (lines 580-604)
- Series Volume input field (lines 607-629)
- Both fields are optional and marked as "library-specific"

**Series Name Field**:
- Label: "Series Name (optional, library-specific)"
- Hint: "Enter series name"
- Controller: `_seriesNameController`
- Pre-populated from `book.seriesName` when editing (line 75)

**Series Volume Field**:
- Label: "Series Volume (optional, library-specific)"
- Hint: "e.g., Volume 1, Book 2"
- Controller: `_seriesVolumeController`
- Only available in edit mode (not shown when adding a new book)

**When Loaded**:
- Form is populated in `_populateForm()` method (line 67)
- Series name is loaded from `book.seriesName` (line 75)
- Series volume is not pre-populated (library-specific field that may not exist in the book model)

---

## Data Loading

### Loading from API

Series data is loaded as part of the Book object from various API endpoints:

#### 1. Library Books Loading

**Endpoint**: `GET /api/v1/libraries/:id`

**Provider**: `LibraryProvider.fetchLibraryDetails()`

**Location**: `lib/providers/library_provider.dart` (lines 66-105)

**Flow**:
1. `fetchLibraryDetails()` is called with a library ID
2. API returns library object with nested `books` array
3. Each book in the array is parsed using `Book.fromJson()`
4. Series name is extracted from `series` or `series_name` field in JSON
5. Books are stored in the `Library.books` list
6. UI components access books via `libraryProvider.selectedLibrary?.books`

**Code Flow**:
```dart
// In LibraryProvider.fetchLibraryDetails()
final response = await _apiService.get('/api/v1/libraries/$libraryId');
final data = jsonDecode(response.body);
final updated = Library.fromJson(data as Map<String, dynamic>);
// Library.fromJson() parses books array
// Each book is parsed with Book.fromJson()
// Book.fromJson() extracts seriesName from JSON
```

#### 2. All Libraries Loading

**Endpoint**: `GET /api/v1/libraries`

**Provider**: `LibraryProvider.fetchLibraries()`

**Location**: `lib/providers/library_provider.dart` (lines 153-223)

**Flow**:
1. `fetchLibraries()` fetches all libraries (owned + shared)
2. Each library response includes a `books` array
3. Books are parsed with series information included
4. Libraries are stored in `_libraries` list
5. Selected library is updated from this list

#### 3. Search Loading

**Endpoint**: `POST /api/v1/books/search`

**Provider**: `BookProvider.searchBooks()`

**Location**: `lib/providers/book_provider.dart` (lines 80-116)

**Flow**:
1. Search is performed with ISBN, title, or author
2. API returns array of Book objects
3. Each book includes series name if available
4. Books are parsed using `Book.fromJson()`
5. Results are displayed in `SearchResultsScreen`

**Code**:
```dart
final response = await _apiService.post('/api/v1/books/search', body);
if (response.statusCode == 200) {
  final responseBody = jsonDecode(response.body);
  if (responseBody is List) {
    return responseBody.map((json) => Book.fromJson(json as Map<String, dynamic>)).toList();
  }
}
```

#### 4. Book Lookup by ISBN

**Endpoint**: `POST /api/v1/books/find`

**Provider**: `BookProvider.findBookByIsbn()`

**Location**: `lib/providers/book_provider.dart` (lines 66-75)

**Flow**:
1. ISBN is sent to find endpoint
2. API returns a single Book object
3. Book is parsed with series information included
4. Used when scanning or manually entering ISBN

---

## Data Saving/Updating

### Adding Series Name When Adding a Book

**Location**: `lib/providers/book_provider.dart` (lines 120-177)

**Method**: `addBookToLibrary()`

**Flow**:
1. When adding a new book (not existing), `seriesName` can be provided
2. Series name is sent in the request body as `series_name`
3. Endpoint: `POST /api/v1/libraries/:id/share_book`

**Code**:
```dart
if (seriesName != null && seriesName.isNotEmpty) {
  body['series_name'] = seriesName;
}
```

**Note**: When adding a new book, the series name becomes part of the global book data, not library-specific.

### Updating Library-Specific Series Fields

**Location**: `lib/providers/book_provider.dart` (lines 295-351)

**Method**: `updateBookInLibrary()`

**Flow**:
1. Only library-specific fields can be updated (not global book fields)
2. Series name and series volume are library-specific overrides
3. Fields are wrapped in `library_book` hash
4. Endpoint: `PATCH /api/v1/libraries/:id/library_books/:library_book_id`

**Code**:
```dart
if (seriesName != null) {
  libraryBookData['series_name'] = seriesName.trim().isEmpty ? '' : seriesName.trim();
}

if (seriesVolume != null) {
  libraryBookData['series_volume'] = seriesVolume.trim().isEmpty ? '' : seriesVolume.trim();
}

final body = <String, dynamic>{
  'library_book': libraryBookData,
};
```

**Usage in UI**:
- Called from `BookEditScreen._updateBook()` (line 199)
- Series name and volume are read from form controllers
- After successful update, library details are refreshed

---

## Search Functionality

### Series Name in Search

**Location**: `lib/providers/library_provider.dart` (lines 594-626)

**Method**: `filterBooksBySearch()`

**Functionality**:
- Series name is included in the search filter
- When searching in the library screen, books are filtered by:
  - Title
  - ISBN
  - **Series name** (if exists)
  - Genre

**Code**:
```dart
// Check series name (if exists)
if (book.seriesName != null && book.seriesName!.toLowerCase().contains(lowerQuery)) {
  return true;
}
```

**Usage**:
- Called from `LibraryScreen._applyFiltersAndSort()` (line 535)
- Search query is case-insensitive
- Partial matches are supported

---

## API Endpoints

### Endpoints That Return Series Data

1. **`GET /api/v1/libraries`**
   - Returns all libraries with nested books
   - Each book includes `series` or `series_name` field

2. **`GET /api/v1/libraries/:id`**
   - Returns single library with nested books
   - Each book includes series information

3. **`POST /api/v1/books/search`**
   - Returns array of books matching search criteria
   - Each book includes series name if available

4. **`POST /api/v1/books/find`**
   - Returns single book by ISBN
   - Includes series name if available

### Endpoints That Accept Series Data

1. **`POST /api/v1/libraries/:id/share_book`**
   - Accepts `series_name` in request body when creating new book
   - Field: `series_name` (string, optional)

2. **`PATCH /api/v1/libraries/:id/library_books/:library_book_id`**
   - Accepts library-specific series fields in `library_book` hash:
     - `series_name` (string, optional) - Library-specific series name override
     - `series_volume` (string, optional) - Library-specific series volume

### JSON Structure

**Book Object (from API)**:
```json
{
  "id": 1,
  "title": "Book Title",
  "author": "Author Name",
  "series": "Series Name",  // or "series_name"
  // ... other fields
}
```

**Library Book Update (to API)**:
```json
{
  "library_book": {
    "series_name": "Library-Specific Series Name",
    "series_volume": "Volume 1"
  }
}
```

---

## Summary

### Series Data Flow

1. **Loading**:
   - Series name is loaded as part of Book objects from various API endpoints
   - Books are included in library responses or returned from search endpoints
   - Series name is parsed from `series` or `series_name` JSON fields

2. **Display**:
   - Series name is displayed in 3 main locations:
     - Book Detail Screen (formatted as "Part of the [Series] series")
     - Library Screen (in book list cards)
     - Search Results Screen (in result cards)
   - Only displayed if series name exists and is not empty

3. **Editing**:
   - Series name can be set when adding a new book (becomes global book data)
   - Series name and volume can be set/updated per library (library-specific overrides)
   - Edit screen provides input fields for both series name and volume

4. **Search**:
   - Series name is included in library search functionality
   - Users can search for books by series name

### Key Files

- **Model**: `lib/models/book.dart` - Defines `seriesName` field
- **Provider**: `lib/providers/book_provider.dart` - Handles API calls for series data
- **Provider**: `lib/providers/library_provider.dart` - Handles library/book loading and search
- **Screens**:
  - `lib/screens/book_detail_screen.dart` - Displays series in detail view
  - `lib/screens/library_screen.dart` - Displays series in library list
  - `lib/screens/search_results_screen.dart` - Displays series in search results
  - `lib/screens/book_edit_screen.dart` - Allows editing series name and volume
