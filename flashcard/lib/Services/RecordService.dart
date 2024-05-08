import 'package:cloud_firestore/cloud_firestore.dart';
class RecordService{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   Future<void> saveRecord({
    required String userId,
    required String topicId,
    required double percentageCorrect,
    required int correctCount,
    required int wrongCount,
    required String elapsedTime,
    required String typeTest,
  }) async {
    try {
      // Truy vấn từ 'Topics' collection để lấy thông tin của topic dựa trên topicId
      final topicSnapshot = await _firestore.collection('Topics').doc(topicId).get();
      final topicName = topicSnapshot.data()?['topicName'];

      // Kiểm tra xem đã có bản ghi nào có userId và topicId giống nhau chưa
      final querySnapshot = await _firestore
          .collection('Record')
          .where('userId', isEqualTo: userId)
          .where('topicId', isEqualTo: topicId)
          .where('typeTest', isEqualTo: typeTest)
          .get();

      // Nếu không có bản ghi nào giống, thêm một bản ghi mới
      if (querySnapshot.docs.isEmpty) {
        await _firestore.collection('Record').add({
          'userId': userId,
          'topicId': topicId,
          'topicName': topicName, // Lưu trường topicName
          'percentageCorrect': percentageCorrect,
          'correctCount': correctCount,
          'wrongCount': wrongCount,
          'elapsedTime': elapsedTime,
          'timestamp': FieldValue.serverTimestamp(),
          'typeTest': typeTest,
          'times': 1, // Thêm trường times với giá trị mặc định là 1
        });
      } else {
        // Nếu có bản ghi giống
        final existingRecord = querySnapshot.docs.first;
        final existingPercentageCorrect = existingRecord['percentageCorrect'];
        final existingElapsedTime = existingRecord['elapsedTime'];
        final existingTimes = existingRecord['times'];

        // So sánh percentageCorrect và elapsedTime
        if (percentageCorrect > existingPercentageCorrect ||
            (percentageCorrect == existingPercentageCorrect &&
                elapsedTime.compareTo(existingElapsedTime) < 0)) {
          // Cập nhật thông tin nếu percentageCorrect cao hơn hoặc
          // nếu điểm số bằng nhau, thì xét thời gian
          await existingRecord.reference.update({
            'percentageCorrect': percentageCorrect,
            'correctCount': correctCount,
            'wrongCount': wrongCount,
            'elapsedTime': elapsedTime,
            'timestamp': FieldValue.serverTimestamp(),
            'typeTest': typeTest,
            'times': existingTimes + 1, // Cập nhật trường times
          });
        } else {
          await existingRecord.reference.update({
            'times': existingRecord['times'] + 1
          });
        }
      }
    } catch (e) {
      print('Error saving record: $e');
    }
  }
    Future<List<DocumentSnapshot>> getRecordsByTopicId(String topicId, {required String typeTest}) async {
    try {
      // Thực hiện truy vấn để lấy ra tất cả các bản ghi có topicId tương ứng
      final querySnapshot = await _firestore
          .collection('Record')
          .where('topicId', isEqualTo: topicId)
          .orderBy('percentageCorrect', descending: true) // Sắp xếp theo điểm số giảm dần
          .orderBy('elapsedTime', descending: false) // Sắp xếp theo thời gian tăng dần nếu điểm số bằng nhau
          .get();

      // Trả về danh sách các document
      return querySnapshot.docs;
    } catch (e) {
      print('Error getting records: $e');
      return []; // Trả về một danh sách rỗng nếu có lỗi xảy ra
    }
  }

      Future<List<DocumentSnapshot>> getRecordsByTopicId2(String typeTest) async {
    try {
      // Thực hiện truy vấn để lấy ra tất cả các bản ghi có topicId tương ứng
      final querySnapshot = await _firestore
          .collection('Record')
          .where('typeTest', isEqualTo: typeTest)
          .orderBy('percentageCorrect', descending: true) // Sắp xếp theo điểm số giảm dần
          .orderBy('elapsedTime', descending: false) // Sắp xếp theo thời gian tăng dần nếu điểm số bằng nhau
          .get();

      // Trả về danh sách các document
      return querySnapshot.docs;
    } catch (e) {
      print('Error getting records: $e');
      return []; // Trả về một danh sách rỗng nếu có lỗi xảy ra
    }
  }

Future<List<DocumentSnapshot>> getRecordsByTypeTestAndTopicId(String typeTest, String topicId) async {
  try {
    final querySnapshot = await _firestore
        .collection('Record')
        .where('typeTest', isEqualTo: typeTest)
        .where('topicId', isEqualTo: topicId)
        .orderBy('percentageCorrect', descending: true)
        .orderBy('elapsedTime', descending: false)
        .get();

    return querySnapshot.docs;
  } catch (e) {
    print('Error getting records by typeTest and topicId: $e');
    return [];
  }
}
Future<List<DocumentSnapshot>> getRecordsByFlashCardTypeTestAndTopicId(String topicId) async {
  try {
    final querySnapshot = await _firestore
        .collection('Record')
        .where('typeTest', isEqualTo: 'FlashCard')
        .where('topicId', isEqualTo: topicId) // Lọc theo topicId truyền vào
        .orderBy('times', descending: true) // Sắp xếp theo times tăng dần
        .orderBy('percentageCorrect', descending: true) // Sắp xếp theo percentageCorrect giảm dần
        .orderBy('elapsedTime', descending: false) // Sắp xếp theo elapsedTime tăng dần
        .get();

    return querySnapshot.docs;
  } catch (e) {
    print('Error getting records by FlashCard typeTest and topicId: $e');
    return [];
  }
}



Future<List<DocumentSnapshot>> getRecordsByTypeTestTopicIdAndUserId(String typeTest, String topicId, String userId) async {
  try {
    final querySnapshot = await _firestore
        .collection('Record')
        .where('typeTest', isEqualTo: typeTest)
        .where('topicId', isEqualTo: topicId)
        .where('userId', isEqualTo: userId)
        .orderBy('percentageCorrect', descending: true)
        .orderBy('elapsedTime', descending: false)
        .get();

    return querySnapshot.docs;
  } catch (e) {
    print('Error getting records by typeTest, topicId, and userId: $e');
    return [];
  }
}
  Future<List<DocumentSnapshot>> getRecordsByUserIdAndPercentageCorrect(
      String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('Record')
          .where('userId', isEqualTo: userId)
          .where('percentageCorrect', isEqualTo: 100)
          .get();
          
      return querySnapshot.docs;
    } catch (e) {
      print('Error getting records by userId and percentageCorrect: $e');
      return [];
    }
  }

 
}