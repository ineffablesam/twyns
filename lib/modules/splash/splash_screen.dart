// modules/splash/splash_screen.dart
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:twyns/modules/splash/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  SplashScreen({super.key});

  final SplashController controller = Get.put(SplashController());

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            /// Background image animation
            FadeInUpBig(
              duration: const Duration(seconds: 2),
              child: Image.asset(
                'assets/images/splash-bg.png',
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.cover,
              ),
            ),

            /// Center Lottie animation - animated position
            Obx(
              () => AnimatedPositioned(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                top: controller.isDownloading.value
                    ? MediaQuery.of(context).size.height * 0.25
                    : MediaQuery.of(context).size.height * 0.5 -
                          (MediaQuery.of(context).size.width / 2),
                left: 0,
                right: 0,
                child: Lottie.asset(
                  'assets/lottie/splash-logo.json',
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width,
                  filterQuality: FilterQuality.high,
                  frameRate: FrameRate.max,
                ),
              ),
            ),

            /// Download Progress Section
            Obx(() {
              if (!controller.isDownloading.value)
                return const SizedBox.shrink();

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),

                    /// File Counter
                    FadeIn(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        controller.currentFileIndex.value == 0 ? "1/2" : "2/2",
                        style: GoogleFonts.ibmPlexMono(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    /// Progress Bar with Gradient
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              /// Background bar
                              Container(
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),

                              /// Progress bar (animated gradient or infinite loading)
                              Obx(() {
                                bool isIndeterminate =
                                    controller.downloadStatus.value.contains(
                                      "Initialising",
                                    ) ||
                                    controller.downloadStatus.value.contains(
                                      "Retrying",
                                    );

                                if (isIndeterminate) {
                                  // Infinite animated gradient
                                  return _InfiniteProgressBar();
                                } else {
                                  // Normal progress
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 4.h,
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.8 *
                                        controller.downloadProgress.value,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF00D4FF),
                                          Color(0xFF0099FF),
                                          Color(0xFF0066FF),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(
                                            0xFF0099FF,
                                          ).withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          /// Status Text and Retry Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  controller.downloadStatus.value,
                                  style: GoogleFonts.ibmPlexMono(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (controller.hasError.value) ...[
                                SizedBox(width: 8.w),
                                GestureDetector(
                                  onTap: controller.retryDownload,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          color: Colors.white,
                                          size: 12.sp,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          "Retry",
                                          style: GoogleFonts.ibmPlexMono(
                                            color: Colors.white,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            /// Bottom Section - ARM Logo or Did You Know Facts
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Obx(() {
                if (!controller.isDownloading.value) {
                  // Initial ARM branding
                  return FadeInUp(
                    duration: const Duration(milliseconds: 1200),
                    delay: const Duration(milliseconds: 800),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "AI Accelerated by".toUpperCase(),
                            style: GoogleFonts.ibmPlexMono(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          VerticalDivider(
                            indent: 3,
                            endIndent: 3,
                            color: Colors.white,
                          ),
                          SvgPicture.asset(
                            'assets/icons/arm.svg',
                            height: 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Did You Know facts during download
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    child: Padding(
                      key: ValueKey(controller.currentFactIndex.value),
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          Text(
                            "Did you know?",
                            style: GoogleFonts.ibmPlexMono(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            controller.didYouKnowFacts[controller
                                .currentFactIndex
                                .value],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ibmPlexMono(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Infinite loading animation widget
class _InfiniteProgressBar extends StatefulWidget {
  @override
  State<_InfiniteProgressBar> createState() => _InfiniteProgressBarState();
}

class _InfiniteProgressBarState extends State<_InfiniteProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true); // This makes it bounce back and forth!

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Smooth physics-like animation
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 4.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xFF00D4FF),
                Color(0xFF0099FF),
                Color(0xFF0066FF),
                Colors.transparent,
              ],
              stops: [
                0.0,
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value,
                (_animation.value + 0.3).clamp(0.0, 1.0),
                1.0,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
            // boxShadow: [
            //   BoxShadow(
            //     color: Color(0xFF0099FF).withOpacity(0.5),
            //     blurRadius: 8,
            //     spreadRadius: 1,
            //   ),
            // ],
          ),
        );
      },
    );
  }
}
