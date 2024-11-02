import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum ClientStatus {
  BluetoothOff,
  StandBy,
  Scanning,
  FoundDevices,
  FoundNoDevices,
  Connected,
  CancelConnection,
  Connecting,
  ConnectionError,
}

class BleController extends ChangeNotifier {
  static final BleController _instance = BleController._internal();
  // 狀態變量
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;
  BluetoothDevice? connectingDevice;
  BluetoothCharacteristic? writeCharacteristic; // send command to slave
  BluetoothCharacteristic? notifyCharacteristic; // receive message from slave
  String lastReceivedMessage = '';
  ClientStatus status = ClientStatus.BluetoothOff;

  factory BleController() {
    return _instance;
  }

  BleController._internal();

  String getStatusString() {
    switch (status) {
      case ClientStatus.BluetoothOff:
        return "藍牙未開啟";
      case ClientStatus.StandBy:
        return "已開啟藍牙";
      case ClientStatus.Scanning:
        return "掃描BLE裝置中...";
      case ClientStatus.FoundDevices:
        return "已掃描裝置: ${scanResults.length}";
      case ClientStatus.FoundNoDevices:
        return "尚未掃描到任何BLE裝置...";
      case ClientStatus.Connected:
        return "已連接:${connectedDevice?.name}";
      case ClientStatus.CancelConnection:
        return "已斷開連結";
      case ClientStatus.Connecting:
        return "正在連接:${connectingDevice?.name ?? "未知裝置"}...";
      case ClientStatus.ConnectionError:
        return "與${connectingDevice?.name ?? "未知裝置"}的連接失敗";
      default:
        return "未知狀態";
    }
  }

  void updateStatus(ClientStatus newStatus) {
    status = newStatus;
    notifyListeners();
  }

  Future<void> checkBluetoothOn() async {
    final bluetoothState = await FlutterBluePlus.adapterState.first;
    if (bluetoothState == BluetoothAdapterState.off) {
      status = ClientStatus.BluetoothOff;
    } else {
      status = ClientStatus.StandBy;
    }
  }

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

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      isScanning = false;
      status = scanResults.isNotEmpty
          ? ClientStatus.FoundDevices
          : ClientStatus.FoundNoDevices;
      notifyListeners();
      print('已停止掃描');
    } catch (e) {
      print('停止掃描時發生錯誤: $e');
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

      if (status == ClientStatus.Connected) {
        await disconnect();
      }

      print('開始掃描設備...');
      scanResults.clear();
      isScanning = true;
      status = ClientStatus.Scanning;
      notifyListeners();

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

      FlutterBluePlus.scanResults.listen((results) {
        scanResults = results;
        notifyListeners();
      }, onError: (error) {
        print('掃描錯誤: $error');
      });

      FlutterBluePlus.isScanning.listen((scanning) {
        isScanning = scanning;
        if (!scanning) {
          if (scanResults.isNotEmpty) {
            status = ClientStatus.FoundDevices;
          } else {
            status = ClientStatus.FoundNoDevices;
          }
          print('掃描完成，共發現 ${scanResults.length} 個設備');
        }
        notifyListeners();
      });
    } catch (e) {
      print('掃描過程發生錯誤: $e');
      isScanning = false;
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // 先斷開之前的連接
      if (connectedDevice != null) {
        await connectedDevice!.disconnect();
      }

      // 嘗試連接新設備
      status = ClientStatus.Connecting;
      connectingDevice = device;
      notifyListeners();
      await device
          .connect(
        timeout: const Duration(seconds: 5), // 設置超時時間
        autoConnect: false, // 不使用自動重連
      )
          .catchError((error) {
        print('連接失敗，嘗試重新連接...');
        // 如果連接失敗，先斷開再重試一次
        return device.disconnect().then((_) {
          return device.connect(
            timeout: const Duration(seconds: 5),
            autoConnect: false,
          );
        });
      });

      print('已連接到設備：${device.name}');
      connectedDevice = device;
      status = ClientStatus.Connected;
      notifyListeners();

      // 發現服務
      List<BluetoothService> services = await device.discoverServices();
      print('發現服務數量: ${services.length}');

      for (var service in services) {
        print('發現服務: ${service.uuid}');

        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          print('  特徵值: ${characteristic.uuid}');
          print('  屬性: ${_getCharacteristicProperties(characteristic)}');

          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            writeCharacteristic = characteristic;
            print('  設置為寫入特徵值');
          }

          if (characteristic.properties.notify ||
              characteristic.properties.indicate) {
            notifyCharacteristic = characteristic;
            print('  設置為通知特徵值');
            await setupNotifications();
          }
        }
      }

      if (writeCharacteristic == null) {
        print('警告：未找到寫入特徵值');
      }
      if (notifyCharacteristic == null) {
        print('警告：未找到通知特徵');
      }
    } catch (e) {
      print('連接錯誤: $e');
      status = ClientStatus.FoundDevices;
      notifyListeners();
      // 確保設備斷開
      try {
        await device.disconnect();
      } catch (disconnectError) {
        print('斷開連接時發生錯誤: $disconnectError');
      }
      status = ClientStatus.ConnectionError;
      notifyListeners();
      connectingDevice = null;
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

  Future<void> disconnect() async {
    try {
      if (connectedDevice != null) {
        await connectedDevice!.disconnect();
        print('已斷開連接：${connectedDevice?.name}');
        connectedDevice = null;
        writeCharacteristic = null;
        notifyCharacteristic = null;
        status = ClientStatus.StandBy;
        notifyListeners();
      }
    } catch (e) {
      print('斷開連接時發生錯誤: $e');
    }
  }

  Future<void> cancelConnecting() async {
    if (connectingDevice != null) {
      try {
        await connectingDevice!.disconnect();
        connectingDevice = null;
        status = ClientStatus.FoundDevices;
        notifyListeners();
      } catch (e) {
        print('取消連接時發生錯誤: $e');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _getCharacteristicProperties(BluetoothCharacteristic characteristic) {
    List<String> props = [];
    if (characteristic.properties.broadcast) props.add('broadcast');
    if (characteristic.properties.read) props.add('read');
    if (characteristic.properties.write) props.add('write');
    if (characteristic.properties.writeWithoutResponse)
      props.add('writeWithoutResponse');
    if (characteristic.properties.notify) props.add('notify');
    if (characteristic.properties.indicate) props.add('indicate');
    return props.join(', ');
  }
}
