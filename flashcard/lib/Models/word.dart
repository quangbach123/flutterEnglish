class Word {
  final String id;
  final String english;
  final String vietnam;
  final String topicId;
  bool isFavorite;

  Word({
    required this.id,
    required this.english,
    required this.vietnam,
    required this.topicId,
    this.isFavorite = false, // Mặc định là không yêu thích
  });


}
