class Invitation {
  final int id;
  final int senderId;
  final int receiverId;
  final int libraryId;
  final String senderEmail;
  final String receiverEmail;
  final String? libraryName;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime? updatedAt;

  Invitation({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.libraryId,
    required this.senderEmail,
    required this.receiverEmail,
    this.libraryName,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      libraryId: json['library_id'] as int,
      senderEmail: json['sender_email'] as String? ?? '',
      receiverEmail: json['receiver_email'] as String? ?? '',
      libraryName: json['library_name'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
