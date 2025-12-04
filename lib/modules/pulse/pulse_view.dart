import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:blobs/blobs.dart';
import 'package:executorch_bridge_flutter/executorch_bridge_flutter.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:twyns/modules/pulse/pulse_engine.dart';

import '../../utils/custom_tap.dart';
import '../../utils/fonts/satoshi_font.dart';
import '../home/chat_controller.dart';
import 'models/pulse_message.dart';
import 'pulse_audio_controller.dart';
import 'pulse_controller.dart';

class PulseView extends StatelessWidget {
  const PulseView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PulseModeController());
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/chat-bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Blob 1
              Positioned(
                bottom: -60,
                left: -150,
                child: Blob.animatedRandom(
                  size: 0.8.sh,
                  loop: true,
                  edgesCount: 5,
                  minGrowth: 2,
                  duration: Duration(seconds: 4),
                  styles: BlobStyles(color: Color(0xFF0D102F)),
                ),
              ),
              // Blob 2
              Positioned(
                left: -100,
                child: Blob.animatedRandom(
                  size: 0.6.sh,
                  loop: true,
                  edgesCount: 5,
                  minGrowth: 4,
                  duration: Duration(milliseconds: 2000),
                  styles: BlobStyles(color: Color(0xFF6721F3)),
                ),
              ),
              // Blob 3
              Blob.animatedRandom(
                size: 0.6.sh,
                loop: true,
                edgesCount: 9,
                minGrowth: 4,
                duration: Duration(milliseconds: 4000),
                styles: BlobStyles(color: Color(0xFF638BBD)),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 180, sigmaY: 180),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Image.asset(
                'assets/images/noise-texture.png',
                width: 1.sw,
                height: 1.sh,
                fit: BoxFit.fill,
                repeat: ImageRepeat.repeat,
              ),
              Container(
                child: Center(
                  child: Obx(() {
                    return PageTransitionSwitcher(
                      duration: const Duration(milliseconds: 600),
                      reverse: false,
                      transitionBuilder:
                          (
                            Widget child,
                            Animation<double> primaryAnimation,
                            Animation<double> secondaryAnimation,
                          ) {
                            return SharedAxisTransition(
                              animation: primaryAnimation,
                              secondaryAnimation: secondaryAnimation,
                              transitionType:
                                  SharedAxisTransitionType.horizontal,
                              child: child,
                              fillColor: Colors.transparent,
                            );
                          },
                      child: _buildPage(controller.currentPageIndex.value),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _BuildPage1(key: ValueKey(0));
      case 1:
        return PulseLoadingPage(key: ValueKey(1));
      case 2:
        return PulseReadyPage(key: ValueKey(2));
      default:
        return _BuildPage1(key: ValueKey(0));
    }
  }
}

class PulseLoadingPage extends StatelessWidget {
  const PulseLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PulseModeController>();
    return Center(
      child: Obx(() {
        return PageTransitionSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder:
              (
                Widget child,
                Animation<double> primaryAnimation,
                Animation<double> secondaryAnimation,
              ) {
                return SharedAxisTransition(
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.vertical,
                  fillColor: Colors.transparent,
                  child: child,
                );
              },
          child: Text(
            controller.currentText.value,
            key: ValueKey(controller.currentText.value),
            textAlign: TextAlign.center,
            style: Satoshi.font(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }
}

class _BuildPage1 extends StatelessWidget {
  const _BuildPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Welcome to Pulse Mode',
                textAlign: TextAlign.center,
                style: Satoshi.font(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        4.verticalSpace,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Step into a smarter, faster conversation with your AI — it\'s all in your voice.',
                  textAlign: TextAlign.center,
                  style: Satoshi.font(
                    color: Colors.grey.shade300,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        10.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [_StartButton()],
        ),
      ],
    );
  }
}

class PulseReadyPage extends StatelessWidget {
  const PulseReadyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = Get.put(PulseAudioController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(() {
        if (!audioController.isInitialized.value) {
          return Center(child: CircularProgressIndicator(color: Colors.white));
        }

        return PulseChatView();
      }),
    );
  }
}

class PulseChatView extends StatelessWidget {
  const PulseChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.put(PulseChatController());
    final audioController = Get.find<PulseAudioController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Chat messages with fading edges
          Positioned.fill(
            bottom: 140.h,
            child: Obx(() {
              final messages = chatController.messages;

              if (messages.isEmpty) {
                return _EmptyPulseState();
              }

              return FadingEdgeScrollView.fromScrollView(
                gradientFractionOnStart: 0.1,
                gradientFractionOnEnd: 0.1,
                child: ListView.builder(
                  controller: chatController.scrollController,
                  reverse: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 20.h,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageBubble(
                      key: ValueKey(message.id),
                      message: message,
                    );
                  },
                ),
              );
            }),
          ),

          // Microphone button at bottom
          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: Center(
              child: _PulseMicButton(
                audioController: audioController,
                chatController: chatController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final PulseMessage message;

  const _MessageBubble({super.key, required this.message});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
          fillColor: Colors.transparent,
        );
      },
      child: FadeTransition(
        key: ValueKey(widget.message.id),
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: widget.message.isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Align(
              alignment: widget.message.isUser
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: widget.message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(maxWidth: 0.75.sw),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: widget.message.isUser
                          ? LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: [0.0, 0.59, 0.81, 1.0],
                              colors: [
                                Color(0x6E000000),
                                Color(0x40283054),
                                Color(0x59000000),
                                Color(0x2F442D41),
                              ],
                            )
                          : LinearGradient(
                              colors: [Colors.transparent, Colors.transparent],
                            ),
                      border: Border.all(
                        color: Colors.grey.shade700.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18.r),
                        topRight: Radius.circular(18.r),
                        bottomLeft: widget.message.isUser
                            ? Radius.circular(18.r)
                            : Radius.circular(4.r),
                        bottomRight: widget.message.isUser
                            ? Radius.circular(4.r)
                            : Radius.circular(18.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    // FIXED: Wrap in Obx to reactively update streaming messages
                    child: Obx(() {
                      // Find the current message from the controller to get latest updates
                      final chatController = Get.find<PulseChatController>();
                      final currentMessage =
                          chatController.messages.firstWhereOrNull(
                            (m) => m.id == widget.message.id,
                          ) ??
                          widget.message;

                      return currentMessage.isStreaming
                          ? _StreamingText(text: currentMessage.text)
                          : Text(
                              currentMessage.text,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            );
                    }),
                  ),

                  // Action buttons for AI messages
                  // FIXED: Also wrap this in Obx to react to isStreaming changes
                  Obx(() {
                    final chatController = Get.find<PulseChatController>();
                    final currentMessage =
                        chatController.messages.firstWhereOrNull(
                          (m) => m.id == widget.message.id,
                        ) ??
                        widget.message;

                    if (!currentMessage.isUser && !currentMessage.isStreaming) {
                      return Padding(
                        padding: EdgeInsets.only(top: 8.h, left: 8.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionButton(icon: LucideIcons.thumbsUp),
                            SizedBox(width: 10.w),
                            _ActionButton(icon: LucideIcons.thumbsDown),
                            SizedBox(width: 10.w),
                            _ActionButton(icon: LucideIcons.copy),
                            SizedBox(width: 10.w),
                            _ActionButton(icon: LucideIcons.share2),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StreamingText extends StatefulWidget {
  final String text;

  const _StreamingText({required this.text});

  @override
  State<_StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<_StreamingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 530),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              widget.text.isEmpty ? 'Thinking...' : widget.text,
              key: ValueKey(widget.text),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;

  const _ActionButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        // Handle action
      },
      borderRadius: BorderRadius.circular(20.r),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Icon(icon, size: 15.sp, color: Colors.grey.shade400),
      ),
    );
  }
}

class _PulseMicButton extends StatelessWidget {
  final PulseAudioController audioController;
  final PulseChatController chatController;

  const _PulseMicButton({
    required this.audioController,
    required this.chatController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isRecording = audioController.isRecording.value;

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) async {
          HapticFeedback.selectionClick();
          await audioController.startRecording();
        },
        onTapUp: (_) async {
          HapticFeedback.lightImpact();

          // Get the final text from stopRecording
          final finalText = await audioController.stopRecording();

          debugPrint('🎯 Got final text from stop: "$finalText"');

          // Confirm the message
          if (finalText.trim().isNotEmpty) {
            chatController.confirmMessage(finalText);

            // Clear audio controller text AFTER confirming
            audioController.transcribedText.value = '';
            audioController.partialText.value = '';

            // Generate AI response
            await _generateAIResponse(finalText);
          } else {
            debugPrint('⚠️ Final text was empty, canceling');
            chatController.cancelTemporaryMessage();
          }
        },
        onTapCancel: () async {
          HapticFeedback.lightImpact();
          await audioController.stopRecording();
          chatController.cancelTemporaryMessage();
          audioController.transcribedText.value = '';
          audioController.partialText.value = '';
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(isRecording ? 24.w : 20.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording
                ? Colors.red.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            border: Border.all(
              color: isRecording ? Colors.red : Colors.greenAccent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (isRecording ? Colors.red : Colors.greenAccent)
                    .withOpacity(0.5),
                blurRadius: isRecording ? 30 : 20,
                spreadRadius: isRecording ? 5 : 2,
              ),
            ],
          ),
          child: Icon(
            isRecording ? LucideIcons.micOff : LucideIcons.mic,
            color: isRecording ? Colors.red : Colors.greenAccent,
            size: 50.sp,
          ),
        ),
      );
    });
  }

  Future<void> _generateAIResponse(String prompt) async {
    try {
      final chatCtrl = Get.find<ChatController>();

      if (!chatCtrl.isModelLoaded.value) {
        chatController.startAIResponse();
        chatController.updateAIResponse(
          'Model is not loaded. Please load the model first.',
        );
        chatController.finishAIResponse();
        return;
      }

      debugPrint('🤖 Starting AI generation for: "$prompt"');
      chatController.startAIResponse();

      final stream = chatCtrl.executorch.generateText(
        prompt.trimLeft(),
        config: GenerationConfig.llama(
          sequenceLength: 128,
          maximumNewTokens: 512,
        ),
      );

      var generatedText = '';
      bool firstToken = true;
      int tokenCount = 0;

      await for (final token in stream) {
        tokenCount++;

        // Add token to generated text
        if (firstToken) {
          generatedText = token.text.trimLeft();
          firstToken = false;
        } else {
          generatedText += token.text;
        }

        debugPrint(
          '📝 Token #$tokenCount: "${token.text}" | Total: "$generatedText"',
        );

        // Update the UI with accumulated text
        chatController.updateAIResponse(generatedText);
      }

      debugPrint('✅ Generation complete. Final text: "$generatedText"');
    } catch (e, stack) {
      debugPrint('❌ AI Generation error: $e');
      debugPrintStack(stackTrace: stack);
      chatController.updateAIResponse('Sorry, I encountered an error: $e');
    } finally {
      chatController.finishAIResponse();
    }
  }
}

