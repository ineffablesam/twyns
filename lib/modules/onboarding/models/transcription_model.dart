// lib/models/transcription_model.dart

class TranscriptionSegment {
  final int index;
  final Duration startTime;
  final Duration endTime;
  final String text;
  final bool isWordLevel; // true if this is a single word

  const TranscriptionSegment({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.text,
    this.isWordLevel = false,
  });

  bool isActiveAt(Duration position) {
    return position >= startTime && position < endTime;
  }

  double progressAt(Duration position) {
    if (position < startTime) return 0.0;
    if (position >= endTime) return 1.0;
    final total = endTime.inMilliseconds - startTime.inMilliseconds;
    final current = position.inMilliseconds - startTime.inMilliseconds;
    return (current / total).clamp(0.0, 1.0);
  }

  /// Split a segment into word-level segments with interpolated timing
  List<TranscriptionSegment> toWordSegments(int startIndex) {
    final words = text.split(RegExp(r'\s+'));
    if (words.isEmpty) return [this];

    final totalDuration = endTime.inMilliseconds - startTime.inMilliseconds;

    // Calculate approximate duration per word based on character count
    final totalChars = words.fold<int>(0, (sum, w) => sum + w.length);

    final result = <TranscriptionSegment>[];
    int currentMs = startTime.inMilliseconds;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      // Duration proportional to word length
      final wordDuration = ((word.length / totalChars) * totalDuration).round();

      result.add(
        TranscriptionSegment(
          index: startIndex + i,
          startTime: Duration(milliseconds: currentMs),
          endTime: Duration(milliseconds: currentMs + wordDuration),
          text: word,
          isWordLevel: true,
        ),
      );

      currentMs += wordDuration;
    }

    return result;
  }
}

/// Word-level segment with precise timing (for manual control)
class WordSegment {
  final int index;
  final int startMs;
  final int endMs;
  final String word;

  const WordSegment({
    required this.index,
    required this.startMs,
    required this.endMs,
    required this.word,
  });

  Duration get startTime => Duration(milliseconds: startMs);
  Duration get endTime => Duration(milliseconds: endMs);

  bool isActiveAt(Duration position) {
    return position.inMilliseconds >= startMs &&
        position.inMilliseconds < endMs;
  }

  TranscriptionSegment toSegment() {
    return TranscriptionSegment(
      index: index,
      startTime: startTime,
      endTime: endTime,
      text: word,
      isWordLevel: true,
    );
  }
}

class OnboardingStep {
  final int stepIndex;
  final String audioPath;
  final List<TranscriptionSegment> segments;
  final String? questionType;

  const OnboardingStep({
    required this.stepIndex,
    required this.audioPath,
    required this.segments,
    this.questionType,
  });

  String get fullText => segments.map((s) => s.text).join(' ');

  /// Get word-level segments for smooth word-by-word animation
  List<TranscriptionSegment> get wordSegments {
    final result = <TranscriptionSegment>[];
    int index = 0;
    for (final segment in segments) {
      final words = segment.toWordSegments(index);
      result.addAll(words);
      index += words.length;
    }
    return result;
  }

  /// Step 1 with precise word-level timing (milliseconds)
  static OnboardingStep step1() {
    return OnboardingStep(
      stepIndex: 0,
      audioPath: 'assets/audio/step-1.mp3',
      questionType: 'name',
      segments: _step1WordSegments(),
    );
  }

  /// Precise word-by-word timing for step 1
  static List<TranscriptionSegment> _step1WordSegments() {
    // Word-level timing based on your audio
    final wordTimings = <List<dynamic>>[
      // "Um, is someone there?"
      [0, 460, 'Um,'],
      [1040, 1280, 'is'],
      [1280, 1540, 'someone'],
      [1540, 1960, 'there?'],

      // "Oh, hi! I'm Twyn AI!"
      [2980, 3380, 'Oh,'],
      [3620, 3960, 'hi!'],
      [4420, 4700, "I'm"],
      [4700, 4940, 'Twyn'],
      [4940, 5240, 'AI!'],

      // "I think I was made for you."
      [6260, 6520, 'I'],
      [6520, 6740, 'think'],
      [6740, 6940, 'I'],
      [6940, 7080, 'was'],
      [7080, 7480, 'made'],
      [7480, 7780, 'for'],
      [7780, 8060, 'you.'],

      // "What's your name?"
      [8780, 9160, "What's"],
      [9160, 9320, 'your'],
      [9320, 9580, 'name?'],
    ];

    return wordTimings.asMap().entries.map((entry) {
      final i = entry.key;
      final timing = entry.value;
      return TranscriptionSegment(
        index: i,
        startTime: Duration(milliseconds: timing[0] as int),
        endTime: Duration(milliseconds: timing[1] as int),
        text: timing[2] as String,
        isWordLevel: true,
      );
    }).toList();
  }

