import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/material.dart';

class BluetoothManager {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? targetDevice;
  final String targetDeviceName = "JDY-31-SPP";

  void startScan() {
    flutterBlue.startScan(timeout: Duration(seconds: 4));

    flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.name == targetDeviceName) {
          targetDevice = result.device;
          stopScanAndConnect(); // 如果找到目标设备，停止扫描并尝试连接
          break;
        }
      }
    });
  }

  void stopScanAndConnect() {
    flutterBlue.stopScan();
    connectToDevice();
  }

  void connectToDevice() async {
    if (targetDevice != null) {
      await targetDevice!.connect();
      print("Connected to the target device");
      discoverServices(targetDevice!);
    }
  }

  void discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      print("Discovered service: ${service.uuid.toString()}");
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        print("Discovered characteristic: ${characteristic.uuid.toString()}");
      }
    }
  }

  void sendDataToPeripheral(String dataString) async {
    if (targetDevice == null) {
      print("No connected peripheral");
      return;
    }

    List<BluetoothService> services = await targetDevice!.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString() == "FFE0") {
        var characteristics = service.characteristics;
        for (BluetoothCharacteristic characteristic in characteristics) {
          if (characteristic.uuid.toString() == "FFE1") {
            await characteristic.write(dataString.codeUnits, withoutResponse: false);
            print("Data sent to peripheral: $dataString");
            break;
          }
        }
        break;
      }
    }
  }
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Bluetooth Example'),
        ),
        body: Center(
          child: Text('Scan and Connect to Bluetooth Devices'),
        ),
      ),
    );
  }
}