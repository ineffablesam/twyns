import 'dart:ui';

import 'package:blobs/blobs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/fonts/satoshi_font.dart';

class LeftPage extends StatelessWidget {
  const LeftPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> chats = [
      {
        "name": "Write me a TODO list",
        "message": "Sure! I created a clean 5-task checklist for you.",
        "time": "2m",
        "avatar": "https://i.pravatar.cc/150?img=12",
      },
      {
        "name": "Plan my day",
        "message": "Your day is now structured from morning to evening ✨",
        "time": "15m",
        "avatar": "https://i.pravatar.cc/150?img=24",
      },
      {
        "name": "Help me focus",
        "message": "I generated a 25-minute focus session for you.",
        "time": "1h",
        "avatar": "https://i.pravatar.cc/150?img=22",
      },
      {
        "name": "Summarize my notes",
        "message": "Your long notes are now a short and clear summary.",
        "time": "3h",
        "avatar": "https://i.pravatar.cc/150?img=18",
      },
      {
        "name": "Motivate me",
        "message": "Here’s a motivational message to lift you up 💛",
        "time": "5h",
        "avatar": "https://i.pravatar.cc/150?img=33",
      },
      {
        "name": "Give me an idea",
        "message": "I came up with 3 creative ideas you might like.",
        "time": "8h",
        "avatar": "https://i.pravatar.cc/150?img=40",
      },
    ];

    final AuthController authController = Get.find<AuthController>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
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
                  styles: BlobStyles(color: Color(0xFF2A0D2F)),
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

                  styles: BlobStyles(color: Colors.blue),
                ),
              ),
              // Blob 3
              Blob.animatedRandom(
                size: 0.6.sh,
                loop: true,
                edgesCount: 9,
                minGrowth: 4,
                duration: Duration(milliseconds: 4000),
                styles: BlobStyles(color: Color(0xFF571648)),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 180, sigmaY: 180),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 0.7.sw,
                    // color: Colors.white.withOpacity(0.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        50.verticalSpace,
                        // Profile Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24.r,
                                backgroundColor: Colors.grey.shade200
                                    .withOpacity(0.1),
                                child: Lottie.asset(
                                  '${authController.avatarPath.value}',
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  authController.name.value,
                                  style: Satoshi.font(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        14.verticalSpace,
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              // border: Border.all(
                              //   color: Colors.grey.shade400.withOpacity(0.2),
                              // ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Search",
                                hintStyle: Satoshi.font(
                                  fontSize: 13.sp,
                                  color: Colors.grey.shade400,
                                ),
                                border: InputBorder.none,
                                icon: Icon(
                                  LucideIcons.search,
                                  size: 18.sp,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Recent Chats Title
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Recent Chats",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // CHAT LIST
                        MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: ListView.builder(
                            itemCount: chats.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final chat = chats[index];
                              return InkWell(
                                onTap: () {},
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              chat["name"],
                                              style: Satoshi.font(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade100,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              chat["message"],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Satoshi.font(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w300,
                                                color: Colors.grey.shade400
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        chat["time"],
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Spacer(),
                        //Logout Button
                        SafeArea(
                          minimum: EdgeInsets.only(left: 16),
                          child: CircleAvatar(
                            radius: 20.r,
                            backgroundColor: Colors.red.shade100.withOpacity(
                              0.1,
                            ),
                            child: IconButton(
                              onPressed: () {
                                authController.logout();
                              },
                              icon: Icon(
                                LucideIcons.logOut,
                                color: Colors.red.shade400,
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
