import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live_api/gemini_live_api.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../app.dart';
import '../enums/author.dart';
import '../enums/response_mode.dart';
import '../main.dart';
import '../models/chat_message.dart';
import '../enums/connection_state.dart';
import 'widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final GoogleGenAI _genAI;
  LiveSession? _session;
  final TextEditingController _textController = TextEditingController();

  // 상태 관리 변수
  ConnectionStatus _ConnectionStatus = ConnectionStatus.disconnected;
  bool _isReplying = false;
  final List<ChatMessage> _messages = [];
  ChatMessage? _streamingMessage; // 스트리밍 중인 메시지를 별도로 관리
  String _statusText = "연결을 초기화합니다...";

  // 이미지 및 오디오 관련 변수
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<RecordState>? _recordSub;
  bool _isRecording = false;

  // --- 오디오 및 모드 관리 ---
  // final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<List<int>>? _audioStreamSubscription;

  // bool _isRecording = false;
  final AudioPlayer _audioPlayer = AudioPlayer(); // 오디오 재생기
  ResponseMode _responseMode = ResponseMode.text; // 기본 응답 모드

  // --- 카메라 및 비디오 스트리밍 ---
  CameraController? _cameraController;
  bool _isStreamingVideo = false;
  Timer? _videoFrameTimer;

  Future<void> _initialize() async {
    await _initCamera();
    await _connectToLiveAPI();
  }

  @override
  void initState() {
    super.initState();
    _genAI = GoogleGenAI(apiKey: geminiApiKey);
    _initialize();
    _recordSub = _audioRecorder.onStateChanged().listen((recordState) {
      if (mounted) {
        setState(() => _isRecording = recordState == RecordState.record);
      }
    });
  }

  @override
  void dispose() {
    _session?.close();
    _audioStreamSubscription?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _cameraController?.dispose();
    _videoFrameTimer?.cancel();
    super.dispose();
  }

  void _updateStatus(String text) {
    if (mounted) setState(() => _statusText = text);
  }

  Future<void> _initCamera() async {
    if (!await Permission.camera.request().isGranted) {
      _updateStatus("카메라 권한이 필요합니다.");
      return;
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      _updateStatus("사용 가능한 카메라가 없습니다.");
      return;
    }
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
    );
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      _updateStatus("카메라 초기화 실패: $e");
    }
  }

  // --- 연결 관리 ---
  Future<void> _connectToLiveAPI() async {
    if (_ConnectionStatus == ConnectionStatus.connecting) return;

    // 이전 세션이 있다면 안전하게 종료
    await _session?.close();
    setState(() {
      _session = null;
      _ConnectionStatus = ConnectionStatus.connecting;
      _messages.clear();
      _addMessage(
        ChatMessage(
          text: "Gemini Live API에 연결 중 (${_responseMode.name} 모드)...",
          author: Author.model,
        ),
      );
      _updateStatus("Gemini Live API에 연결 중...");
    });

    try {
      final session = await _genAI.live.connect(
        LiveConnectParameters(
          model: 'gemini-2.0-flash-live-001',
          // model: 'gemini-2.5-flash-preview-native-audio-dialog',
          // *** 수정: 선택된 응답 모드에 따라 GenerationConfig 설정 ***
          config: GenerationConfig(
            responseModalities: _responseMode == ResponseMode.audio
                ? [Modality.AUDIO]
                : [Modality.TEXT],
          ),

          systemInstruction: Content(
            parts: [
              Part(
                text: "You are a friendly assistant. Please answer in Korean.",
              ),
            ],
          ),
          callbacks: LiveCallbacks(
            // onOpen: () => print('✅ WebSocket 연결 성공'),
            onOpen: () => _updateStatus("연결 성공! 마이크와 비디오를 켜보세요."),
            onMessage: _handleLiveAPIResponse,
            onError: (error, stack) {
              print('🚨 에러 발생: $error');
              if (mounted)
                setState(
                  () => _ConnectionStatus = ConnectionStatus.disconnected,
                );
            },
            onClose: (code, reason) {
              print('🚪 연결 종료: $code, $reason');
              if (mounted)
                setState(
                  () => _ConnectionStatus = ConnectionStatus.disconnected,
                );
            },
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _session = session;
          _ConnectionStatus = ConnectionStatus.connected;
          _messages.removeLast(); // "연결 중..." 메시지 제거
          _addMessage(
            ChatMessage(
              text: "안녕하세요! 마이크 버튼을 눌러 말씀해보세요.",
              author: Author.model,
            ),
          );
        });
      }
    } catch (e) {
      print("연결 실패: $e");
      if (mounted)
        setState(() => _ConnectionStatus = ConnectionStatus.disconnected);
    }
  }

  // // --- 메시지 처리 ---
  // void _handleLiveAPIResponse(LiveServerMessage message) {
  //   if (!mounted) return;
  //
  //   final textChunk = message.text;
  //   print('📥 Received message textchunk: ${textChunk}');
  //   if (textChunk != null) {
  //     setState(() {
  //       if (_streamingMessage == null) {
  //         _streamingMessage = ChatMessage(
  //           text: textChunk,
  //           author: Author.model,
  //         );
  //       } else {
  //         _streamingMessage = ChatMessage(
  //           text: _streamingMessage!.text + textChunk,
  //           author: Author.model,
  //         );
  //       }
  //     });
  //   }
  //
  //   if (message.serverContent?.turnComplete ?? false) {
  //     setState(() {
  //       if (_streamingMessage != null) {
  //         _messages.add(_streamingMessage!);
  //         _streamingMessage = null;
  //       }
  //       _isReplying = false;
  //     });
  //   }
  // }
  final StringBuffer _audioBuffer = StringBuffer();

  // --- 메시지 및 오디오 처리 ---_handleLiveAPIResponse
  void _handleLiveAPIResponse(LiveServerMessage message) async {
    if (!mounted) return;

    // --- 텍스트 응답 처리 ---
    final textChunk = message.text;
    if (_responseMode == ResponseMode.text && textChunk != null) {
      setState(() {
        if (_streamingMessage == null) {
          _streamingMessage = ChatMessage(
            text: textChunk,
            author: Author.model,
          );
        } else {
          _streamingMessage = ChatMessage(
            text: _streamingMessage!.text + textChunk,
            author: Author.model,
          );
        }
      });
    }

    // --- 오디오 응답 처리 ---
    final audioPart = message.serverContent?.modelTurn?.parts?.firstWhere(
      (p) => p.inlineData?.mimeType.startsWith('audio/') ?? false,
      orElse: () => Part(),
    );

    if (_responseMode == ResponseMode.audio &&
        audioPart?.inlineData?.data != null) {
      // final mimeType = audioPart!.inlineData!.mimeType;
      // final audioData = base64Decode(audioPart.inlineData!.data);
      //
      // Uint8List playableAudioBytes;
      //
      // // 1. MIME 타입을 확인하여 PCM 데이터인지 판단
      // if (mimeType.startsWith('audio/pcm')) {
      //   // 2. MIME 타입에서 샘플링 레이트 추출 (예: 'audio/pcm;rate=24000')
      //   final rateMatch = RegExp(r'rate=(\d+)').firstMatch(mimeType);
      //   final sampleRate =
      //       int.tryParse(rateMatch?.group(1) ?? '24000') ?? 24000;
      //
      //   print('PCM 데이터 수신. Sample Rate: $sampleRate. WAV 헤더 추가 중...');
      //   // 3. WAV 헤더를 추가하여 재생 가능한 바이트로 변환
      //   playableAudioBytes = addWavHeader(audioData, sampleRate: sampleRate);
      // } else {
      //   // PCM이 아닌 다른 포맷(MP3, AAC 등)은 그대로 사용
      //   print('$mimeType 포맷 데이터 수신. 직접 재생 시도 중...');
      //   playableAudioBytes = audioData;
      // }
      //
      // // 4. 변환된 오디오 바이트를 재생
      // _audioPlayer.play(BytesSource(playableAudioBytes));
      //
      // // UI 피드백
      // setState(() {
      //   _streamingMessage = ChatMessage(
      //     text: "🔊 모델 음성 응답 재생 중...",
      //     author: Author.model,
      //     isAudio: true,
      //   );
      // });
      _audioBuffer.write(audioPart!.inlineData!.data);
    }

    if (message.serverContent?.turnComplete ?? false) {
      if (_audioBuffer.isNotEmpty) {
        print('턴 종료. 전체 오디오 데이터를 파일로 저장합니다.');

        final pcmBytes = base64Decode(_audioBuffer.toString());
        final wavBytes = addWavHeader(pcmBytes, sampleRate: 24000);

        // 쓰기 가능한 디렉토리에 파일 저장
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/gemini_response.wav';
        final file = File(filePath);
        await file.writeAsBytes(wavBytes);

        print('✅ 오디오 파일 저장 완료: $filePath');
        print('이 파일을 컴퓨터로 복사해서 재생해보세요.');

        // 파일 저장 후 재생 시도
        try {
          print('저장된 파일 재생 시도...');
          // UI 피드백
          setState(() {
            _streamingMessage = ChatMessage(
              text: "🔊 모델 음성 응답 재생 중...",
              author: Author.model,
              isAudio: true,
            );
          });
          await _audioPlayer.play(DeviceFileSource(filePath));
          print('재생 명령 성공.');
        } catch (e) {
          print('저장된 파일 재생 실패: $e');
        }

        // 버퍼 초기화
        _audioBuffer.clear();
      }

      setState(() {
        if (_streamingMessage != null) {
          _messages.add(_streamingMessage!);
          _streamingMessage = null;
          _isReplying = false;
        }
      });
    }
  }

  void _addMessage(ChatMessage message) {
    if (!mounted) return;
    setState(() {
      _messages.add(message);
    });
  }

  // --- 멀티모달 입력 및 전송 ---
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  // // *** _toggleRecording 함수 수정 ***
  // Future<void> _toggleRecording() async {
  //   if (_isRecording) {
  //     // --- 녹음 중지 로직 ---
  //     final path = await _audioRecorder.stop();
  //     setState(() => _isRecording = false); // UI 즉시 업데이트
  //
  //     if (path != null) {
  //       print("녹음 중지. 파일 경로: $path");
  //
  //       // 1. 녹음된 파일을 바이트로 읽기
  //       final file = File(path);
  //       final audioBytes = await file.readAsBytes();
  //
  //       // 2. 오디오 파일을 UI에 메시지로 표시
  //       // 텍스트는 비워두고, 이미지 표시 로직처럼 오디오 아이콘을 표시할 수 있습니다.
  //       // 여기서는 간단하게 텍스트로 표현합니다.
  //       _addMessage(ChatMessage(text: "[사용자 음성 전송됨]", author: Author.user));
  //
  //       // 3. 서버로 오디오 데이터 전송
  //       if (_session != null) {
  //         setState(() => _isReplying = true);
  //
  //         _session!.sendMessage(
  //           LiveClientMessage(
  //             clientContent: LiveClientContent(
  //               turns: [
  //                 Content(
  //                   role: "user",
  //                   parts: [
  //                     Part(
  //                       inlineData: Blob(
  //                         // Gemini API는 다양한 오디오 포맷을 지원합니다.
  //                         // record 패키지의 기본 인코더에 맞춰 MIME 타입을 설정합니다.
  //                         // 예: aacLc, pcm16bits, flac, opus, amrNb, amrWb
  //                         mimeType: 'audio/wav', // RecordConfig에 따라 변경 필요
  //                         data: base64Encode(audioBytes),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //               turnComplete: true,
  //             ),
  //           ),
  //         );
  //       }
  //
  //       // 4. 임시 파일 삭제
  //       await file.delete();
  //     }
  //   } else {
  //     // --- 녹음 시작 로직 ---
  //     if (await Permission.microphone.request().isGranted) {
  //       final tempDir = await getTemporaryDirectory();
  //       final filePath =
  //           '${tempDir.path}/temp_audio.m4a'; // 확장자를 .m4a (AAC) 등으로 변경
  //
  //       // MIME 타입과 일치하는 인코더 사용 (예: AAC)
  //       await _audioRecorder.start(
  //         const RecordConfig(encoder: AudioEncoder.aacLc),
  //         path: filePath,
  //       );
  //     } else {
  //       print("마이크 권한이 거부되었습니다.");
  //       if (mounted) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(const SnackBar(content: Text("마이크 권한이 필요합니다.")));
  //       }
  //     }
  //   }
  // }

  // --- 오디오/비디오 스트리밍 제어 ---

  Future<void> _toggleAudioStreaming() async {
    if (_isRecording) {
      await _stopAudioStreaming();
    } else {
      await _startAudioStreaming();
    }
  }

  Future<void> _startAudioStreaming() async {
    if (_session == null) return;
    if (!await Permission.microphone.request().isGranted) {
      _updateStatus("마이크 권한이 필요합니다.");
      return;
    }
    setState(() => _isRecording = true);
    final stream = await _audioRecorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    _audioStreamSubscription = stream.listen(
      (data) => _session!.sendAudio(data),
    );
  }

  Future<void> _stopAudioStreaming() async {
    await _audioStreamSubscription?.cancel();
    await _audioRecorder.stop();
    _audioStreamSubscription = null;
    if (mounted) setState(() => _isRecording = false);
  }

  Future<void> _toggleVideoStreaming() async {
    if (_isStreamingVideo) {
      _stopVideoStreaming();
    } else {
      await _startVideoStreaming();
    }
  }

  Future<void> _startVideoStreaming() async {
    if (_session == null ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized)
      return;

    setState(() => _isStreamingVideo = true);
    // 1초에 2프레임 (500ms 간격) 전송
    _videoFrameTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      if (!_isStreamingVideo) {
        timer.cancel();
        return;
      }
      try {
        final image = await _cameraController!.takePicture();
        final imageBytes = await image.readAsBytes();

        // 이미지 크기를 줄여서 전송 (선택적이지만 권장)
        final resizedImage = img.copyResize(
          img.decodeImage(imageBytes)!,
          width: 640,
        );
        final jpegBytes = img.encodeJpg(resizedImage, quality: 75);

        _session!.sendVideo(jpegBytes);
      } catch (e) {
        print("프레임 캡쳐/전송 오류: $e");
      }
    });
  }

  void _stopVideoStreaming() {
    _videoFrameTimer?.cancel();
    _videoFrameTimer = null;
    if (mounted) setState(() => _isStreamingVideo = false);
  }

  Future<void> _startStreaming() async {
    if (_session == null || _ConnectionStatus != ConnectionStatus.connected) {
      print("세션이 연결되지 않았습니다.");
      return;
    }
    if (await Permission.microphone.request().isGranted) {
      setState(() => _isRecording = true);

      // record 패키지의 startStream은 바이트 스트림을 반환합니다.
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits, // PCM 16-bit 인코딩
          sampleRate: 16000, // 16kHz 샘플링 레이트
          numChannels: 1, // 모노 채널
        ),
      );

      _audioStreamSubscription = stream.listen(
        (data) {
          // 마이크에서 오디오 데이터 청크가 들어올 때마다 호출됨
          // Live API 세션으로 오디오 데이터 전송
          _session!.sendAudio(data);
        },
        onError: (error) {
          print("오디오 스트림 에러: $error");
          _stopStreaming();
        },
        onDone: () {
          print("오디오 스트림 종료됨.");
          _stopStreaming();
        },
      );
    } else {
      print("마이크 권한이 거부되었습니다.");
    }
  }

  Future<void> _stopStreaming() async {
    await _audioRecorder.stop();
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
    if (mounted) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopStreaming();
    } else {
      await _startStreaming();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text;
    if ((text.isEmpty && _pickedImage == null) ||
        _isReplying ||
        _session == null)
      return;

    // 사용자 메시지를 UI에 먼저 추가
    _addMessage(
      ChatMessage(text: text, author: Author.user, image: _pickedImage),
    );

    setState(() => _isReplying = true);

    final List<Part> parts = [];
    if (text.isNotEmpty) {
      parts.add(Part(text: text));
    }
    if (_pickedImage != null) {
      final imageBytes = await _pickedImage!.readAsBytes();
      parts.add(
        Part(
          inlineData: Blob(
            mimeType: 'image/jpeg',
            data: base64Encode(imageBytes),
          ),
        ),
      );
    }

    _session!.sendMessage(
      LiveClientMessage(
        clientContent: LiveClientContent(
          turns: [Content(role: "user", parts: parts)],
          turnComplete: true,
        ),
      ),
    );

    _textController.clear();
    setState(() => _pickedImage = null);
  }

  Widget _buildControlButtons() {
    if (_ConnectionStatus != ConnectionStatus.connected) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 비디오 스트리밍 버튼
          FloatingActionButton(
            heroTag: 'video_fab',
            onPressed: _toggleVideoStreaming,
            backgroundColor: _isStreamingVideo
                ? Colors.blue
                : Colors.grey.shade300,
            child: Icon(
              _isStreamingVideo ? Icons.videocam_off : Icons.videocam,
              color: _isStreamingVideo ? Colors.white : Colors.black,
            ),
          ),
          // 오디오 스트리밍 버튼
          FloatingActionButton.large(
            heroTag: 'audio_fab',
            onPressed: _toggleAudioStreaming,
            backgroundColor: _isRecording ? Colors.red : Colors.grey.shade300,
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 48,
            ),
          ),
          // 빈 공간 채우기 용 (혹은 다른 버튼 추가)
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          if (_pickedImage != null)
            Container(
              height: 100,
              padding: const EdgeInsets.only(bottom: 8),
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_pickedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.white70,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                        onPressed: () => setState(() => _pickedImage = null),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined),
                onPressed: _pickImage,
              ),
              IconButton(
                icon: Icon(
                  _isRecording
                      ? Icons.stop_circle_outlined
                      : Icons.mic_none_outlined,
                ),
                color: _isRecording
                    ? Colors.red
                    : Theme.of(context).iconTheme.color,
                onPressed: _toggleRecording,
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration.collapsed(
                    hintText: '메시지 또는 이미지 설명 입력',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _toggleRecording,
            backgroundColor: _isRecording
                ? Colors.red.shade400
                : Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: _isRecording
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSecondaryContainer,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // // --- UI 위젯 빌더 ---
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Gemini Live Full-duplex'),
  //       actions: [
  //         // *** 추가: 응답 모드 선택 메뉴 ***
  //         PopupMenuButton<ResponseMode>(
  //           onSelected: (ResponseMode mode) {
  //             if (mode != _responseMode) {
  //               setState(() => _responseMode = mode);
  //               // 모드가 변경되면 재연결
  //               _connectToLiveAPI();
  //             }
  //           },
  //           itemBuilder: (BuildContext context) =>
  //               <PopupMenuEntry<ResponseMode>>[
  //                 const PopupMenuItem<ResponseMode>(
  //                   value: ResponseMode.text,
  //                   child: Text('텍스트 응답'),
  //                 ),
  //                 const PopupMenuItem<ResponseMode>(
  //                   value: ResponseMode.audio,
  //                   child: Text('오디오 응답'),
  //                 ),
  //               ],
  //           icon: Icon(
  //             _responseMode == ResponseMode.text
  //                 ? Icons.text_fields
  //                 : Icons.graphic_eq,
  //           ),
  //         ),
  //         Padding(
  //           padding: const EdgeInsets.only(right: 16.0),
  //           child: Icon(
  //             Icons.circle,
  //             color: _ConnectionStatus == ConnectionStatus.connected
  //                 ? Colors.green
  //                 : _ConnectionStatus == ConnectionStatus.connecting
  //                 ? Colors.orange
  //                 : Colors.red,
  //             size: 16,
  //           ),
  //         ),
  //       ],
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.all(12.0),
  //       child: Column(
  //         children: [
  //           Expanded(
  //             child: ListView.builder(
  //               padding: const EdgeInsets.all(8.0),
  //               reverse: true,
  //               itemCount:
  //                   _messages.length + (_streamingMessage == null ? 0 : 1),
  //               itemBuilder: (context, index) {
  //                 if (_streamingMessage != null && index == 0) {
  //                   return ChatBubble(message: _streamingMessage!);
  //                 }
  //                 final messageIndex =
  //                     index - (_streamingMessage == null ? 0 : 1);
  //                 final message = _messages.reversed.toList()[messageIndex];
  //                 return ChatBubble(message: message);
  //               },
  //             ),
  //           ),
  //           if (_isReplying) const LinearProgressIndicator(),
  //           const Divider(height: 1.0),
  //           if (_ConnectionStatus == ConnectionStatus.disconnected)
  //             Padding(
  //               padding: const EdgeInsets.all(8.0),
  //               child: ElevatedButton.icon(
  //                 icon: const Icon(Icons.refresh),
  //                 label: const Text("연결 재시도"),
  //                 onPressed: _connectToLiveAPI,
  //               ),
  //             ),
  //           if (_ConnectionStatus == ConnectionStatus.connected)
  //             _buildTextComposer(),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // --- UI 위젯 빌더 ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Vision Streamer'),
        actions: [
          // *** 추가: 응답 모드 선택 메뉴 ***
          PopupMenuButton<ResponseMode>(
            onSelected: (ResponseMode mode) {
              if (mode != _responseMode) {
                setState(() => _responseMode = mode);
                // 모드가 변경되면 재연결
                _connectToLiveAPI();
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<ResponseMode>>[
                  const PopupMenuItem<ResponseMode>(
                    value: ResponseMode.text,
                    child: Text('텍스트 응답'),
                  ),
                  const PopupMenuItem<ResponseMode>(
                    value: ResponseMode.audio,
                    child: Text('오디오 응답'),
                  ),
                ],
            icon: Icon(
              _responseMode == ResponseMode.text
                  ? Icons.text_fields
                  : Icons.graphic_eq,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.circle,
              color: _ConnectionStatus == ConnectionStatus.connected
                  ? Colors.green
                  : _ConnectionStatus == ConnectionStatus.connecting
                  ? Colors.orange
                  : Colors.red,
              size: 16,
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          Positioned.fill(
            top: 16,
            left: 16,
            right: 16,
            bottom: 160,
            child: Builder(
              builder: (context) {
                if (_cameraController != null &&
                    _cameraController!.value.isInitialized) {
                  return Container(
                    decoration: ShapeDecoration(
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(42),
                        side: BorderSide(color: Colors.grey,width: 2),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .1),
                          spreadRadius: 4,
                          blurRadius: 2,
                        ),
                      ],
                    ),

                    child: ClipRSuperellipse(
                      borderRadius: BorderRadius.circular(42),
                      child: CameraPreview(_cameraController!),
                    ),
                  );
                  // // final size = MediaQuery.of(context).size;
                  // // final deviceRatio = size.width / size.height;
                  // // final xScale =
                  // //     _cameraController!.value.aspectRatio / deviceRatio;
                  // // // Modify the yScale if you are in Landscape
                  // // final yScale = 1.0;
                  //
                  // final size = MediaQuery.of(context).size;
                  // final deviceRatio = size.width / size.height;
                  // final mediaSize = MediaQuery.sizeOf(context);
                  // final scale =
                  //     1 /
                  //     (_cameraController!.value.aspectRatio *
                  //         mediaSize.aspectRatio);
                  //
                  // return Transform.scale(
                  //   scale: scale,
                  //   alignment: Alignment.topCenter,
                  //   child: CameraPreview(_cameraController!),
                  // );
                  // return Container(
                  //   child: Transform.scale(
                  //     alignment: Alignment.center,
                  //     scale: _cameraController!.value.aspectRatio / deviceRatio,
                  //     child: AspectRatio(
                  //         aspectRatio: _cameraController!.value.aspectRatio,
                  //         child: CameraPreview(_cameraController!)),
                  //   ),
                  // );
                }
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              },
            ),
          ),
        ],
      ),

      // Column(
      //   children: [
      //     // 카메라 프리뷰
      //     Expanded(
      //       flex: 3,
      //       child: Container(
      //         // color: Colors.black,
      //         child:
      //             _cameraController != null &&
      //                 _cameraController!.value.isInitialized
      //             ? ClipRSuperellipse(
      //                 borderRadius: BorderRadius.circular(24),
      //                 child: CameraPreview(_cameraController!),
      //               )
      //             : const Center(child: CircularProgressIndicator.adaptive()),
      //       ),
      //     ),
      //     // 상태 및 메시지 표시 영역
      //     Expanded(
      //       flex: 2,
      //       child: Container(
      //         color: Theme.of(context).colorScheme.surface,
      //         width: double.infinity,
      //         padding: const EdgeInsets.all(16.0),
      //         child: Column(
      //           mainAxisAlignment: MainAxisAlignment.center,
      //           children: [
      //             Text(
      //               _statusText,
      //               style: Theme.of(context).textTheme.titleMedium,
      //             ),
      //             const SizedBox(height: 20),
      //             if (_ConnectionStatus == ConnectionStatus.disconnected)
      //               ElevatedButton.icon(
      //                 icon: const Icon(Icons.refresh),
      //                 label: const Text("연결 재시도"),
      //                 onPressed: _connectToLiveAPI,
      //               ),
      //           ],
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
      // 컨트롤 버튼
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildControlButtons(),
    );
  }
}
