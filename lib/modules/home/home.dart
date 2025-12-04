import 'dart:ui';

import 'package:blobs/blobs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:twyns/utils/custom_tap.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/custom_slide_panel.dart';
import '../../utils/fonts/satoshi_font.dart';
import '../pulse/pulse_view.dart';
import 'chat_controller.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({super.key});

  final ChatController controller = Get.put(ChatController());

  @override
  Widget build(BuildContext context) {
    return CupertinoScaffold(
      // backgroundColor: const Color(0xFFF5F5F5),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/chat-bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) {
                      return IconButton(
                        icon: Icon(
                          LucideIcons.panelLeft,
                          size: 20.sp,
                          color: Colors.grey.shade200,
                        ),
                        onLongPress: () {
                          HapticFeedback.heavyImpact();
                          final authController = Get.find<AuthController>();
                          authController.logout();
                        },
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          OverlappingPanels.of(
                            context,
                          )?.reveal(RevealSide.left);
                        },
                      );
                    },
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/images/container-bg.png'),
                        fit: BoxFit.cover,
                        opacity: 0.3,
                        repeat: ImageRepeat.repeat,
                      ),
                      borderRadius: BorderRadius.circular(50.r),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Supercharged by',
                            style: Satoshi.font(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          VerticalDivider(
                            indent: 3,
                            endIndent: 2,
                            color: Colors.white,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: SvgPicture.asset(
                              'assets/icons/arm.svg',
                              width: 34,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Lottie.asset(
                  //   'assets/lottie/ai-audio.json',
                  //   width: 28.w,
                  //   height: 28.h,
                  //   fit: BoxFit.cover,
                  // ),
                  Center(child: BlobAvatar()),
                ],
              ),
              centerTitle: true,
              elevation: 0,
            ),
            SliverFillRemaining(
              child: Obx(() {
                if (controller.isLoadingModel.value) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!controller.isModelLoaded.value) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: controller.autoLoadModel,
                      child: const Text('Retry Loading Model'),
                    ),
                  );
                } else {
                  return Material(
                    color: Colors.transparent,
                    child: Chat(
                      currentUserId: ChatController.userId,
                      chatController: controller.chatController,
                      backgroundColor: Colors.transparent,
                      builders: types.Builders(
                        chatMessageBuilder:
                            (
                              context,
                              message,
                              index,
                              animation,
                              child, {
                              types.MessageGroupStatus? groupStatus,
                              bool? isRemoved,
                              required bool isSentByMe,
                            }) {
                              Widget messageContent;

                              var iconSize = 15.sp;
                              if (message is types.TextMessage) {
                                // Check if this is an AI message that's currently streaming
                                final isStreaming =
                                    !isSentByMe &&
                                    controller.isGenerating.value &&
                                    index == 0; // Latest message is at index 0

                                messageContent = isStreaming
                                    ? _StreamingTextWidget(
                                        text: message.text,
                                        isSentByMe: isSentByMe,
                                      )
                                    : Text(
                                        message.text,
                                        style: Satoshi.regular(
                                          fontSize: 14.sp,
                                          color: isSentByMe
                                              ? Colors.white
                                              : Colors.white,
                                        ),
                                      );
                              } else if (message is types.ImageMessage) {
                                messageContent = ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(message.source),
                                );
                              } else if (message is types.FileMessage) {
                                messageContent = Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.insert_drive_file_rounded,
                                      color: isSentByMe
                                          ? Colors.white
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        message.name,
                                        style: Satoshi.font(
                                          fontSize: 14.sp,
                                          color: isSentByMe
                                              ? Colors.white
                                              : const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                messageContent = Text(
                                  'Unsupported message type',
                                  style: Satoshi.font(
                                    fontSize: iconSize,
                                    color: Colors.grey,
                                  ),
                                );
                              }

                              return Align(
                                alignment: isSentByMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: isSentByMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.75,
                                      ),
                                      margin: EdgeInsets.symmetric(
                                        vertical: 4.h,
                                        horizontal: 16.w,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 12.h,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isSentByMe
                                            ? LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                stops: [
                                                  0.0, // 0%
                                                  0.59, // 59%
                                                  0.81, // 81%
                                                  1.0, // 100%
                                                ],
                                                colors: [
                                                  Color(
                                                    0x6E000000,
                                                  ), // 000000 at 43% opacity → 0x6E hex
                                                  Color(
                                                    0x40283054,
                                                  ), // 283054 at 25% opacity → 0x40 hex
                                                  Color(
                                                    0x59000000,
                                                  ), // 000000 at 25% opacity → 0x40 hex
                                                  Color(
                                                    0x2F442D41,
                                                  ), // F1A4E8 at 0% opacity → 0x00 hex
                                                ],
                                              )
                                            : LinearGradient(
                                                colors: [
                                                  // Colors.black.withOpacity(0.2),
                                                  // Colors.white.withOpacity(0.1),
                                                  Colors.transparent,
                                                  Colors.transparent,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                        border: Border.all(
                                          color: isSentByMe
                                              ? Colors.grey.shade700
                                                    .withOpacity(0.5)
                                              : Colors.grey.shade700
                                                    .withOpacity(0.5),
                                        ),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(18.r),
                                          topRight: Radius.circular(18.r),
                                          bottomLeft: isSentByMe
                                              ? Radius.circular(18.r)
                                              : Radius.circular(4.r),
                                          bottomRight: isSentByMe
                                              ? Radius.circular(4.r)
                                              : Radius.circular(18.r),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: messageContent,
                                    ),
                                    if (!isSentByMe)
                                      Padding(
                                        padding: EdgeInsets.only(top: 8.h),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.only(
                                                left: 16.w,
                                                bottom: 2.h,
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  spacing: 10,
                                                  children: [
                                                    Icon(
                                                      LucideIcons.thumbsUp,
                                                      size: iconSize,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    Icon(
                                                      LucideIcons.thumbsDown,
                                                      size: iconSize,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    Icon(
                                                      LucideIcons.share2,
                                                      size: iconSize,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    Icon(
                                                      LucideIcons.copy,
                                                      size: iconSize,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    Icon(
                                                      LucideIcons
                                                          .ellipsisVertical,
                                                      size: iconSize,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                        emptyChatListBuilder: (context) => EmptyChatState(),
                      ),
                      theme: types.ChatTheme(
                        typography: types.ChatTypography(
                          bodyLarge: Satoshi.font(
                            fontSize: 16.sp,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          bodyMedium: Satoshi.font(
                            fontSize: 14.sp,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          bodySmall: Satoshi.font(
                            fontSize: 12.sp,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          labelLarge: Satoshi.font(
                            fontSize: 18.sp,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                          labelMedium: Satoshi.font(
                            fontSize: 12.sp,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          labelSmall: Satoshi.font(
                            fontSize: 12.sp,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        colors: types.ChatColors(
                          primary: Colors.green,
                          onPrimary: Colors.green,
                          surface: Colors.green,
                          onSurface: Colors.white,
                          surfaceContainer: Colors.green,
                          surfaceContainerLow: Colors.transparent,
                          surfaceContainerHigh: Color(0xFF101010),
                        ),
                        shape: BorderRadiusGeometry.all(Radius.circular(12.r)),
                      ),
                      resolveUser: (userId) async {
                        if (userId == ChatController.userId) {
                          return types.User(
                            id: ChatController.userId,
                            name: 'You',
                          );
                        } else if (userId == ChatController.assistantId) {
                          return types.User(
                            id: ChatController.assistantId,
                            name: 'AI',
                          );
                        }
                        return null;
                      },
                      onMessageSend: (message) {
                        if (message.trim().isNotEmpty) {
                          controller.sendMessage(message.trim());
                        }
                      },
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

class BlobAvatar extends StatelessWidget {
  const BlobAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomTap(
      onTap: () {
        HapticFeedback.mediumImpact();
        CupertinoScaffold.showCupertinoModalBottomSheet(
          context: context,

          builder: (context) => Container(height: 0.7.sh, child: PulseView()),
        );
      },
      child: CircleAvatar(
        radius: 22.r,
        backgroundColor: Colors.white.withOpacity(0.1),
        child: CircleAvatar(
          radius: 20.r,
          backgroundImage: Image.asset(
            'assets/images/splash-bg.png',
            fit: BoxFit.scaleDown,
          ).image,
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Blob 1
                Blob.animatedRandom(
                  size: 40,
                  loop: true,
                  edgesCount: 5,
                  minGrowth: 2,
                  duration: Duration(milliseconds: 1000),
                  styles: BlobStyles(color: Color(0xFFCF7987)),
                ),
                // Blob 2
                Blob.animatedRandom(
                  size: 30,
                  loop: true,
                  edgesCount: 5,
                  minGrowth: 4,
                  duration: Duration(milliseconds: 1000),

                  styles: BlobStyles(color: Colors.blue),
                ),
                // Blob 3
                Blob.animatedRandom(
                  size: 20,
                  loop: true,
                  edgesCount: 9,
                  minGrowth: 4,
                  duration: Duration(milliseconds: 1000),
                  styles: BlobStyles(color: Color(0xFFC934A3)),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Icon(LucideIcons.mic, size: 16.sp, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyChatState extends StatelessWidget {
  const EmptyChatState({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = [
      {
        "avatar": "😂",
        "image": "comedy.png",
        "title": "Jokes & Fun",
        "description":
            "Hear a random joke, play a mini game, or brighten your day with some humor.",
      },

      {
        "avatar": "🎵",
        "title": "Music & Playlists",
        "image": "music.png",
        "description":
            "Discover new songs, curated playlists, or music recommendations for your mood.",
      },
      {
        "avatar": "💡",
        "title": "Advice & Tips",
        "image": "productivity.png",
        "description":
            "Ask Twyn for life, study, or productivity advice to make your day easier.",
      },
      // {
      //   "avatar": "🌟",
      //   "title": "Daily Inspiration",
      //   "description":
      //       "Get motivational quotes, positive thoughts, or a boost of encouragement for today.",
      // },
      //
      // {
      //   "avatar": "📚",
      //   "title": "Learn Something",
      //   "description":
      //       "Explore fun facts, trivia, or mini-lessons to expand your knowledge every day.",
      // },
      // {
      //   "avatar": "🗓️",
      //   "title": "Plan Your Day",
      //   "description":
      //       "Organize your tasks, set reminders, or plan your schedule with your Twyn's help.",
      // },
      // {
      //   "avatar": "🌤️",
      //   "title": "Weather & Updates",
      //   "description":
      //       "Check the daily weather, important updates, or local news highlights.",
      // },
      // {
      //   "avatar": "🧘",
      //   "title": "Mindfulness",
      //   "description":
      //       "Learn relaxation techniques, breathing exercises, or tips for mental well-being.",
      // },
    ];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              children: [
                Text(
                  "Hello Samuel,",
                  style: Satoshi.font(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                2.verticalSpace,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Text(
                    "Let's tackle today together \n— your Twyn has your back.",
                    style: Satoshi.font(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade400,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          14.verticalSpace,
          Padding(
            padding: EdgeInsets.only(left: 16.w),
            child: QuickSuggestionsGrid(
              row1: [
                "Hello Twyn! 👋",
                "Tell me a joke 😂",
                "Daily summary 📋",
                "Mood check",
                "Fun fact 🌟",
                "Play music 🎵",
                "Give me advice 💡",
              ],
              row2: [
                "Set reminder ⏰",
                "To-do list",
                "Motivation quote 💪",
                "Plan my day 🗓️",
                "Check my schedule",
                "Track habit 📈",
                "Weather update ☀️",
              ],
              onTap: (text) {
                print("User tapped: $text");
                // Send text to chat input or Twyn AI
              },
            ),
          ),
          10.verticalSpace,
          PopularTopics(
            topics: topics,
            onTap: (topic) {
              print("User tapped: ${topic['title']}");
              // Open chat with this topic
            },
          ),
        ],
      ),
    );
  }
}

class PopularTopics extends StatelessWidget {
  final List<Map<String, String>> topics;
  final Function(Map<String, String>) onTap;

  const PopularTopics({super.key, required this.topics, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Popular Topics",
                style: Satoshi.font(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Open full list page
                },
                child: Text(
                  "See All",
                  style: Satoshi.font(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: topics.length,
            separatorBuilder: (_, __) => SizedBox(width: 12),
            itemBuilder: (context, index) {
              final topic = topics[index];
              return GestureDetector(
                onTap: () => onTap(topic),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade100.withOpacity(0.1),
                    ),
                    color: Colors.grey.shade100.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blueAccent,
                        backgroundImage: Image.asset(
                          'assets/images/${topic['image']}',
                        ).image,
                      ),
                      SizedBox(height: 8),
                      Text(
                        topic['title'] ?? "",
                        style: Satoshi.font(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        topic['description'] ?? "",
                        style: Satoshi.font(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade400,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class QuickSuggestionsGrid extends StatelessWidget {
  final List<String> row1;
  final List<String> row2;
  final Function(String) onTap;

  const QuickSuggestionsGrid({
    super.key,
    required this.row1,
    required this.row2,
    required this.onTap,
  });

  Widget _buildRow(List<String> suggestions) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onTap(suggestion),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade100.withOpacity(0.1),
                  ),
                  color: Colors.grey.shade100.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    suggestion,
                    style: Satoshi.font(
                      color: Colors.grey.shade100,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildRow(row1), const SizedBox(height: 8), _buildRow(row2)],
    );
  }
}

class _StreamingTextWidget extends StatefulWidget {
  final String text;
  final bool isSentByMe;

  const _StreamingTextWidget({required this.text, required this.isSentByMe});

  @override
  State<_StreamingTextWidget> createState() => _StreamingTextWidgetState();
}

class _StreamingTextWidgetState extends State<_StreamingTextWidget>
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
          child: Text(
            widget.text,
            style: Satoshi.font(
              fontSize: 14.sp,
              color: widget.isSentByMe ? Colors.white : Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 2),
        FadeTransition(
          opacity: _cursorController,
          child: Container(
            width: 2,
            height: 18.h,
            decoration: BoxDecoration(
              color: widget.isSentByMe ? Colors.white : Colors.white,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}
