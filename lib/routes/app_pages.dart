// routes/app_pages.dart
import 'package:get/get.dart';
import 'package:twyns/modules/home/home.dart';

import '../controllers/audio_visualizer_controller.dart';
import '../modules/onboarding/onboarding_screen.dart';
import '../modules/splash/splash_controller.dart';
import '../modules/splash/splash_screen.dart';
import '../routes/app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => SplashScreen(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),

    GetPage(
      name: Routes.ONBOARDING,
      page: () => OnboardingScreen(),
      binding: BindingsBuilder(() {
        Get.put(OnboardingController());
      }),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => ChatScreen(),
      // binding: BindingsBuilder(() {
      //   Get.put(OnboardingController());
      // }),
    ),

    // Later add:
    // GetPage(name: Routes.LOGIN, page: () => LoginScreen(), binding: LoginBinding()),
    // GetPage(name: Routes.HOME, page: () => HomePage(), binding: HomeBinding()),
  ];
}
