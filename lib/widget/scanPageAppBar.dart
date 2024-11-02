import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test4/constant/appColor.dart';
import 'package:test4/constant/font.dart';
import 'package:test4/service/ble_controller.dart';

class ScanPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ScanPageAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, controller, child) {
        String title = controller.getStatusString();
        return AppBar(
          shadowColor: AppColor.accent,
          title: Text(title, style: Font.h2),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
