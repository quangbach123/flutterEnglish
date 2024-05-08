import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashcard/Models/Folder.dart';
import 'package:flashcard/Models/Topic.dart';
import 'package:flashcard/Models/User.dart';
import 'package:firebase_storage/firebase_storage.dart';
class UserService {
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('User');
  final CollectionReference foldersCollection = FirebaseFirestore.instance.collection('Folder');
  final CollectionReference topicsCollection = FirebaseFirestore.instance.collection('Topic');
   final FirebaseStorage storage = FirebaseStorage.instance;

  // Hàm để lấy ra một user từ Firestore dựa trên id
Future<User?> getUserById(String userId) async {
    try {
      // Thực hiện truy vấn để lấy ra user với id nhất định
      DocumentSnapshot doc = await usersCollection.doc(userId).get();

      // Kiểm tra xem tài liệu có tồn tại không
      if (doc.exists) {
        // Kiểm tra trước khi truy cập vào trường 'AvatarUrl', 'Folders' và 'Topics'
        String? avatarUrl;
        List<DocumentReference>? folderReferences;
        List<DocumentReference>? topicReferences;
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?; // Ép kiểu để sử dụng 'data' như một Map
        if (data != null) {
          if (data.containsKey('AvatarUrl')) {
            avatarUrl = data['AvatarUrl'];
          }
          if (data.containsKey('Folders')) {
            folderReferences = List<DocumentReference>.from(data['Folders']);
          }
          if (data.containsKey('Topics')) {
            topicReferences = List<DocumentReference>.from(data['Topics']);
          }
        }
        
        // Tạo một user từ dữ liệu của tài liệu Firestore
        return User(
          id: doc.id,
          email: data!['Email'], // Sử dụng 'data' để truy cập dữ liệu
          name: data['Name'],
          folderReferences: folderReferences ?? [], // Sử dụng giá trị mặc định nếu trường không tồn tại
          topicReferences: topicReferences ?? [], // Sử dụng giá trị mặc định nếu trường không tồn tại
          avatarUrl: avatarUrl, // Truyền giá trị của 'AvatarUrl' hoặc null nếu không tồn tại
        );
      } else {
        // Trả về null nếu không tìm thấy user
        return null;
      }
    } catch (error) {
      // Xử lý lỗi nếu có
      print("Error getting user by id: $error");
      // Trả về null trong trường hợp có lỗi
      return null;
    }
  }
  Future<User?> getUserByEmail(String email) async {
  try {
    // Thực hiện truy vấn để lấy ra người dùng với email nhất định
    QuerySnapshot querySnapshot = await usersCollection.where('Email', isEqualTo: email).get();

    // Kiểm tra xem có bất kỳ tài liệu nào phù hợp không
    if (querySnapshot.docs.isNotEmpty) {
      // Lấy dữ liệu từ tài liệu đầu tiên trong kết quả truy vấn
      DocumentSnapshot doc = querySnapshot.docs.first;
      // Tạo một user từ dữ liệu của tài liệu Firestore
      return User.fromFirestore(doc);
    } else {
      // Trả về null nếu không tìm thấy người dùng với email tương ứng
      return null;
    }
  } catch (error) {
    // Xử lý lỗi nếu có
    print("Error getting user by email: $error");
    // Trả về null trong trường hợp có lỗi
    return null;
  }
}
  

