import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(),
      debugShowCheckedModeBanner: false,
      home: BluetoothPage(),
    );
  }
}

class BluetoothPage extends StatefulWidget {
  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      // 請求所有必要權限
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();

      // 檢查權限狀態
      statuses.forEach((permission, status) {
        print('$permission: $status');
      });

      // 確保所有權限都已授予
      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      if (!allGranted) {
        // 處理權限未授予的情況
        print('Not all permissions were granted');
        // 可以顯示一個對話框告知用戶需要這些權限
      }
    }
  }

  void startScan() async {
    try {
      // 檢查藍牙是否開啟
      if (!await FlutterBluePlus.isSupported) {
        print('設備不支持藍牙');
        return;
      }

      if (!(await FlutterBluePlus.adapterState.first ==
          BluetoothAdapterState.on)) {
        print('藍牙未開啟');
        return;
      }

      print('開始掃描設備...');
      setState(() {
        scanResults.clear();
        isScanning = true;
      });

      // 開始掃描
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 4),
        androidUsesFineLocation: true,
      );

      // 監聽掃描結果
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          print('發現設備: ${r.device.name} (${r.device.id})');
        }
        setState(() {
          scanResults = results;
        });
      }, onError: (error) {
        print('掃描錯誤: $error');
      });

      // 監聽掃描狀態
      FlutterBluePlus.isScanning.listen((scanning) {
        setState(() {
          isScanning = scanning;
        });
        if (!scanning) {
          print('掃描完成，共發現 ${scanResults.length} 個設備');
        }
      });
    } catch (e) {
      print('掃描過程發生錯誤: $e');
      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      print('已连接到设备：${device.name}');
      connectedDevice = device;

      List<BluetoothService> services = await device.discoverServices();
      print('发现服务数量: ${services.length}');

      for (var service in services) {
        print('检查服务 UUID: ${service.uuid}');
        // 轉換為小寫進行比較
        if (service.uuid.toString().toLowerCase() ==
            '19b10000-e8f2-537e-4f6c-d104768a1214') {
          print('找到目标服务');
          print('该服务的特征值数量: ${service.characteristics.length}');

          for (BluetoothCharacteristic c in service.characteristics) {
            print('特征值 UUID: ${c.uuid}');
            // 轉換為小寫進行比較
            if (c.uuid.toString().toLowerCase() ==
                '19b10001-e8f2-537e-4f6c-d104768a1214') {
              writeCharacteristic = c;
              print('找到写入特征值');
              break;
            }
          }
        }
      }

      if (writeCharacteristic == null) {
        print('警告：未找到写入特征值');
        // 添加更多調試信息
        for (var service in services) {
          print('服務 ${service.uuid} 包含以下特徵值：');
          for (var c in service.characteristics) {
            print('- ${c.uuid}');
          }
        }
      }

      setState(() {}); // 更新UI
    } catch (e) {
      print('连接错误: $e');
    }
  }

  Future<void> sendCommand(String command) async {
    if (writeCharacteristic != null) {
      try {
        List<int> bytes = utf8.encode(command);
        await writeCharacteristic!.write(bytes);
        print('發送命令: $command');
      } catch (e) {
        print('發送命令錯誤: $e');
      }
    } else {
      print('未找到寫入特徵');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('風扇控制'),
      ),
      body: Column(
        children: [
          // 掃描結果列表
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                return ListTile(
                  title: Text(result.device.name.isEmpty
                      ? 'Unknown Device'
                      : result.device.name),
                  subtitle: Text(result.device.id.toString()),
                  onTap: () => connectToDevice(result.device),
                );
              },
            ),
          ),
          // 控制按鈕
          if (connectedDevice != null) // 只在設備連接時顯示控制按鈕
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => sendCommand('SpeedDown'),
                    child: Text('風速降低'),
                  ),
                  ElevatedButton(
                    onPressed: () => sendCommand('SpeedUp'),
                    child: Text('風速增加'),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isScanning ? null : startScan,
        child: Icon(isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}
