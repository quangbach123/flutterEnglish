import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Models/Topic.dart';

class TopicService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionName = 'Topics';
  

  // Cập nhật thông tin của một chủ đề trong Firestore
  Future<void> updateTopic(String topicId, Map<String, dynamic> data) async {
    try {
      await _db.collection(_collectionName).doc(topicId).update(data);
    } catch (error) {
      print("Error updating topic: $error");
      throw error;
    }
  }

  // Lấy thông tin của một chủ đề từ Firestore dựa trên ID
Future<List<Topic>> getTopicsByUserId(String userId) async {
  try {
    QuerySnapshot querySnapshot = await _db.collection(_collectionName)
    .where('userId', isEqualTo: userId)
    .get();
    List<Topic> topics = querySnapshot.docs.map((doc) => Topic.fromFirestore(doc)).toList();
    return topics;
  } catch (error) {
    print("Error getting topics by user ID: $error");
    throw error;
  }
}


// sửa trạng thái của topic
Future<void> toggleTopicStatus(String topicId) async {
    try {
      // Lấy thông tin của topic từ Firestore
      DocumentSnapshot topicDoc = await _db.collection(_collectionName).doc(topicId).get();

      // Kiểm tra xem topic có tồn tại không
      if (topicDoc.exists) {
        // Lấy trạng thái hiện tại của topic
        bool currentStatus = topicDoc['isPublic'] ?? false;

        // Đảo ngược trạng thái
        bool newStatus = !currentStatus;

        // Cập nhật trạng thái mới của topic trong Firestore
        await _db.collection(_collectionName).doc(topicId).update({'isPublic': newStatus});
      } else {
        throw ('Topic not found');
      }
    } catch (error) {
      print("Error toggling topic status: $error");
      throw error;
    }
  }
  Future<Topic> getTopicById(String topicId) async {
  try {
    DocumentSnapshot documentSnapshot = await _db.collection(_collectionName).doc(topicId).get();
    if (documentSnapshot.exists) {
      Topic topic = Topic.fromFirestore(documentSnapshot);
      return topic;
    } else {
      throw Exception('Topic with ID $topicId not found');
    }
  } catch (error) {
    print("Error getting topic by ID: $error");
    throw error;
  }
  }

  // Lấy danh sách tất cả các chủ đề từ Firestore
  Future<List<Topic>> getAllTopics() async {
    try {
      QuerySnapshot querySnapshot = await _db.collection(_collectionName).get();
      List<Topic> topics = querySnapshot.docs.map((doc) => Topic.fromFirestore(doc)).toList();
      return topics;
    } catch (error) {
      print("Error getting all topics: $error");
      throw error;
    }
  }

  // Thêm một chủ đề mới và cập nhật tham chiếu trong trường 'Topics' của người dùng
  Future<void> addTopicWithUserReference(Topic topic, String userId) async {
    try {
      // Thêm một chủ đề mới vào Firestore
      DocumentReference topicRef = await _db.collection(_collectionName).add(topic.toMap());

      // Tạo một tham chiếu đến người dùng trong Firestore
      DocumentReference userRef = _db.collection('User').doc(userId);

      // Cập nhật trường 'Topics' của người dùng để tham chiếu đến chủ đề mới
      await userRef.update({
        'Topics': FieldValue.arrayUnion([topicRef])
      });
    } catch (error) {
      print("Error adding topic with user reference: $error");
      throw error;
    }
  }
  //
  Future<void> incrementView(String topicId) async {
    try {
      // Lấy thông tin của topic từ Firestore
      DocumentSnapshot topicDoc = await _db.collection(_collectionName).doc(topicId).get();

      // Kiểm tra xem topic có tồn tại không
      if (topicDoc.exists) {
        // Lấy giá trị hiện tại của trường 'view'
        String currentView = topicDoc['view'] ?? '0';

        // Chuyển đổi giá trị hiện tại thành kiểu int và tăng giá trị lên 1
        int newView = int.parse(currentView) + 1;

        // Chuyển đổi giá trị mới thành kiểu String
        String newViewString = newView.toString();

        // Cập nhật trường 'view' mới của topic trong Firestore
        await _db.collection(_collectionName).doc(topicId).update({'view': newViewString});
      } else {
        throw Exception('Topic not found');
      }
    } catch (error) {
      print("Error incrementing view for topic: $error");
      throw error;
    }
  }
  

Future<void> deleteTopicWithUserReference(String topicId, String userId) async {
  try {
    // Tạo một tham chiếu đến chủ đề
    DocumentReference topicRef = _db.collection('Topics').doc(topicId);

    // Lấy tất cả các từ vựng có topicId trùng với topicRef
    QuerySnapshot wordsSnapshot = await _db.collection('Words').where('topicId', isEqualTo: topicRef).get();

    // Xóa từng từ vựng
    for (DocumentSnapshot doc in wordsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Xóa chủ đề từ Firestore
    await topicRef.delete();

    // Tạo một tham chiếu đến người dùng trong Firestore
    DocumentReference userRef = _db.collection('User').doc(userId);

    // Cập nhật trường 'Topics' của người dùng để xóa tham chiếu của chủ đề đã bị xóa
    await userRef.update({
      'Topics': FieldValue.arrayRemove([topicRef])
    });
  } catch (error) {
    print("Error deleting topic with user reference: $error");
    throw error;
  }
} // lấy ra các topic public
  Future<List<Topic>> getAllPublicTopics() async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection(_collectionName)
          .where('isPublic', isEqualTo: true)
          .get();
      List<Topic> publicTopics =
          querySnapshot.docs.map((doc) => Topic.fromFirestore(doc)).toList();
      return publicTopics;
    } catch (error) {
      print("Error getting all public topics: $error");
      throw error;
    }
  }
   // Hàm để lấy tất cả các chủ đề chưa có trong một thư mục với userId trùng với userId của thư mục đó
  Future<List<Topic>> getTopicsNotInFolder(String userId, String folderId) async {
    try {
      // Lấy danh sách các chủ đề đã có trong thư mục
      DocumentSnapshot folderSnapshot = await _db.collection('Folder').doc(folderId).get();
      List<DocumentReference> topicReferences = List<DocumentReference>.from(folderSnapshot['Topics']);

      // Lấy danh sách các chủ đề có userId trùng với userId của thư mục
      QuerySnapshot querySnapshot = await _db.collection(_collectionName).where('userId', isEqualTo: userId).get();

      // Lọc ra các chủ đề chưa có trong thư mục
      List<Topic> topicsNotInFolder = [];
      for (DocumentSnapshot doc in querySnapshot.docs) {
        if (!topicReferences.contains(doc.reference)) {
          topicsNotInFolder.add(Topic.fromFirestore(doc));
        }
      }

      return topicsNotInFolder;
    } catch (error) {
      print("Error getting topics not in folder: $error");
      throw error;
    }
  }
    // Hàm để tìm kiếm các chủ đề công khai dựa trên một từ khóa
  Future<List<Topic>> searchPublicTopics(String keyword) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection(_collectionName)
          .where('isPublic', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: keyword)
          .where('name', isLessThanOrEqualTo: keyword + '\uf8ff')
          .get();
      List<Topic> publicTopics =
          querySnapshot.docs.map((doc) => Topic.fromFirestore(doc)).toList();
      return publicTopics;
    } catch (error) {
      print("Error searching public topics: $error");
      throw error;
    }
  }
  
  
}

