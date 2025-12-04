import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:twyns/modules/onboarding/widgets/pill_highlighted_transcription.dart';
import 'package:twyns/modules/onboarding/widgets/step_navigation.dart';

import '../../controllers/audio_visualizer_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/step_audio_controller.dart';
import '../../controllers/voice_clone_controller.dart';
import '../../utils/fonts/satoshi_font.dart';
import '../../utils/shader/visualizer_painter.dart';
import 'models/transcription_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final OnboardingController visualizerController;
  late final StepAudioController stepController;

  @override
  void initState() {
    super.initState();
    visualizerController = Get.put(OnboardingController());
    stepController = Get.put(StepAudioController());

    // Connect step audio amplitude to visualizer
    stepController.setAmplitudeCallback((amplitude) {
      visualizerController.onStepAudioAmplitude(amplitude);
    });

    // Auto-play first step audio when both controllers are ready
    _setupAutoPlay();
  }

  void _setupAutoPlay() {
    // Wait for both controllers to be ready
    ever(visualizerController.isInitialized, (initialized) {
      if (initialized && stepController.isAudioLoaded.value) {
        _playFirstStep();
      }
    });

    ever(stepController.isAudioLoaded, (loaded) {
      if (loaded &&
          visualizerController.isInitialized.value &&
          stepController.currentStepIndex.value == 0 &&
          !stepController.isPlaying.value) {
        _playFirstStep();
      }
    });
  }

  void _playFirstStep() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!stepController.isPlaying.value) {
        stepController.playCurrentStep();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!visualizerController.isInitialized.value) {
        return _buildLoadingState();
      }

      return Scaffold(
        backgroundColor: Colors.grey[700],
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            visualizerController.updateRenderSize(size);

            return Stack(
              children: [
                _buildVisualizer(),
                _buildSettingsButton(visualizerController),
                Obx(() {
                  if (visualizerController.showSettings.value) {
                    return _buildSettingsPanel(context, visualizerController);
                  }
                  return const SizedBox.shrink();
                }),
                Obx(() {
                  if (visualizerController.isRecording.value) {
                    return _buildRecordingIndicator();
                  }
                  return const SizedBox.shrink();
                }),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildVisualizer() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Shader visualizer
        GetBuilder<OnboardingController>(
          builder: (_) => CustomPaint(
            isComplex: true,
            painter: AudioVisualizerPainter(
              program: visualizerController.mainProgram!,
              time: visualizerController.elapsed.inMilliseconds / 1000.0,
              bufferAImage: visualizerController.bufferAImage,
              warpStrength: visualizerController.warpStrength.value,
              colorIntensity: visualizerController.colorIntensity.value,
              glowFalloff: visualizerController.glowFalloff.value,
              smoothness: visualizerController.smoothness.value,
            ),
            size: Size.infinite,
          ),
        ),

        // Bottom content panel
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.compose(
              outer: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              inner: ColorFilter.matrix(_darkMatrix),
            ),
            child: Container(
              height: Get.height * 0.52,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.9)),
              child: _buildStepContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    return Obx(() {
      final step = stepController.currentStep;
      final isForward = stepController.isNavigatingForward.value;
      final stepIndex = stepController.currentStepIndex.value;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 20),
            child: const MinimalStepNavigation(),
          ),
          Expanded(
            child: PageTransitionSwitcher(
              duration: const Duration(milliseconds: 400),
              reverse: !isForward,
              transitionBuilder: (child, primary, secondary) {
                return SharedAxisTransition(
                  animation: primary,
                  secondaryAnimation: secondary,
                  transitionType: SharedAxisTransitionType.vertical,
                  fillColor: Colors.transparent,
                  child: child,
                );
              },
              child: _StepContentWidget(key: ValueKey(stepIndex), step: step),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSettingsButton(OnboardingController controller) {
    return Positioned(
      top: 90,
      right: 16,
      child: IconButton(
        onPressed: controller.toggleSettings,
        icon: Icon(
          controller.showSettings.value ? Icons.close : Icons.settings,
          color: Colors.white.withOpacity(0.7),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(
    BuildContext context,
    OnboardingController controller,
  ) {
    return Positioned(
      top: 130,
      left: 20,
      right: 20,
      child: Container(
        height: Get.height * 0.3,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildSectionTitle('VISUAL EFFECTS', Colors.blue.shade300),
              const SizedBox(height: 15),
              _buildSlider(
                'Warp Strength',
                controller.warpStrength.value,
                0.1,
                1.0,
                90,
                Colors.purple,
                (value) => controller.warpStrength.value = value,
                '${(controller.warpStrength.value * 100).toInt()}%',
              ),
              _buildSlider(
                'Color Intensity',
                controller.colorIntensity.value,
                1.0,
                10.0,
                90,
                Colors.orange,
                (value) => controller.colorIntensity.value = value,
                '${controller.colorIntensity.value.toStringAsFixed(1)}x',
              ),
              _buildSlider(
                'Glow Falloff',
                controller.glowFalloff.value,
                1.0,
                20.0,
                95,
                Colors.cyan,
                (value) => controller.glowFalloff.value = value,
                controller.glowFalloff.value.toStringAsFixed(1),
              ),
              _buildSlider(
                'Smoothness',
                controller.smoothness.value,
                0.1,
                2.0,
                95,
                Colors.green,
                (value) => controller.smoothness.value = value,
                controller.smoothness.value.toStringAsFixed(1),
              ),
              _buildSlider(
                'Audio Response',
                controller.audioResponse.value,
                0.1,
                1.0,
                90,
                Colors.yellow,
                (value) => controller.audioResponse.value = value,
                '${(controller.audioResponse.value * 100).toInt()}%',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('AUDIO PROCESSING', Colors.green.shade300),
              const SizedBox(height: 15),
              _buildSlider(
                'Noise Threshold',
                controller.noiseThreshold.value,
                0.1,
                0.8,
                70,
                Colors.blue,
                (value) => controller.noiseThreshold.value = value,
                '${(controller.noiseThreshold.value * 100).toInt()}% - ${controller.getSensitivityLabel(controller.noiseThreshold.value)}',
                valueColor: controller.getSensitivityColor(
                  controller.noiseThreshold.value,
                ),
              ),
              _buildSlider(
                'Audio Boost',
                controller.audioBoost.value,
                0.5,
                3.0,
                25,
                Colors.green,
                (value) => controller.audioBoost.value = value,
                '${controller.audioBoost.value.toStringAsFixed(1)}x',
              ),
              _buildSlider(
                'Smoothing',
                controller.smoothingFactor.value,
                0.1,
                0.9,
                80,
                Colors.orange,
                (value) => controller.smoothingFactor.value = value,
                '${(controller.smoothingFactor.value * 100).toInt()}% - ${controller.smoothingFactor.value > 0.7
                    ? 'Very Smooth'
                    : controller.smoothingFactor.value > 0.4
                    ? 'Balanced'
                    : 'Responsive'}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    int divisions,
    Color activeColor,
    Function(double) onChanged,
    String displayValue, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: activeColor,
          inactiveColor: Colors.white.withOpacity(0.3),
          onChanged: onChanged,
        ),
        Text(
          'Current: $displayValue',
          style: TextStyle(
            color: valueColor ?? activeColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildRecordingIndicator() {
    return Positioned(
      top: 48,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.red, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'LISTENING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const List<double> _darkMatrix = <double>[
    1.385, -0.56, -0.112, 0.0, 0.3, //
    -0.315, 1.14, -0.112, 0.0, 0.3, //
    -0.315, -0.56, 1.588, 0.0, 0.3, //
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];
}

class _StepContentWidget extends StatelessWidget {
  final OnboardingStep step;

  const _StepContentWidget({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PillHighlightedTranscription(
              segments: step.segments,
              pillColor: const Color(0xFF343434),
              glowColor: const Color(0x3F343434),
              pillBorderRadius: 12,
              pillPadding: EdgeInsets.symmetric(horizontal: 6.5, vertical: 3),
              baseStyle: Satoshi.font(
                color: Colors.grey.withOpacity(0.4),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              activeStyle: Satoshi.font(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              completedStyle: Satoshi.font(
                color: Colors.grey.withOpacity(0.9),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 32),

            // Input field based on step type - with animation
            _AnimatedStepInput(step: step),
          ],
        ),
      ),
    );
  }
}

/// Wrapper that animates the input field appearance after audio completes
class _AnimatedStepInput extends StatelessWidget {
  final OnboardingStep step;

  const _AnimatedStepInput({required this.step});

  @override
  Widget build(BuildContext context) {
    final stepController = Get.find<StepAudioController>();

    // Directly show avatar picker (no animations)
    if (step.questionType == 'avatar-picker') {
      return _buildInputForStep(step);
    }

    if (step.questionType == 'audio-clone') {
      return VoiceCloneWidget();
    }

    return Obx(() {
      final isAudioCompleted = stepController.isAudioCompleted.value;

      return AnimatedOpacity(
        opacity: isAudioCompleted ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        child: AnimatedSlide(
          offset: isAudioCompleted ? Offset.zero : const Offset(0, 0.1),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _buildInputForStep(step),
        ),
      );
    });
  }

  Widget _buildInputForStep(OnboardingStep step) {
    switch (step.questionType) {
      case 'name':
        return _NameInputField();
      case 'dob':
        return DOBSelectorField(
          initialDate: DateTime(2004, 7, 27),
          onDateSelected: (date) {
            print("Selected DOB: $date");
          },
        );
      case 'avatar-picker':
        return _AvatarPicker(); // Always visible
      case 'audio-clone':
        return VoiceCloneWidget(); // Always visible
      default:
        return const SizedBox.shrink();
    }
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final stepController = Get.find<StepAudioController>();

    final avatars = List.generate(
      20,
      (i) => "assets/lottie/avatars/${i + 1}.json",
    );

    return Column(
      children: [
        AnimationLimiter(
          child: SizedBox(
            height: 0.3.sh,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: avatars.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final file = avatars[index];

                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    columnCount: 3,
                    duration: const Duration(milliseconds: 450),
                    child: ScaleAnimation(
                      curve: Curves.easeOutBack,
                      child: FadeInAnimation(
                        child: Obx(() {
                          final isSelected =
                              authController.selectedAvatarIndex.value == index;

                          return GestureDetector(
                            onTap: () {
                              authController.selectedAvatarIndex.value = index;
                              authController.avatarPath.value = file;
                              debugPrint(
                                "✅ Selected Avatar: $file (Index: $index)",
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade900,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: isSelected ? 3 : 0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.3),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Lottie.asset(file, fit: BoxFit.contain),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        7.verticalSpace,

        // Next Button (sticky at bottom)
        Obx(() {
          final hasSelection = authController.selectedAvatarIndex.value != null;

          return AnimatedOpacity(
            opacity: hasSelection ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: hasSelection
                  ? () async {
                      if (authController.validateAvatar()) {
                        await stepController.goToNextStep();
                      }
                    }
                  : null,
              child: Container(
                height: 54,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasSelection
                        ? [
                            Colors.blueAccent.shade200,
                            Colors.blueAccent.shade200,
                          ]
                        : [Colors.grey.shade700, Colors.grey.shade800],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: hasSelection
                      ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Next',
                    style: Satoshi.font(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class DOBSelectorField extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime>? onDateSelected;

  const DOBSelectorField({Key? key, this.initialDate, this.onDateSelected})
    : super(key: key);

  @override
  State<DOBSelectorField> createState() => _DOBSelectorFieldState();
}

class _DOBSelectorFieldState extends State<DOBSelectorField> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    selectedDate = authController.dob.value ?? DateTime(2000, 1, 1);
  }

  void _showDatePicker() {
    final authController = Get.find<AuthController>();
    final stepController = Get.find<StepAudioController>();

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 225.h,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.grey.shade400.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        initialDateTime: selectedDate,
                        mode: CupertinoDatePickerMode.date,
                        maximumDate: DateTime.now(),
                        onDateTimeChanged: (date) {
                          setState(() {
                            selectedDate = date;
                          });
                          authController.dob.value = date;
                          if (widget.onDateSelected != null) {
                            widget.onDateSelected!(date);
                          }
                        },
                      ),
                    ),
                  ),
                  Material(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                    child: InkWell(
                      splashFactory: InkRipple.splashFactory,
                      splashColor: Colors.blueAccent.shade100.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: () async {
                        Navigator.of(context).pop();

                        // Validate and go to next step
                        if (authController.validateDOB()) {
                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );
                          await stepController.goToNextStep();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        child: Text(
                          "Done",
                          style: Satoshi.regular(
                            color: Colors.blueAccent.shade200,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  5.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateContainer(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade900.withOpacity(0.6),
      ),
      child: Text(
        text,
        style: Satoshi.font(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String dd = selectedDate.day.toString().padLeft(2, '0');
    String mm = selectedDate.month.toString().padLeft(2, '0');
    String yyyy = selectedDate.year.toString();

    return GestureDetector(
      onTap: _showDatePicker,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade800.withOpacity(0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDateContainer(dd),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '-',
                  style: Satoshi.font(
                    color: Colors.grey.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildDateContainer(mm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  '-',
                  style: Satoshi.font(
                    color: Colors.grey.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildDateContainer(yyyy),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameInputField extends StatefulWidget {
  @override
  State<_NameInputField> createState() => _NameInputFieldState();
}

class _NameInputFieldState extends State<_NameInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);

    // Load existing name if any
    final authController = Get.find<AuthController>();
    if (authController.name.value.isNotEmpty) {
      _textController.text = authController.name.value;
    }

    // Listen to text changes
    _textController.addListener(() {
      authController.name.value = _textController.text;
    });
  }

  @override
  void dispose() {
    _cursorController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleDone() async {
    final authController = Get.find<AuthController>();
    final stepController = Get.find<StepAudioController>();

    // Validate name
    if (authController.validateName()) {
      _focusNode.unfocus();
      await Future.delayed(const Duration(milliseconds: 200));
      await stepController.goToNextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _cursorController,
              builder: (context, child) {
                return Opacity(
                  opacity: _cursorController.value,
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleDone(),
                style: Satoshi.font(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Say or type your name...',
                  hintStyle: Satoshi.font(
                    color: Colors.grey.withOpacity(0.5),
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
