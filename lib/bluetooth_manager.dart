// ignore_for_file: camel_case_types

import 'package:flutter_blue/flutter_blue.dart';


class bluetooth_manager {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? targetCharacteristic;
  final String targetDeviceName = "JDY-31-SPP";
  bool isScanning = false;
  bool isConnected = false;

  void startScan() {
    if (isScanning) return;

    isScanning = true;
    flutterBlue.startScan(timeout: Duration(seconds: 2));

    flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.name == targetDeviceName) {
          targetDevice = result.device;
          stopScanAndConnect();
          break;
        }
      }
    }).onDone(() {
      isScanning = false;
    });
  }

  void stopScanAndConnect() {
    if (!isScanning) return;

    flutterBlue.stopScan();
    isScanning = false;
    connectToDevice();
  }

  void connectToDevice() async {
    if (targetDevice == null) {
      print("No target device found");
      return;
    }
    if (isConnected) {
      print("Device is already connected");
      return;
    }

    try {
      await targetDevice!.connect();
      isConnected = true;
      discoverServices();
    } catch (e) {
      isConnected = false;
      print("Failed to connect to the device: $e");
    }
  }
}