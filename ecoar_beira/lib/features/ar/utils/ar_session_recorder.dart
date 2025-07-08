import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/utils/logger.dart';

class ARSessionRecorder {
  static ARSessionRecorder? _instance;
  static ARSessionRecorder get instance => _instance ??= ARSessionRecorder._();
  ARSessionRecorder._();

  bool _isRecording = false;
  DateTime? _recordingStartTime;
  final List<ARSessionEvent> _sessionEvents = [];

  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingStartTime != null 
      ? DateTime.now().difference(_recordingStartTime!)
      : Duration.zero;

  void startRecording(String sessionId) {
    if (_isRecording) return;

    AppLogger.i('Starting AR session recording: $sessionId');
    _isRecording = true;
    _recordingStartTime = DateTime.now();
    _sessionEvents.clear();

    _recordEvent(ARSessionEvent(
      type: ARSessionEventType.sessionStart,
      timestamp: DateTime.now(),
      data: {'sessionId': sessionId},
    ));
  }

  void stopRecording() {
    if (!_isRecording) return;

    AppLogger.i('Stopping AR session recording');
    _recordEvent(ARSessionEvent(
      type: ARSessionEventType.sessionEnd,
      timestamp: DateTime.now(),
      data: {'duration': recordingDuration.inSeconds},
    ));

    _isRecording = false;
    _recordingStartTime = null;
  }

  void recordObjectInteraction(String objectId, String interactionType) {
    if (!_isRecording) return;

    _recordEvent(ARSessionEvent(
      type: ARSessionEventType.objectInteraction,
      timestamp: DateTime.now(),
      data: {
        'objectId': objectId,
        'interactionType': interactionType,
      },
    ));
  }

  void recordPointsEarned(int points, String reason) {
    if (!_isRecording) return;

    _recordEvent(ARSessionEvent(
      type: ARSessionEventType.pointsEarned,
      timestamp: DateTime.now(),
      data: {
        'points': points,
        'reason': reason,
      },
    ));
  }

  void recordError(String error, String context) {
    if (!_isRecording) return;

    _recordEvent(ARSessionEvent(
      type: ARSessionEventType.error,
      timestamp: DateTime.now(),
      data: {
        'error': error,
        'context': context,
      },
    ));
  }

  void recordPerformanceMetric(String metric, double value) {
    if (!_isRecording) return;

    _recordEvent(ARSessionEvent(
      type: ARSessionEventType.performance,
      timestamp: DateTime.now(),
      data: {
        'metric': metric,
        'value': value,
      },
    ));
  }

  void _recordEvent(ARSessionEvent event) {
    _sessionEvents.add(event);
    AppLogger.d('AR session event recorded: ${event.type}');
  }

  Future<String?> saveSession() async {
    if (_sessionEvents.isEmpty) return null;

    try {
      final sessionData = ARSessionData(
        events: List.from(_sessionEvents),
        totalDuration: recordingDuration,
        startTime: _recordingStartTime!,
        endTime: DateTime.now(),
      );

      final documentsDir = await getApplicationDocumentsDirectory();
      final sessionsDir = Directory(path.join(documentsDir.path, 'ar_sessions'));
      if (!await sessionsDir.exists()) {
        await sessionsDir.create(recursive: true);
      }

      final fileName = 'ar_session_${_recordingStartTime!.millisecondsSinceEpoch}.json';
      final filePath = path.join(sessionsDir.path, fileName);
      final file = File(filePath);

      await file.writeAsString(sessionData.toJson());
      AppLogger.i('AR session saved: $filePath');

      return filePath;
    } catch (e, stackTrace) {
      AppLogger.e('Error saving AR session', e, stackTrace);
      return null;
    }
  }

  List<ARSessionEvent> getSessionEvents() {
    return List.from(_sessionEvents);
  }

  void clearSession() {
    _sessionEvents.clear();
    _isRecording = false;
    _recordingStartTime = null;
  }
}

class ARSessionEvent {
  final ARSessionEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  ARSessionEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

enum ARSessionEventType {
  sessionStart,
  sessionEnd,
  objectInteraction,
  pointsEarned,
  error,
  performance,
  sceneLoad,
  userAction,
}

class ARSessionData {
  final List<ARSessionEvent> events;
  final Duration totalDuration;
  final DateTime startTime;
  final DateTime endTime;

  ARSessionData({
    required this.events,
    required this.totalDuration,
    required this.startTime,
    required this.endTime,
  });

  String toJson() {
    return '''
{
  "startTime": "${startTime.toIso8601String()}",
  "endTime": "${endTime.toIso8601String()}",
  "totalDuration": ${totalDuration.inSeconds},
  "events": [
    ${events.map((e) => e.toJson().toString()).join(',\n    ')}
  ]
}''';
  }
}
