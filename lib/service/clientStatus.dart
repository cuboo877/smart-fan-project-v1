import 'package:test4/service/ble_controller.dart';

String getStatusString(ClientStatus status) {
  switch (status) {
    case ClientStatus.BluetoothOff:
      print("藍牙未開啟");
      return "藍牙未開啟";
    case ClientStatus.StandBy:
      print("已開啟藍牙");
      return "已開啟藍牙";
    case ClientStatus.Scanning:
      print("掃描BLE裝置中...");
      return "掃描BLE裝置中...";
    case ClientStatus.FoundDevices:
      print("已掃描裝置:");
      return "已掃描裝置:";
    case ClientStatus.FoundNoDevices:
      print("尚未掃描到任何BLE裝置");
      return "尚未掃描到任何BLE裝置";
    case ClientStatus.Connected:
      print("已連接");
      return "已連接:";
    default:
      return "未知狀態";
  }
}
