class PulseMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;
  final bool isTemporary; // For STT while recording

  PulseMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
    this.isTemporary = false,
  });

  PulseMessage copyWith({String? text, bool? isStreaming, bool? isTemporary}) {
    return PulseMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }
}
