import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl; // Thêm trường để lưu URL của ảnh đại diện
  final List<DocumentReference>? folderReferences;
  final List<DocumentReference>? topicReferences;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl, // Đặt trường này là tùy chọn
    required this.folderReferences,
    required this.topicReferences,
  });

  // Factory constructor để tạo User từ một tài liệu Firestore
  factory User.fromFirestore(DocumentSnapshot doc) {
    List<DocumentReference> folderRefs =
        List<DocumentReference>.from(doc['Folders']);
    List<DocumentReference> topicRefs =
        List<DocumentReference>.from(doc['Topics']);

    return User(
        id: doc.id,
        email: doc['Email'],
        name: doc['Name'],
        avatarUrl: doc['AvatarUrl'],
        folderReferences: folderRefs,
        topicReferences: topicRefs);
  }
}
