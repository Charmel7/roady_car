import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled/Bluetooth/ble_constants.dart';

class BluetoothManager extends ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  StreamSubscription<List<int>>? _dataSubscription;
  List<BluetoothDevice> _discoveredDevices = [];
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;
  final StreamController<List<BluetoothDevice>> _devicesController =
      StreamController<List<BluetoothDevice>>.broadcast();
  Stream<List<BluetoothDevice>> get discoveredDevicesStream =>
      _devicesController.stream;

  bool get isConnected => _connectedDevice?.isConnected ?? false;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Stream<BluetoothConnectionState> get connectionStateStream {
    return connectedDevice?.connectionState ??
        Stream.value(BluetoothConnectionState.disconnected);
  }

  Future<void> sendPriorityCommand(String command) async {
    if (_rxCharacteristic == null) return;

    try {
      await _rxCharacteristic!
          .write(utf8.encode(command), withoutResponse: true);
    } catch (e) {
      debugPrint('Priority command error: $e');
    }
  }

  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        return false;
      }

      // Vérifier l'état Bluetooth
      final bluetoothState = await FlutterBluePlus.adapterState.first;
      if (bluetoothState != BluetoothAdapterState.on) {
        try {
          await FlutterBluePlus.turnOn();
          // Attendre que le Bluetooth soit activé
          await FlutterBluePlus.adapterState
              .firstWhere((state) => state == BluetoothAdapterState.on);
          return true;
        } catch (e) {
          debugPrint('Failed to turn on Bluetooth: $e');
          return false;
        }
      }
    }
    return true;
  }

  Stream<bool> get isConnectedStream => connectionStateStream
      .map((state) => state == BluetoothConnectionState.connected);

  @override
  void dispose() {
    _devicesController.close();
    // ... autres nettoyages
    super.dispose();
  }

  Future<void> startScan() async {
    if (!await _checkPermissions()) {
      throw Exception('Permissions not granted');
    }
    _discoveredDevices.clear();
    notifyListeners();

    try {
      await FlutterBluePlus.stopScan();
      FlutterBluePlus.scanResults.listen((results) {
        _discoveredDevices = results.map((r) => r.device).toSet().toList();
        _devicesController.add(_discoveredDevices);
        notifyListeners();
      });
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Scan error: $e');
      rethrow;
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
      _connectedDevice = device;
      notifyListeners();

      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() ==
            BluetoothConstants.serviceUuid.toLowerCase()) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            // Caractéristique TX (Notifications)
            if (characteristic.uuid.toString().toLowerCase() ==
                BluetoothConstants.txUuid.toLowerCase()) {
              _txCharacteristic = characteristic;

              // Vérification de null avant d'utiliser setNotifyValue
              if (_txCharacteristic != null) {
                await _txCharacteristic!.setNotifyValue(true);
                _dataSubscription =
                    _txCharacteristic!.onValueReceived.listen((data) {
                  notifyListeners();
                });
              }
            }

            // Caractéristique RX (Écriture)
            if (characteristic.uuid.toString().toLowerCase() ==
                BluetoothConstants.rxUuid.toLowerCase()) {
              _rxCharacteristic = characteristic;
            }
          }
        }
      }

      if (_txCharacteristic == null || _rxCharacteristic == null) {
        throw Exception('Characteristics not found. '
            'TX: ${_txCharacteristic != null ? "found" : "missing"}, '
            'RX: ${_rxCharacteristic != null ? "found" : "missing"}');
      }
    } catch (e) {
      debugPrint('Connection error: $e');
      await disconnect();
      rethrow;
    }
  }

  // Ajouter cette méthode pour vérifier l'état de connexion
  Stream<BluetoothConnectionState> get connectionState {
    return _connectedDevice?.connectionState ??
        Stream.value(BluetoothConnectionState.disconnected);
  }

  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    if (_connectedDevice != null) {
      await _connectedDevice?.disconnect();
    }
    _connectedDevice = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    notifyListeners();
  }

  void printDebug(String message) {
    debugPrint('[BluetoothManager] $message');
  }

  Future<void> sendCommand(String command) async {
    if (!isConnected || _rxCharacteristic == null) {
      throw Exception('Not connected to device');
    }
    await _rxCharacteristic!.write(utf8.encode(command));
  }

  Stream<List<int>> get dataStream {
    _txCharacteristic ??= throw Exception('Not connected to device');
    return _txCharacteristic!.onValueReceived;
  }
}

Stream<List<BluetoothDevice>> get discoveredDevicesStream {
  return FlutterBluePlus.scanResults
      .map((results) => results.map((r) => r.device).toSet().toList());
}
