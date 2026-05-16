import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:untitled/Bluetooth/bluetooth_manager.dart';
import 'package:untitled/HomePage/homePage.dart';
import 'package:untitled/ThemeProvider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
            create: (_) =>
                BluetoothManager()), // Changé à ChangeNotifierProvider
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'SmartCar Pilot',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const BluetoothWrapper(),
    );
  }

  ThemeData _buildLightTheme() {
    const Color primaryColor = Color(0xFF1976D2);
    const Color secondaryColor = Color(0xFF64B5F6);

    return ThemeData.light().copyWith(
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFFF8FAFC),
      ),
      appBarTheme: const AppBarTheme(
        color: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: Colors.black,
        // bodyColor: Color(0x610B181E),
        displayColor: Color(0xFF263238),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const Color primaryColor = Color(0xFF64B5F6);
    const Color secondaryColor = Color(0xFF90CAF9);

    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFF121212),
      ),
      appBarTheme: const AppBarTheme(
        color: Color(0xFF1E1E1E),
        elevation: 1,
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
        color: const Color(0xFF2D2D2D),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
      ),
      textTheme: const TextTheme().apply(
        bodyColor: Color(0xFFE0E0E0),
        displayColor: Color(0xFFF5F5F5),
      ),
    );
  }
}

class BluetoothWrapper extends StatefulWidget {
  const BluetoothWrapper({super.key});

  @override
  State<BluetoothWrapper> createState() => _BluetoothWrapperState();
}

class _BluetoothWrapperState extends State<BluetoothWrapper> {
  BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    try {
      // Initial state
      _bluetoothState = await FlutterBluePlus.adapterState.first;

      // Listen for changes
      FlutterBluePlus.adapterState.listen((state) {
        if (mounted) {
          setState(() => _bluetoothState = state);
        }
      });
    } catch (e) {
      debugPrint('Bluetooth init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bluetoothState == BluetoothAdapterState.on) {
      return HomePage();
    } else {
      return _BluetoothOffScreen(bluetoothState: _bluetoothState);
    }
  }
}

class _BluetoothOffScreen extends StatelessWidget {
  final BluetoothAdapterState bluetoothState;

  const _BluetoothOffScreen({required this.bluetoothState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 50,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              bluetoothState == BluetoothAdapterState.off
                  ? 'Bluetooth désactivé'
                  : 'Bluetooth non disponible',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 30),
            if (bluetoothState == BluetoothAdapterState.off)
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth),
                label: const Text('ACTIVER BLUETOOTH'),
                onPressed: () async {
                  try {
                    await FlutterBluePlus.turnOn();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: ${e.toString()}')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
