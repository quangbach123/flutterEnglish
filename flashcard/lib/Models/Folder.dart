import 'package:cloud_firestore/cloud_firestore.dart';

class Folder {
  final String documentId;
  final String name;
  final List<DocumentReference>? Topics;
  final String userId; // Thêm trường userId vào Folder

  Folder({
    required this.documentId,
    required this.name,
    required this.Topics,
    required this.userId, // Thêm trường userId vào constructor
  });

  // Factory constructor để tạo Folder từ một tài liệu Firestore
  factory Folder.fromFirestore(DocumentSnapshot doc) {
    List<DocumentReference> topicRefs =
        List<DocumentReference>.from(doc['Topics']);
    return Folder(
      documentId: doc.id,
      name: doc['Name'],
      Topics: topicRefs,
      userId:
          doc['userId'], // Gán giá trị cho trường userId từ tài liệu Firestore
    );
  }
}
