class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime time;

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
  });
}