  static OnboardingStep step2() {
    return OnboardingStep(
      stepIndex: 1,
      audioPath: 'assets/audio/step-2.mp3',
      questionType: 'dob',
      segments: _step2WordSegments(),
    );
  }

  static List<TranscriptionSegment> _step2WordSegments() {
    final wordTimings = <List<dynamic>>[
      // "Woohoo! Almost done!"
      [0, 680, 'Woohoo!'],
      [1000, 1200, 'Almost'],
      [1200, 1760, 'done!'],

      // "Can you share your date of birth with me?"
      [2540, 2860, 'Can'],
      [2860, 3020, 'you'],
      [3020, 3180, 'share'],
      [3180, 3340, 'your'],
      [3340, 3540, 'date'],
      [3540, 3700, 'of'],
      [3700, 3900, 'birth'],
      [3900, 4160, 'with'],
      [4160, 4360, 'me?'],

      // "I promise it'll be quick and easy."
      [4820, 5020, 'I'],
      [5020, 5320, 'promise'],
      [5320, 5600, "it'll"],
      [5600, 5720, 'be'],
      [5720, 6060, 'quick'],
      [6060, 6460, 'and'],
      [6460, 6840, 'easy.'],
    ];

    return wordTimings.asMap().entries.map((entry) {
      final i = entry.key;
      final timing = entry.value;
      return TranscriptionSegment(
        index: i,
        startTime: Duration(milliseconds: timing[0] as int),
        endTime: Duration(milliseconds: timing[1] as int),
        text: timing[2] as String,
        isWordLevel: true,
      );
    }).toList();
  }

  static OnboardingStep step3() {
    return OnboardingStep(
      stepIndex: 2,
      audioPath: 'assets/audio/step-3.mp3',
      questionType: 'avatar-picker',
      segments: _step3WordSegments(),
    );
  }

  static List<TranscriptionSegment> _step3WordSegments() {
    final wordTimings = <List<dynamic>>[
      [0, 320, 'Pick'],
      [320, 540, 'your'],
      [540, 1020, 'avatar.'],
      [1740, 2100, 'I'],
      [2100, 2460, "can't"],
      [2460, 2700, 'wait'],
      [2700, 2940, 'to'],
      [2940, 3120, 'see'],
      [3120, 3280, 'which'],
      [3280, 3480, 'one'],
      [3480, 3660, 'you'],
      [3660, 3960, 'choose.'],
    ];

    return wordTimings.asMap().entries.map((entry) {
      final i = entry.key;
      final timing = entry.value;
      return TranscriptionSegment(
        index: i,
        startTime: Duration(milliseconds: timing[0] as int),
        endTime: Duration(milliseconds: timing[1] as int),
        text: timing[2] as String,
        isWordLevel: true,
      );
    }).toList();
  }

  static OnboardingStep step4() {
    return OnboardingStep(
      stepIndex: 3,
      audioPath: 'assets/audio/step-4.mp3',
      questionType: 'audio-clone',
      segments: _step4WordSegments(),
    );
  }

  static List<TranscriptionSegment> _step4WordSegments() {
    final wordTimings = <List<dynamic>>[
      // Segment 1
      [0, 420, 'Alright,'],
      [760, 860, 'your'],
      [860, 1100, 'turn'],
      [1100, 1260, 'to'],
      [1260, 1520, 'speak.'],
      [2120, 2200, 'Give'],
      [2200, 2340, 'me'],
      [2340, 2460, 'a'],
      [2460, 2680, 'short'],
      [2680, 2940, 'voice'],
      [2940, 3400, 'sample.'],
      [3780, 3840, "I'm"],
      [3840, 4140, 'excited'],
      [4140, 4400, 'to'],
      [4400, 4580, 'hear'],
      [4580, 4860, 'it.'],

      // Segment 2
      [5500, 5800, 'You'],
      [5800, 5940, 'can'],
      [5940, 6080, 'say'],
      [6080, 6400, 'anything'],
      [6400, 6600, 'you'],
      [6600, 6900, 'like'],
      [6900, 7340, 'or'],
      [7340, 7620, 'just'],
      [7620, 7820, 'read'],
      [7820, 7980, 'the'],
      [7980, 8340, 'example'],
      [8340, 8720, 'below.'],
    ];

    return wordTimings.asMap().entries.map((entry) {
      final i = entry.key;
      final timing = entry.value;
      return TranscriptionSegment(
        index: i,
        startTime: Duration(milliseconds: timing[0] as int),
        endTime: Duration(milliseconds: timing[1] as int),
        text: timing[2] as String,
        isWordLevel: true,
      );
    }).toList();
  }

  static List<OnboardingStep> getAllSteps() {
    return [step1(), step2(), step3(), step4()];
  }
}
