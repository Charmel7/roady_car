import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:roady_car/Bluetooth/bluetooth_manager.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CourbesPage extends StatefulWidget {
  const CourbesPage({super.key});

  @override
  State<CourbesPage> createState() => _CourbesPageState();
}

class _CourbesPageState extends State<CourbesPage> {
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  final List<LiveData> speedData = [];
  final List<LiveData> gyroXData = [];
  final List<LiveData> gyroYData = [];
  final List<LiveData> gyroZData = [];
  bool _isConnected = false;
  bool showSpeed = true;
  bool showGyroX = true;
  bool showGyroY = false;
  bool showGyroZ = false;
  final int maxDataPoints = 100;
  int timeCounter = 0;
  late ZoomPanBehavior _zoomPanBehavior;
  StreamSubscription<List<int>>? _dataSubscription;

  double currentSpeed = 0.0;
  double currentGyroX = 0.0;
  double currentGyroY = 0.0;
  double currentGyroZ = 0.0;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: true,
      enablePanning: true,
    );
    _initBluetooth();
  }

  void _initBluetooth() {
    final bluetoothManager = context.read<BluetoothManager>();

    // Écouter les changements d'état de connexion
    _connectionSubscription =
        bluetoothManager.connectionStateStream.listen((state) {
      final newState = state == BluetoothConnectionState.connected;
      if (mounted && newState != _isConnected) {
        setState(() => _isConnected = newState);

        if (newState) {
          _subscribeToData(bluetoothManager);
        } else {
          _dataSubscription?.cancel();
          _dataSubscription = null;
        }
      }
    });

    // Initialisation pour l'état actuel
    _isConnected = bluetoothManager.isConnected;
    if (_isConnected) {
      _subscribeToData(bluetoothManager);
    }
  }

  void _subscribeToData(BluetoothManager bluetoothManager) {
    _dataSubscription?.cancel();
    _dataSubscription = bluetoothManager.dataStream.listen(
      _processBluetoothData,
      onError: (e) => debugPrint('Data stream error: $e'),
    );
  }

  late BluetoothManager _bluetoothManager;
  late StreamSubscription<bool> _connectionSub;
  late StreamSubscription<List<int>> _dataSub;

  @override
  void didChangeDependencies() {
    final bluetoothManager = Provider.of<BluetoothManager>(context);
    _connectionSubscription?.cancel();
    _connectionSubscription = bluetoothManager.connectionState.listen((state) {
      final newState = state == BluetoothConnectionState.connected;
      if (mounted) {
        setState(() => _isConnected = newState);
        if (newState) {
          _dataSubscription?.cancel();
          _dataSubscription =
              bluetoothManager.dataStream.listen(_processBluetoothData);
        }
      }
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    super.dispose();
  }

  void _processBluetoothData(List<int> data) {
    final now = timeCounter * 0.1; // 10 Hz = 0.1s par point
    timeCounter++;

    try {
      final dataStr = utf8.decode(data).trim();

      // On ignore si ce n'est pas une trame de télémétrie (ex: Radar D:)
      if (!dataStr.startsWith('T:')) return;

      final parts = dataStr.substring(2).split(',');

      if (parts.length >= 4) {
        final speed = double.tryParse(parts[0]) ?? 0;
        final gx = double.tryParse(parts[1]) ?? 0;
        final gy = double.tryParse(parts[2]) ?? 0;
        final gz = double.tryParse(parts[3]) ?? 0;

        setState(() {
          currentSpeed = speed;
          currentGyroX = gx;
          currentGyroY = gy;
          currentGyroZ = gz;
          _addDataPoint(now, speed, gx, gy, gz);
          _trimDataLists();
        });
      }
    } catch (e) {
      debugPrint('Error processing data: $e');
    }
  }

  void _addDataPoint(
      double time, double speed, double gx, double gy, double gz) {
    speedData.add(LiveData(time, speed));
    gyroXData.add(LiveData(time, gx));
    gyroYData.add(LiveData(time, gy));
    gyroZData.add(LiveData(time, gz));
  }

  void _trimDataLists() {
    while (speedData.length > maxDataPoints) {
      speedData.removeAt(0);
    }
    while (gyroXData.length > maxDataPoints) {
      gyroXData.removeAt(0);
    }
    while (gyroYData.length > maxDataPoints) {
      gyroYData.removeAt(0);
    }
    while (gyroZData.length > maxDataPoints) {
      gyroZData.removeAt(0);
    }
  }

  // Score de stabilité retiré à la demande de l'utilisateur

  Future<void> _exportCSV() async {
    final bluetoothManager =
        Provider.of<BluetoothManager>(context, listen: false);
    final deviceName = bluetoothManager.isConnected
        ? (bluetoothManager.connectedDevice?.name ?? 'unnamed_device')
        : 'disconnected_device';

    final rows = [
      ['Time', 'Speed', 'GyroX', 'GyroY', 'GyroZ'],
      ...List.generate(
          speedData.length,
          (i) => [
                speedData[i].time.toStringAsFixed(2),
                speedData[i].value.toStringAsFixed(2),
                gyroXData[i].value.toStringAsFixed(2),
                gyroYData[i].value.toStringAsFixed(2),
                gyroZData[i].value.toStringAsFixed(2),
              ])
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/car_data_${deviceName}_${DateTime.now().millisecondsSinceEpoch}.csv');

    await file.writeAsString(csv);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data exported to ${file.path}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothManager = Provider.of<BluetoothManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courbes de données'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportCSV,
          ),
        ],
      ),
      body: Column(
        children: [
          //_buildConnectionStatus(),
          _buildCurrentValues(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: speedData.isEmpty
                  ? _buildEmptyState(bluetoothManager)
                  : SfCartesianChart(
                      zoomPanBehavior: _zoomPanBehavior,
                      primaryXAxis:
                          NumericAxis(title: AxisTitle(text: 'Time (s)')),
                      primaryYAxis:
                          NumericAxis(title: AxisTitle(text: 'Value')),
                      series: _getChartSeries(),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildConnectionStatus() {
  //   return ListTile(
  //     leading: Icon(
  //       _isReallyConnected
  //           ? Icons.bluetooth_connected
  //           : Icons.bluetooth_disabled,
  //       color: _isReallyConnected ? Colors.green : Colors.red,
  //     ),
  //     title: Text(
  //       _isReallyConnected
  //           ? 'Connecté à ${_bluetoothManager.connectedDevice?.name ?? 'appareil'}'
  //           : 'Non-connecté',
  //     ),
  //     trailing: _isReallyConnected
  //         ? ElevatedButton(
  //             child: const Text('Déconnecter'),
  //             onPressed: () => _bluetoothManager.disconnect(),
  //           )
  //         : ElevatedButton(
  //             child: const Text('Connecter'),
  //             onPressed: () => Navigator.pushNamed(context, '/device-scan'),
  //           ),
  //   );
  // }

  Widget _buildEmptyState(BluetoothManager bluetoothManager) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth, size: 50, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            bluetoothManager.isConnected
                ? 'Waiting for data...'
                : 'Please connect to a device',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentValues() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildValueTile('Speed', '${currentSpeed.toStringAsFixed(1)} km/h',
                Colors.blue),
            _buildValueTile(
                'Gyro X', currentGyroX.toStringAsFixed(2), Colors.red),
            _buildValueTile(
                'Gyro Y', currentGyroY.toStringAsFixed(2), Colors.green),
            _buildValueTile(
                'Gyro Z', currentGyroZ.toStringAsFixed(2), Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildValueTile(String title, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  List<LineSeries<LiveData, double>> _getChartSeries() {
    return <LineSeries<LiveData, double>>[
      if (showSpeed && speedData.isNotEmpty)
        LineSeries<LiveData, double>(
          name: 'Speed (km/h)',
          dataSource: speedData.toList(),
          color: Colors.blue,
          width: 2,
          xValueMapper: (LiveData data, _) => data.time,
          yValueMapper: (LiveData data, _) => data.value,
          animationDuration: 0,
        ),
      if (showGyroX && gyroXData.isNotEmpty)
        LineSeries<LiveData, double>(
          name: 'Gyro X',
          dataSource: gyroXData.toList(),
          color: Colors.red,
          width: 2,
          xValueMapper: (LiveData data, _) => data.time,
          yValueMapper: (LiveData data, _) => data.value,
          animationDuration: 0,
        ),
      if (showGyroY && gyroYData.isNotEmpty)
        LineSeries<LiveData, double>(
          name: 'Gyro Y',
          dataSource: gyroYData.toList(),
          color: Colors.green,
          width: 2,
          xValueMapper: (LiveData data, _) => data.time,
          yValueMapper: (LiveData data, _) => data.value,
          animationDuration: 0,
        ),
      if (showGyroZ && gyroZData.isNotEmpty)
        LineSeries<LiveData, double>(
          name: 'Gyro Z',
          dataSource: gyroZData.toList(),
          color: Colors.orange,
          width: 2,
          xValueMapper: (LiveData data, _) => data.time,
          yValueMapper: (LiveData data, _) => data.value,
          animationDuration: 0,
        ),
    ];
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Display Settings"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSwitchListTile('Show Speed', showSpeed, (val) {
                      setDialogState(() => showSpeed = val);
                      setState(() => showSpeed = val);
                    }, Colors.blue),
                    _buildSwitchListTile('Show Gyro X', showGyroX, (val) {
                      setDialogState(() => showGyroX = val);
                      setState(() => showGyroX = val);
                    }, Colors.red),
                    _buildSwitchListTile('Show Gyro Y', showGyroY, (val) {
                      setDialogState(() => showGyroY = val);
                      setState(() => showGyroY = val);
                    }, Colors.green),
                    _buildSwitchListTile('Show Gyro Z', showGyroZ, (val) {
                      setDialogState(() => showGyroZ = val);
                      setState(() => showGyroZ = val);
                    }, Colors.orange),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Close'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSwitchListTile(
      String title, bool value, Function(bool) onChanged, Color color) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
      ),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: color,
      ),
    );
  }
}

class LiveData {
  LiveData(this.time, this.value);
  final double time;
  final double value;
}
