import 'dart:io';

import 'package:ai_sprint_25_gemini_live/enums/author.dart';
import 'package:ai_sprint_25_gemini_live/models/chat_message.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.author == Author.user
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: message.author == Author.user
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.image != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(message.image!.path),
                          height: 150,
                        ),
                      ),
                    ),
                  if (message.isAudio)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.multitrack_audio,
                          size: 20,
                          color: message.author == Author.user
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(message.text),
                      ],
                    )
                  else if (message.text.isNotEmpty)
                    SelectableText(message.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
