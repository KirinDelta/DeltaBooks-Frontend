class Genre {
  final String slug;
  final String nameEn;
  final String nameRo;
  final int position;

  const Genre({
    required this.slug,
    required this.nameEn,
    required this.nameRo,
    required this.position,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      slug: json['slug'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameRo: json['name_ro'] as String? ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}
