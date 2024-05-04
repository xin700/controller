// ignore_for_file: prefer_final_fields, library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class BluetoothManager {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? targetCharacteristic;
  final String targetDeviceName = "JDY-31-SPP";
  bool isScanning = false;
  bool isConnected = false;

  void startScan() {
    if (isScanning) return;

    isScanning = true;
    flutterBlue.startScan(timeout: Duration(seconds: 4));

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

  void disconnectFromDevice() {
    if (isConnected && targetDevice != null) {
      targetDevice!.disconnect();
      isConnected = false;
      targetCharacteristic = null;
      print("Disconnected from the device.");
    }
  }

  void discoverServices() async {
    if (targetDevice == null) return;

    List<BluetoothService> services = await targetDevice!.discoverServices();
    services.forEach((service) {
      var characteristicUuid = Guid("0000ffe1-0000-1000-8000-00805f9b34fb"); // 这里需要换成实际使用的特征UUID
      service.characteristics.forEach((characteristic) {
        if(characteristic.uuid == characteristicUuid) {
          targetCharacteristic = characteristic;
          print("Target characteristic found: ${characteristic.uuid}");
        }
      });
    });
  }

  Future<void> sendDataToPeripheral(String data) async {
    if (!isConnected || targetCharacteristic == null) {
      print("No device connected or characteristic not found.");
      startScan();
      return;
    }

    List<int> bytes = utf8.encode(data); // 将字符串数据编码为字节数组
    await targetCharacteristic!.write(bytes);
    print("Data sent to peripheral");
  }
}
void main() => runApp(MyApp());
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BluetoothControlPage(),
    );
  }
}

class BluetoothControlPage extends StatefulWidget {
  @override
  _BluetoothControlPageState createState() => _BluetoothControlPageState();
}

class _BluetoothControlPageState extends State<BluetoothControlPage> {
  BluetoothManager _bluetoothManager = BluetoothManager();
  bool isLightOn = false; // 用于标记灯泡状态的布尔值
  
  @override
  void initState() {
    super.initState();
    // 立即开始连接到指定的蓝牙设备
    _bluetoothManager.startScan();
  }

  // 发送ASCII字符的方法，根据灯泡的状态交替发送 'a' 或 'b'
  void toggleLightAndSendCommand() {
    setState(() {
      isLightOn = !isLightOn;
      String command = isLightOn ?  'b' : 'a';
      _bluetoothManager.sendDataToPeripheral(command);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Light Control'),
      ),
      body: Center(
        child: IconButton(
          icon: Icon(
            isLightOn ? Icons.lightbulb : Icons.lightbulb_outline,
            size: 100, // 设置图标的尺寸
            color: isLightOn ? Colors.yellow : Colors.grey,
          ),
          onPressed: () {
            toggleLightAndSendCommand();
            // if (_bluetoothManager.targetDevice != null && _bluetoothManager.targetDevice!.state == BluetoothDeviceState.connected) {
            //   toggleLightAndSendCommand();
            // } else {
            //   print("Trying to reconnect to device.");
            //   _bluetoothManager.startScan();
            // }
          },
        ),
      ),
    );
  }
}