// lib/wav_header.dart
import 'dart:typed_data';

/// PCM 오디오 데이터에 WAV 헤더를 추가하여 완전한 WAV 파일 바이트를 생성합니다.
///
/// [pcmBytes] 순수 PCM 오디오 데이터입니다.
/// [sampleRate] 오디오의 샘플링 레이트입니다 (예: 24000).
/// [numChannels] 채널 수입니다 (1=모노, 2=스테레오).
/// [bitsPerSample] 샘플당 비트 수입니다 (일반적으로 16).
Uint8List addWavHeader(
  Uint8List pcmBytes, {
  required int sampleRate,
  int numChannels = 1,
  int bitsPerSample = 16,
}) {
  final byteRate = (sampleRate * numChannels * bitsPerSample) ~/ 8;
  final blockAlign = (numChannels * bitsPerSample) ~/ 8;
  final pcmLength = pcmBytes.length;
  final totalLength = pcmLength + 36;

  final header = ByteData(44);

  // RIFF chunk descriptor
  header.setUint8(0, 0x52); // 'R'
  header.setUint8(1, 0x49); // 'I'
  header.setUint8(2, 0x46); // 'F'
  header.setUint8(3, 0x46); // 'F'
  header.setUint32(4, totalLength, Endian.little);
  header.setUint8(8, 0x57); // 'W'
  header.setUint8(9, 0x41); // 'A'
  header.setUint8(10, 0x56); // 'V'
  header.setUint8(11, 0x45); // 'E'

  // "fmt " sub-chunk
  header.setUint8(12, 0x66); // 'f'
  header.setUint8(13, 0x6d); // 'm'
  header.setUint8(14, 0x74); // 't'
  header.setUint8(15, 0x20); // ' '
  header.setUint32(16, 16, Endian.little); // Sub-chunk1Size for PCM
  header.setUint16(20, 1, Endian.little); // AudioFormat, 1 for PCM
  header.setUint16(22, numChannels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);

  // "data" sub-chunk
  header.setUint8(36, 0x64); // 'd'
  header.setUint8(37, 0x61); // 'a'
  header.setUint8(38, 0x74); // 't'
  header.setUint8(39, 0x61); // 'a'
  header.setUint32(40, pcmLength, Endian.little);

  // WAV 헤더와 PCM 데이터를 합칩니다.
  final wavBytes = Uint8List(44 + pcmLength);
  wavBytes.setRange(0, 44, header.buffer.asUint8List());
  wavBytes.setRange(44, wavBytes.length, pcmBytes);

  return wavBytes;
}
