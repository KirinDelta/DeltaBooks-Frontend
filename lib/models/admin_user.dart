class AdminLibraryMembership {
  final int id;
  final String name;
  final bool isOwner;
  final DateTime? joinedAt;

  AdminLibraryMembership({
    required this.id,
    required this.name,
    required this.isOwner,
    this.joinedAt,
  });

  factory AdminLibraryMembership.fromJson(Map<String, dynamic> json) {
    return AdminLibraryMembership(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      isOwner: json['is_owner'] as bool? ?? false,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'] as String)
          : null,
    );
  }
}

class AdminUser {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String accountStatus;
  final bool isAdmin;
  final DateTime? createdAt;
  final int librariesCount;
  final int userBooksCount;

  AdminUser({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.accountStatus,
    required this.isAdmin,
    this.createdAt,
    required this.librariesCount,
    required this.userBooksCount,
  });

  bool get isSuspended => accountStatus == 'suspended';

  String get displayName {
    final parts = [firstName, lastName].where((s) => s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' ') : username.isNotEmpty ? username : email;
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      accountStatus: json['account_status'] as String? ?? 'active',
      isAdmin: json['admin'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      librariesCount: (json['libraries_count'] as num?)?.toInt() ?? 0,
      userBooksCount: (json['user_books_count'] as num?)?.toInt() ?? 0,
    );
  }

  AdminUser copyWith({String? accountStatus}) {
    return AdminUser(
      id: id,
      email: email,
      username: username,
      firstName: firstName,
      lastName: lastName,
      accountStatus: accountStatus ?? this.accountStatus,
      isAdmin: isAdmin,
      createdAt: createdAt,
      librariesCount: librariesCount,
      userBooksCount: userBooksCount,
    );
  }
}

class AdminUserDetail extends AdminUser {
  final int wishlistItemsCount;
  final List<AdminLibraryMembership> libraryMemberships;

  AdminUserDetail({
    required super.id,
    required super.email,
    required super.username,
    required super.firstName,
    required super.lastName,
    required super.accountStatus,
    required super.isAdmin,
    super.createdAt,
    required super.librariesCount,
    required super.userBooksCount,
    required this.wishlistItemsCount,
    required this.libraryMemberships,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final memberships = (json['library_memberships'] as List<dynamic>?)
            ?.map((m) => AdminLibraryMembership.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];

    return AdminUserDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      accountStatus: json['account_status'] as String? ?? 'active',
      isAdmin: json['admin'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      librariesCount: (json['libraries_count'] as num?)?.toInt() ?? 0,
      userBooksCount: (json['user_books_count'] as num?)?.toInt() ?? 0,
      wishlistItemsCount: (json['wishlist_items_count'] as num?)?.toInt() ?? 0,
      libraryMemberships: memberships,
    );
  }
}
