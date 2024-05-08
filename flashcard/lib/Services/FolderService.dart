import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Models/Folder.dart';
import 'package:flashcard/Models/Topic.dart';

class FolderService {
  final CollectionReference folderCollection = FirebaseFirestore.instance.collection('Folder');
  // Hàm để lấy ra tất cả các folder của một user
  Future<List<Folder>> getAllFoldersOfUser(String userId) async {
    try {
      // Thực hiện truy vấn để lấy ra tất cả các folder của user có userId nhất định
      QuerySnapshot querySnapshot = await folderCollection.where('userId', isEqualTo: userId).get();

      // Chuyển đổi kết quả truy vấn thành danh sách các folder
      List<Folder> folders = querySnapshot.docs.map((doc) => Folder.fromFirestore(doc)).toList();
      return folders;
    } catch (error) {
      // Xử lý lỗi nếu có
      print("Error getting all folders of user: $error");
      return [];
    }
  }
  // Hàm để lấy một folder từ Firestore dựa trên id
  Future<Folder?> getFolderById(String folderId) async {
    try {
      // Thực hiện truy vấn để lấy ra folder có id nhất định
      DocumentSnapshot doc = await folderCollection.doc(folderId).get();

      // Kiểm tra xem tài liệu có tồn tại không
      if (doc.exists) {
        // Tạo một folder từ dữ liệu của tài liệu Firestore
        return Folder.fromFirestore(doc);
      } else {
        // Trả về null nếu không tìm thấy folder
        return null;
      }
    } catch (error) {
      // Xử lý lỗi nếu có
      print("Error getting folder by id: $error");
      return null;
    }
  }
  // hàm lấy ra tất cả các folder của 1 user nhưng dùng tham chiếu 
  Future<List<DocumentSnapshot>> getTopicsInFolder(DocumentReference folderRef) async {
  try {
    // Get the snapshot of the folder document
    DocumentSnapshot folderSnapshot = await folderRef.get();
    // Extract the list of topic references from the folder document
    List<DocumentReference>? topicReferences = List<DocumentReference>.from(folderSnapshot['Topics']);
    // Get the documents for each topic reference
    List<Future<DocumentSnapshot>> topicFutures = topicReferences.map((topicRef) => topicRef.get()).toList();
    
    // Wait for all topic documents to be retrieved
    List<DocumentSnapshot> topicSnapshots = await Future.wait(topicFutures);
    
    return topicSnapshots;
  } catch (error) {
    print("Error getting topics in folder: $error");
    throw error;
  }
}
// lấy topic chưa có trong folder
Future<List<DocumentSnapshot>> getTopicsNotInFolder(String userId, DocumentReference folderRef) async {
  try {
    // Lấy danh sách các chủ đề trong thư mục
    List<DocumentSnapshot> topicsInFolder = await getTopicsInFolder(folderRef);

    // Lấy danh sách các chủ đề có userId trùng với userId của thư mục
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Topics')
        .where('userId', isEqualTo: userId)
        .get();

    // Lọc ra những chủ đề có userId trùng với userId của thư mục nhưng chưa có trong thư mục
    List<DocumentSnapshot> topicsNotInFolder = querySnapshot.docs.where((topicDoc) {
      // Lọc ra chủ đề không có trong thư mục
      return !topicsInFolder.any((topicInFolder) => topicInFolder.id == topicDoc.id);
    }).toList();

    return topicsNotInFolder;
  } catch (error) {
    print("Error getting topics not in folder: $error");
    throw error;
  }
}
Future<List<Topic>> getPublicTopicsNotInFolder(DocumentReference folderRef) async {
  try {
    // Lấy danh sách các chủ đề trong thư mục
    List<DocumentSnapshot> topicsInFolder = await getTopicsInFolder(folderRef);

    // Lấy danh sách các chủ đề có thuộc tính isPublic=true
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Topics')
        .where('isPublic', isEqualTo: true)
        .get();

    // Lọc ra những chủ đề có thuộc tính isPublic=true nhưng chưa có trong thư mục
    List<DocumentSnapshot> topicsNotInFolder = querySnapshot.docs.where((topicDoc) {
      // Lọc ra chủ đề không có trong thư mục
      return !topicsInFolder.any((topicInFolder) => topicInFolder.id == topicDoc.id);
    }).toList();

    // Chuyển đổi danh sách DocumentSnapshot thành danh sách Topic
    List<Topic> publicTopicsNotInFolder = topicsNotInFolder.map((snapshot) => Topic.fromFirestore(snapshot)).toList();
    
    return publicTopicsNotInFolder;
  } catch (error) {
    print("Error getting public topics not in folder: $error");
    throw error;
  }
}





// Hàm để thêm một chủ đề vào một thư mục
  Future<void> addTopicToFolder(String folderId, DocumentReference topicRef) async {
    try {
      // Lấy thông tin của thư mục từ Firestore
      DocumentSnapshot folderSnapshot = await folderCollection.doc(folderId).get();

      // Kiểm tra xem thư mục có tồn tại không
      if (folderSnapshot.exists) {
        // Lấy danh sách tham chiếu của các chủ đề từ tài liệu thư mục
        List<DocumentReference> topicReferences = List<DocumentReference>.from(folderSnapshot['Topics']);

        // Kiểm tra xem chủ đề đã tồn tại trong thư mục chưa
        if (!topicReferences.contains(topicRef)) {
          // Thêm tham chiếu của chủ đề mới vào danh sách
          topicReferences.add(topicRef);

          // Cập nhật lại danh sách tham chiếu trong tài liệu thư mục
          await folderCollection.doc(folderId).update({'Topics': topicReferences});

          // Cập nhật trường folderId trong tài liệu chủ đề
          await topicRef.update({'folderId': folderId});
        }
      } else {
        throw ('Folder not found');
      }
    } catch (error) {
      print("Error adding topic to folder: $error");
      throw error;
    }
  }

  // Hàm để xóa một chủ đề khỏi một thư mục
  Future<void> removeTopicFromFolder(String folderId, DocumentReference topicRef) async {
    try {
      // Lấy thông tin của thư mục từ Firestore
      DocumentSnapshot folderSnapshot = await folderCollection.doc(folderId).get();

      // Kiểm tra xem thư mục có tồn tại không
      if (folderSnapshot.exists) {
        // Lấy danh sách tham chiếu của các chủ đề từ tài liệu thư mục
        List<DocumentReference> topicReferences = List<DocumentReference>.from(folderSnapshot['Topics']);

        // Kiểm tra xem chủ đề có tồn tại trong thư mục không
        if (topicReferences.contains(topicRef)) {
          // Xóa tham chiếu của chủ đề khỏi danh sách
          topicReferences.remove(topicRef);

          // Cập nhật lại danh sách tham chiếu trong tài liệu thư mục
          await folderCollection.doc(folderId).update({'Topics': topicReferences});

          // Cập nhật trường folderId trong tài liệu chủ đề
          await topicRef.update({'folderId': null});
        }
      } else {
        throw ('Folder not found');
      }
    } catch (error) {
      print("Error removing topic from folder: $error");
      throw error;
    }
  }

  
}
