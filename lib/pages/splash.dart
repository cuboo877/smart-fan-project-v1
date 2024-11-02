import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test4/constant/appColor.dart';
import 'package:test4/pages/scanPage.dart';
import 'package:test4/service/ble_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    BleController()
        .checkBluetoothOn(); // Set client status before nav to scan page
    delayToNav();
  }

  void delayToNav() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ScanPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0); // 從右邊滑入
            const end = Offset.zero; // 到達目的地
            const curve = Curves.ease; // 使用緩和效果

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500), // 動畫時間
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.base,
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: AppColor.accent, width: 7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Fanshion",
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColor.accent),
          ),
        ),
      ),
    );
  }
}
