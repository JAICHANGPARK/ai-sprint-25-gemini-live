

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gemini_live_api/gemini_live_api.dart';

import 'app.dart';

const String geminiApiKey = "";

// LiveSession 클래스에 sendVideo 메소드 추가
extension LiveSessionExtensions on LiveSession {
  void sendVideo(List<int> imageBytes) {
    sendMessage(
      LiveClientMessage(
        realtimeInput: LiveClientRealtimeInput(
          video: Blob(mimeType: 'image/jpeg', data: base64Encode(imageBytes)),
        ),
      ),
    );
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}