  // Hàm để thêm một folder mới vào user
Future<void> addFolderToUser(String userId, String folderName) async {
  try {
    // Tạo một tham chiếu đến user trong Firestore
    DocumentReference userRef = usersCollection.doc(userId);

    // Tạo một folder mới trong Firestore
    DocumentReference folderRef = await FirebaseFirestore.instance.collection('Folder').add({
      'Name': folderName,
      'userId': userId,
      'Topics': [], // Khởi tạo danh sách tham chiếu đến các topic là trống
    });

    // Lấy dữ liệu hiện tại của user
    DocumentSnapshot userDoc = await userRef.get();

    // Kiểm tra xem user có tồn tại không
    if (userDoc.exists) {
      // Thêm tham chiếu của folder mới vào danh sách Folders của user
      List<DocumentReference> folderRefs = userDoc['Folders'] != null
          ? List<DocumentReference>.from(userDoc['Folders'])
          : [];
      folderRefs.add(folderRef);

      // Cập nhật dữ liệu của user trong Firestore
      await userRef.update({'Folders': folderRefs});
    } else {
      print('User does not exist');
    }
  } catch (error) {
    // Xử lý lỗi nếu có
    print("Error adding folder to user: $error");
  }
}
// đổi tên folder
Future<void> updateFolderName(String folderId, String newName) async {
  try {
    // Tạo một tham chiếu đến folder trong Firestore
    DocumentReference folderRef = FirebaseFirestore.instance.collection('Folder').doc(folderId);

    // Cập nhật trường 'Name' của folder
    await folderRef.update({'Name': newName});
  } catch (error) {
    // Xử lý lỗi nếu có
    print("Error updating folder name: $error");
  }
}

// xóa folder
Future<void> deleteFolder(String userId, String folderId) async {
  try {
    // Tạo một tham chiếu đến user trong Firestore
    DocumentReference userRef = usersCollection.doc(userId);

    // Lấy dữ liệu hiện tại của user
    DocumentSnapshot userDoc = await userRef.get();

    // Kiểm tra xem user có tồn tại không
    if (userDoc.exists) {
      // Lấy danh sách các tham chiếu của các folder của user
      List<DocumentReference> folderRefs = userDoc['Folders'] != null
          ? List<DocumentReference>.from(userDoc['Folders'])
          : [];

      // Xóa tham chiếu của folder cần xóa khỏi danh sách
      folderRefs.removeWhere((ref) => ref.id == folderId);

      // Cập nhật lại danh sách tham chiếu của user trong Firestore
      await userRef.update({'Folders': folderRefs});

      // Xóa folder khỏi Firestore
      await FirebaseFirestore.instance.collection('Folder').doc(folderId).delete();
    } else {
      print('User does not exist');
    }
  } catch (error) {
    // Xử lý lỗi nếu có
    print("Error deleting folder: $error");
  }

 }
// Hàm để lấy ra tất cả các chủ đề của người dùng
Future<List<Topic>> getAllTopicsByUserId(String userId) async {
  try {
    List<Topic> topics = [];
    // Lấy tham chiếu của tài liệu người dùng từ Firestore
    DocumentReference userRef = usersCollection.doc(userId);
    // Lấy danh sách tham chiếu của các chủ đề từ tài liệu người dùng
    List<DocumentReference> topicRefs = (await userRef.get())['Topics'].cast<DocumentReference>() ?? [];
    // Lấy dữ liệu thực sự của các chủ đề từ Firestore
    for (DocumentReference topicRef in topicRefs) {
      DocumentSnapshot topicDoc = await topicRef.get();
      topics.add(Topic.fromFirestore(topicDoc));
    }
    return topics;
  } catch (error) {
    print("Error getting all topics by user ID: $error");
    throw error;
  }
}



// Hàm để lấy ra tất cả các thư mục của người dùng
Future<List<Folder>> getAllFoldersByUserId(String userId) async {
  try {
    List<Folder> folders = [];
    // Lấy tham chiếu của tài liệu người dùng từ Firestore
    DocumentReference userRef = usersCollection.doc(userId);
    // Lấy dữ liệu của tài liệu người dùng từ Firestore
    DocumentSnapshot userDoc = await userRef.get();
    // Kiểm tra nếu tài liệu người dùng không null và có chứa trường 'Folders'
    if (userDoc != null && (userDoc.data() as Map<String, dynamic>?)?.containsKey('Folders') == true) {
      // Lấy danh sách tham chiếu của các thư mục từ tài liệu người dùng
      List<DocumentReference> folderRefs = (userDoc.data() as Map<String, dynamic>)['Folders'].cast<DocumentReference>() ?? [];
      // Lấy dữ liệu thực sự của các thư mục từ Firestore
      for (DocumentReference folderRef in folderRefs) {
        DocumentSnapshot folderDoc = await folderRef.get();
        folders.add(Folder.fromFirestore(folderDoc));
      }
    }
    return folders;
  } catch (error) {
    print("Error getting all folders by user ID: $error");
    throw error;
  }
}


  Future<void> updateUserAvatar(String userId, Uint8List imageData) async {
    try {
      // Tạo tham chiếu đến ảnh đại diện trên Firebase Storage
      Reference ref = FirebaseStorage.instance.ref().child('avatars/$userId/avatar.jpg');

      // Tải lên ảnh đại diện lên Firebase Storage
      UploadTask uploadTask = ref.putData(imageData);

      // Chờ cho quá trình tải lên hoàn tất và lấy URL của ảnh
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Cập nhật URL của ảnh đại diện trong tài liệu người dùng trên Firestore
      await usersCollection.doc(userId).update({'AvatarUrl': downloadUrl});
    } catch (error) {
      print("Error updating user avatar: $error");
      throw error;
    }
  }



}
