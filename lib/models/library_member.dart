import 'user.dart';

/// Represents a member/partner that has access to a specific library.
class LibraryMember {
  final int id;
  final int libraryId;
  final User user;

  /// Invitation / membership status for this member.
  ///
  /// Expected values: 'pending', 'accepted', 'revoked' (or similar).
  final String status;

  /// Granular permissions for this member on the library.
  final bool canAddBooks;
  final bool canRemoveBooks;

   /// Whether this member is the owner of the library.
   ///
   /// Sourced from backend fields like `is_owner` or a `role` of "owner".
   final bool isOwner;

  const LibraryMember({
    required this.id,
    required this.libraryId,
    required this.user,
    required this.status,
    required this.canAddBooks,
    required this.canRemoveBooks,
    this.isOwner = false,
  });

  /// Convenience accessors for the member's name fields, mirroring the
  /// structure described in the frontend documentation. These delegate to
  /// the underlying [User] model returned by the backend.
  String? get firstName => user.firstName;
  String? get lastName => user.lastName;

  bool get isActive => status == 'accepted';

  bool get isPending => status == 'pending';

  factory LibraryMember.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }

    bool parseIsOwner(Map<String, dynamic> data) {
      final rawIsOwner = data['is_owner'];
      if (rawIsOwner is bool) return rawIsOwner;

      final role = data['role'];
      if (role is String) {
        return role.toLowerCase() == 'owner';
      }

      return false;
    }

    // Member user can be nested under "user" or top-level user fields
    final userJson = (json['user'] as Map<String, dynamic>?) ?? json;

    return LibraryMember(
      id: parseId(json['id']) ?? 0,
      libraryId: parseId(json['library_id']) ?? 0,
      user: User.fromJson(userJson),
      // The members endpoint typically returns only accepted members, so if
      // status is missing we treat the record as active/accepted.
      status: (json['status'] as String?) ?? 'accepted',
      canAddBooks: (json['can_add_books'] as bool?) ?? false,
      canRemoveBooks: (json['can_remove_books'] as bool?) ?? false,
      isOwner: parseIsOwner(json),
    );
  }

  LibraryMember copyWith({
    int? id,
    int? libraryId,
    User? user,
    String? status,
    bool? canAddBooks,
    bool? canRemoveBooks,
    bool? isOwner,
  }) {
    return LibraryMember(
      id: id ?? this.id,
      libraryId: libraryId ?? this.libraryId,
      user: user ?? this.user,
      status: status ?? this.status,
      canAddBooks: canAddBooks ?? this.canAddBooks,
      canRemoveBooks: canRemoveBooks ?? this.canRemoveBooks,
      isOwner: isOwner ?? this.isOwner,
    );
  }
}

