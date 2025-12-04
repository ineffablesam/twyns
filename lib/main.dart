import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twyns/routes/app_pages.dart';

import 'config/supabase_config.dart';
import 'controllers/auth_controller.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  debugPrint('✅ Supabase initialized');
  Get.put(AuthController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GestureDetector(
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: GetMaterialApp(
            title: 'Twyns',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
            initialRoute: AppPages.INITIAL,
            getPages: AppPages.routes,
            color: Colors.black,
          ),
        );
      },
    );
  }
}