class _EmptyPulseState extends StatelessWidget {
  const _EmptyPulseState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.mic,
            size: 60.sp,
            color: Colors.white.withOpacity(0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            'Tap and hold to speak',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your conversation will appear here',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// Update PulseAudioController to work with chat
class PulseAudioControllerExtension {
  static void setupChatIntegration(
    PulseAudioController audioController,
    PulseChatController chatController,
  ) {
    // Listen to transcribed text and update chat in real-time
    ever(audioController.partialText, (text) {
      if (audioController.isRecording.value && text.isNotEmpty) {
        chatController.addTemporaryMessage(text);
      }
    });

    ever(audioController.transcribedText, (text) {
      if (audioController.isRecording.value && text.isNotEmpty) {
        chatController.addTemporaryMessage(text);
      }
    });
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PulseModeController>();
    return CustomTap(
      onTap: () {
        HapticFeedback.heavyImpact();
        controller.startPulseMode();
      },
      child: Container(
        width: 120.w,
        height: 40.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(32.r)),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            image: DecorationImage(
              image: AssetImage('assets/images/splash-bg.png'),
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeat,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32.r),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Blob 1
                Positioned(
                  top: -40,
                  child: Blob.animatedRandom(
                    size: 190,
                    loop: true,
                    edgesCount: 5,
                    minGrowth: 2,
                    duration: Duration(milliseconds: 1000),
                    styles: BlobStyles(color: Color(0xFFCF7987)),
                  ),
                ),
                // Blob 2
                Blob.animatedRandom(
                  size: 130,
                  loop: true,
                  edgesCount: 5,
                  minGrowth: 4,
                  duration: Duration(milliseconds: 1000),
                  styles: BlobStyles(color: Colors.blue),
                ),
                // Blob 3
                Blob.animatedRandom(
                  size: 150,
                  loop: true,
                  edgesCount: 9,
                  minGrowth: 4,
                  duration: Duration(milliseconds: 1000),
                  styles: BlobStyles(color: Color(0xFFC934A3)),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start',
                        style: Satoshi.font(
                          color: Colors.grey.shade300,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      4.horizontalSpace,
                      Icon(
                        LucideIcons.arrowRight,
                        size: 16.sp,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
