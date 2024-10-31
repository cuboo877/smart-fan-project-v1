import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/ble_controller.dart';
import 'scan_page.dart';

class ControlPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, controller, child) {
        // 如果設備斷開連接，返回掃描頁面
        if (controller.connectedDevice == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ScanPage()),
            );
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('風扇控制'),
            leading: IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: () async {
                await controller.connectedDevice?.disconnect();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const ScanPage()),
                );
              },
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            '已連接設備',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.connectedDevice?.name ??
                                'Unknown Device',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            '設備回傳訊息',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            controller.lastReceivedMessage.isEmpty
                                ? '等待訊息...'
                                : controller.lastReceivedMessage,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.remove),
                        label: const Text('風速降低'),
                        onPressed: () => controller.sendCommand('SpeedDown'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('風速增加'),
                        onPressed: () => controller.sendCommand('SpeedUp'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
