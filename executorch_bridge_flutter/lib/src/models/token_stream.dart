/// Data emitted during token streaming
class TokenStreamData {
  /// The generated token text
  final String text;

  /// Total number of tokens generated so far
  final int tokenCount;

  /// Current generation speed in tokens per second
  final double tokensPerSecond;

  TokenStreamData({
    required this.text,
    required this.tokenCount,
    required this.tokensPerSecond,
  });

  @override
  String toString() {
    return 'TokenStreamData(text: "$text", tokens: $tokenCount, speed: ${tokensPerSecond.toStringAsFixed(1)} t/s)';
  }
}
