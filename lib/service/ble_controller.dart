import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends ChangeNotifier {
  static final BleController _instance = BleController._internal();

  // 狀態變量
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;
  String lastReceivedMessage = '';
  BluetoothCharacteristic? notifyCharacteristic;

  factory BleController() {
    return _instance;
  }

  BleController._internal();

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });

      if (!allGranted) {
        print('Not all permissions were granted');
      }
    }
  }

  void startScan() async {
    try {
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
      scanResults.clear();
      isScanning = true;
      notifyListeners();

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );

      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          print('發現設備: ${r.device.name} (${r.device.id})');
        }
        scanResults = results;
        notifyListeners();
      }, onError: (error) {
        print('掃描錯誤: $error');
      });

      FlutterBluePlus.isScanning.listen((scanning) {
        isScanning = scanning;
        notifyListeners();
        if (!scanning) {
          print('掃描完成，共發現 ${scanResults.length} 個設備');
        }
      });
    } catch (e) {
      print('掃描過程發生錯誤: $e');
      isScanning = false;
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      print('已連接到設備：${device.name}');
      connectedDevice = device;
      notifyListeners();

      List<BluetoothService> services = await device.discoverServices();
      print('發現服務數量: ${services.length}');

      for (var service in services) {
        if (service.uuid.toString().toLowerCase() ==
            '19b10000-e8f2-537e-4f6c-d104768a1214') {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString().toLowerCase() ==
                '19b10001-e8f2-537e-4f6c-d104768a1214') {
              writeCharacteristic = c;
              notifyListeners();
              print('找到寫入特徵值');
            }
            if (c.uuid.toString().toLowerCase() ==
                '19b10002-e8f2-537e-4f6c-d104768a1214') {
              notifyCharacteristic = c;
              print('找到通知特徵值');
              await setupNotifications();
            }
          }
        }
      }

      if (writeCharacteristic == null) {
        print('警告：未找到寫入特徵值');
      }
      if (notifyCharacteristic == null) {
        print('警告：未找到通知特徵值');
      }
    } catch (e) {
      print('連接錯誤: $e');
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

  Future<void> setupNotifications() async {
    if (notifyCharacteristic != null) {
      try {
        await notifyCharacteristic!.setNotifyValue(true);
        notifyCharacteristic!.value.listen((value) {
          String message = utf8.decode(value);
          print('收到訊息: $message');
          lastReceivedMessage = message;
          notifyListeners();
        }, onError: (error) {
          print('通知錯誤: $error');
        });
        print('通知已啟用');
      } catch (e) {
        print('設置通知時出錯: $e');
      }
    }
  }
}
