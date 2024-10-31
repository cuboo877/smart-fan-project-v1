import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/ble_controller.dart';
import 'control_page.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜尋設備'),
      ),
      body: Consumer<BleController>(
        builder: (context, controller, child) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: controller.scanResults.length,
                  itemBuilder: (context, index) {
                    final result = controller.scanResults[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(
                          result.device.name.isEmpty
                              ? 'Unknown Device'
                              : result.device.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(result.device.id.toString()),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await controller.connectToDevice(result.device);
                          if (controller.connectedDevice != null) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => ControlPage(),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              if (controller.scanResults.isEmpty && !controller.isScanning)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('沒有找到設備，請點擊掃描按鈕'),
                  ),
                ),
              if (controller.isScanning)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<BleController>(
        builder: (context, controller, child) {
          return FloatingActionButton(
            onPressed: controller.isScanning ? null : controller.startScan,
            child: Icon(controller.isScanning ? Icons.stop : Icons.search),
          );
        },
      ),
    );
  }
}
