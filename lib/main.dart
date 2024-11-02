import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test4/constant/appColor.dart';
import 'package:test4/constant/font.dart';
import 'package:test4/pages/splash.dart';
import 'package:test4/service/ble_controller.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => BleController()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fanshion Fan Controller',
      theme: ThemeData(
        fontFamily: "CascadiaMono",
        textTheme: const TextTheme(
          bodyLarge:
              TextStyle(color: AppColor.base, fontWeight: FontWeight.bold),
          bodyMedium:
              TextStyle(color: AppColor.base, fontWeight: FontWeight.bold),
          bodySmall:
              TextStyle(color: AppColor.base, fontWeight: FontWeight.bold),
        ),
        buttonTheme: const ButtonThemeData(
            buttonColor: AppColor.accent,
            padding: EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)))),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: AppColor.accent,
            foregroundColor: AppColor.accent,
            textStyle: Font.h1,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
