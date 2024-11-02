import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/ble_controller.dart';
import 'scanPage.dart';

class ControlPage extends StatefulWidget {
  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  late BleController _bleController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bleController = Provider.of<BleController>(context);
  }

  @override
  void dispose() {
    _bleController.connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_bleController.connectedDevice == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ScanPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('風扇控制'),
        leading: IconButton(
          icon: const Icon(Icons.bluetooth_disabled),
          onPressed: () async {
            await _bleController.connectedDevice?.disconnect();
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ScanPage()),
            );
          },
        ),
      ),
      body: Consumer<BleController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              Text(controller.connectedDevice?.name ?? 'Unknown Device'),
              Text(controller.lastReceivedMessage.isEmpty
                  ? '等待訊息...'
                  : controller.lastReceivedMessage),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => controller.sendCommand('SpeedDown'),
                    child: const Text('風速降低'),
                  ),
                  ElevatedButton(
                    onPressed: () => controller.sendCommand('SpeedUp'),
                    child: const Text('風速增加'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
