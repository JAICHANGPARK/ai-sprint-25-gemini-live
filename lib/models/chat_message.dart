import 'package:camera/camera.dart';

import '../enums/author.dart';

class ChatMessage {
  final String text;
  final Author author;
  final XFile? image;
  final bool isAudio; // 오디오 메시지 여부 플래그

  ChatMessage({
    required this.text,
    required this.author,
    this.image,
    this.isAudio = false,
  });
}