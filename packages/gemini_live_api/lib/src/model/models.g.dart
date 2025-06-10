// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Part _$PartFromJson(Map<String, dynamic> json) => Part(
  text: json['text'] as String?,
  inlineData: json['inlineData'] == null
      ? null
      : Blob.fromJson(json['inlineData'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PartToJson(Part instance) => <String, dynamic>{
  if (instance.text case final value?) 'text': value,
  if (instance.inlineData case final value?) 'inlineData': value,
};

Blob _$BlobFromJson(Map<String, dynamic> json) =>
    Blob(mimeType: json['mimeType'] as String, data: json['data'] as String);

Map<String, dynamic> _$BlobToJson(Blob instance) => <String, dynamic>{
  'mimeType': instance.mimeType,
  'data': instance.data,
};

Content _$ContentFromJson(Map<String, dynamic> json) => Content(
  parts: (json['parts'] as List<dynamic>?)
      ?.map((e) => Part.fromJson(e as Map<String, dynamic>))
      .toList(),
  role: json['role'] as String?,
);

Map<String, dynamic> _$ContentToJson(Content instance) => <String, dynamic>{
  if (instance.parts case final value?) 'parts': value,
  if (instance.role case final value?) 'role': value,
};

GenerationConfig _$GenerationConfigFromJson(Map<String, dynamic> json) =>
    GenerationConfig(
      temperature: (json['temperature'] as num?)?.toDouble(),
      topK: (json['top_k'] as num?)?.toInt(),
      topP: (json['top_p'] as num?)?.toDouble(),
      maxOutputTokens: (json['max_output_tokens'] as num?)?.toInt(),
      responseModalities: (json['response_modalities'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$ModalityEnumMap, e))
          .toList(),
    );

Map<String, dynamic> _$GenerationConfigToJson(
  GenerationConfig instance,
) => <String, dynamic>{
  if (instance.temperature case final value?) 'temperature': value,
  if (instance.topK case final value?) 'top_k': value,
  if (instance.topP case final value?) 'top_p': value,
  if (instance.maxOutputTokens case final value?) 'max_output_tokens': value,
  if (instance.responseModalities?.map((e) => _$ModalityEnumMap[e]!).toList()
      case final value?)
    'response_modalities': value,
};

const _$ModalityEnumMap = {
  Modality.TEXT: 'TEXT',
  Modality.IMAGE: 'IMAGE',
  Modality.AUDIO: 'AUDIO',
};

LiveClientSetup _$LiveClientSetupFromJson(Map<String, dynamic> json) =>
    LiveClientSetup(
      model: json['model'] as String,
      generationConfig: json['generation_config'] == null
          ? null
          : GenerationConfig.fromJson(
              json['generation_config'] as Map<String, dynamic>,
            ),
      systemInstruction: json['system_instruction'] == null
          ? null
          : Content.fromJson(
              json['system_instruction'] as Map<String, dynamic>,
            ),
      tools: (json['tools'] as List<dynamic>?)
          ?.map((e) => Tool.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LiveClientSetupToJson(
  LiveClientSetup instance,
) => <String, dynamic>{
  'model': instance.model,
  if (instance.generationConfig case final value?) 'generation_config': value,
  if (instance.systemInstruction case final value?) 'system_instruction': value,
  if (instance.tools case final value?) 'tools': value,
};

LiveClientContent _$LiveClientContentFromJson(Map<String, dynamic> json) =>
    LiveClientContent(
      turns: (json['turns'] as List<dynamic>?)
          ?.map((e) => Content.fromJson(e as Map<String, dynamic>))
          .toList(),
      turnComplete: json['turn_complete'] as bool?,
    );

Map<String, dynamic> _$LiveClientContentToJson(LiveClientContent instance) =>
    <String, dynamic>{
      if (instance.turns case final value?) 'turns': value,
      if (instance.turnComplete case final value?) 'turn_complete': value,
    };

LiveClientRealtimeInput _$LiveClientRealtimeInputFromJson(
  Map<String, dynamic> json,
) => LiveClientRealtimeInput(
  audio: json['audio'] == null
      ? null
      : Blob.fromJson(json['audio'] as Map<String, dynamic>),
  video: json['video'] == null
      ? null
      : Blob.fromJson(json['video'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LiveClientRealtimeInputToJson(
  LiveClientRealtimeInput instance,
) => <String, dynamic>{
  if (instance.audio case final value?) 'audio': value,
  if (instance.video case final value?) 'video': value,
};

LiveClientMessage _$LiveClientMessageFromJson(Map<String, dynamic> json) =>
    LiveClientMessage(
      setup: json['setup'] == null
          ? null
          : LiveClientSetup.fromJson(json['setup'] as Map<String, dynamic>),
      clientContent: json['clientContent'] == null
          ? null
          : LiveClientContent.fromJson(
              json['clientContent'] as Map<String, dynamic>,
            ),
      realtimeInput: json['realtimeInput'] == null
          ? null
          : LiveClientRealtimeInput.fromJson(
              json['realtimeInput'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$LiveClientMessageToJson(LiveClientMessage instance) =>
    <String, dynamic>{
      if (instance.setup case final value?) 'setup': value,
      if (instance.clientContent case final value?) 'clientContent': value,
      if (instance.realtimeInput case final value?) 'realtimeInput': value,
    };

LiveServerSetupComplete _$LiveServerSetupCompleteFromJson(
  Map<String, dynamic> json,
) => LiveServerSetupComplete();

Transcription _$TranscriptionFromJson(Map<String, dynamic> json) =>
    Transcription(
      text: json['text'] as String?,
      finished: json['finished'] as bool?,
    );

LiveServerContent _$LiveServerContentFromJson(Map<String, dynamic> json) =>
    LiveServerContent(
      modelTurn: json['modelTurn'] == null
          ? null
          : Content.fromJson(json['modelTurn'] as Map<String, dynamic>),
      turnComplete: json['turnComplete'] as bool?,
      inputTranscription: json['inputTranscription'] == null
          ? null
          : Transcription.fromJson(
              json['inputTranscription'] as Map<String, dynamic>,
            ),
      outputTranscription: json['outputTranscription'] == null
          ? null
          : Transcription.fromJson(
              json['outputTranscription'] as Map<String, dynamic>,
            ),
      generationComplete: json['generationComplete'] as bool?,
    );

LiveServerMessage _$LiveServerMessageFromJson(Map<String, dynamic> json) =>
    LiveServerMessage(
      setupComplete: json['setupComplete'] == null
          ? null
          : LiveServerSetupComplete.fromJson(
              json['setupComplete'] as Map<String, dynamic>,
            ),
      serverContent: json['serverContent'] == null
          ? null
          : LiveServerContent.fromJson(
              json['serverContent'] as Map<String, dynamic>,
            ),
      usageMetadata: json['usageMetadata'] == null
          ? null
          : UsageMetadata.fromJson(
              json['usageMetadata'] as Map<String, dynamic>,
            ),
    );

UsageMetadata _$UsageMetadataFromJson(Map<String, dynamic> json) =>
    UsageMetadata(
      promptTokenCount: (json['promptTokenCount'] as num).toInt(),
      responseTokenCount: (json['responseTokenCount'] as num).toInt(),
      totalTokenCount: (json['totalTokenCount'] as num).toInt(),
    );

Tool _$ToolFromJson(Map<String, dynamic> json) => Tool();

Map<String, dynamic> _$ToolToJson(Tool instance) => <String, dynamic>{};
