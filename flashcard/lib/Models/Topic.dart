import 'package:cloud_firestore/cloud_firestore.dart';

class Topic {
  final String documentId;
  final String? topicImageUrl;
  final String topicName;
  final String? folderId;
  final String? userId;
  final bool isPublic;
  final String? userAvatarUrl;
  final String? userName;
  final String view; 

  Topic({
    required this.documentId,
    this.topicImageUrl,
    required this.topicName,
    this.folderId,
    this.userId,
    required this.isPublic,
    this.userAvatarUrl,
    this.userName,
    required this.view, // Thêm trường view vào constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'topicImageUrl': topicImageUrl,
      'topicName': topicName,
      'folderId': folderId,
      'userId': userId,
      'isPublic': isPublic,
      'userAvatarUrl': userAvatarUrl,
      'userName': userName,
      'view': view, // Thêm trường view vào map
    };
  }

  factory Topic.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Topic(
      documentId: doc.id,
      topicImageUrl: data['topicImageUrl'],
      topicName: data['topicName'],
      folderId: data['folderId'],
      userId: data['userId'],
      isPublic: data['isPublic'] ?? false,
      userAvatarUrl: data['userAvatarUrl'],
      userName: data['userName'],
      view: data['view']// Gán giá trị mặc định cho view nếu không có giá trị từ Firestore
    );
  }

  static fromSnapshot(DocumentSnapshot<Object?> snapshot) {}
}
