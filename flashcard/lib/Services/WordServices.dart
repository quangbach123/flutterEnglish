import 'package:cloud_firestore/cloud_firestore.dart';

class WordService{
  final CollectionReference Topics= FirebaseFirestore.instance.collection('Topics');
  final CollectionReference words = FirebaseFirestore.instance.collection('Words');
  final CollectionReference Folder = FirebaseFirestore.instance.collection('Folder');
  final CollectionReference User = FirebaseFirestore.instance.collection('User');

  // lay all topic
  Stream<QuerySnapshot> getTopicStream(){
    final wordsStream = Topics.orderBy('topicName',descending: true).snapshots();
    return wordsStream;
  }
  // lay word voi topicId 
Stream<QuerySnapshot> getWordsByTopicId(String topicId) {
      return words.
      where('topicId', isEqualTo: Topics.doc(topicId))
      .snapshots();
}
// lay all word
  Stream<QuerySnapshot> getWordsStream(){
    final wordsStream = words.orderBy('english',descending: true).snapshots();
    return wordsStream;
  }

   // Thêm từ mới
  Future<void> addWord(String english, String vietnam, String topicId) async {
    try {
      await words.add({
        'english': english,
        'vietnam': vietnam,
        'topicId': Topics.doc(topicId), // Tham chiếu đến chủ đề (topic) tương ứng
      });
    } catch (error) {
      print('Error adding word: $error');
      throw error;
    }
  }

  // Xóa từ
  Future<void> deleteWord(String wordId) async {
    try {
      await words.doc(wordId).delete();
    } catch (error) {
      print('Error deleting word: $error');
      throw error;
    }
  }

  // Cập nhật từ
  Future<void> updateWord(String wordId, String english, String vietnam, String topicId) async {
    try {
      await words.doc(wordId).update({
        'english': english,
        'vietnam': vietnam,
        'topicId': Topics.doc(topicId), // Tham chiếu đến chủ đề (topic) tương ứng
      });
    } catch (error) {
      print('Error updating word: $error');
      throw error;
    }
  }
}
