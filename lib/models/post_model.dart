class Post {
  final String userName;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  int likes;

  Post({
    required this.userName,
    required this.timeAgo,
    required this.content,
    this.imageUrl,
    this.likes = 0,
  });
}