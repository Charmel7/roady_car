import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:roady_car/Bluetooth/bluetooth_manager.dart';
import 'package:roady_car/Commands/Commands.dart';
import 'package:roady_car/Courbes/courbes.dart';
import 'package:roady_car/MusicSelector/MusicSelector.dart';
import 'package:roady_car/Objectifs/Objectifs.dart';
import 'package:roady_car/members/Members.dart';
import 'package:roady_car/settings/setting.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late BluetoothManager _bluetoothManager;
  bool _isScanning = false;
  String _connectionStatus = 'Non connecté';
  BluetoothDevice? _connectedDevice;

  List<BluetoothDevice> _availableDevices = [];
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Initialisation Bluetooth
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _scanDevices();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bluetoothManager = Provider.of<BluetoothManager>(context);

    // Écouter les changements de connexion
    _bluetoothManager.connectionState.listen((state) {
      if (mounted) {
        setState(() {
          _connectedDevice = _bluetoothManager.connectedDevice;
          _connectionStatus = state == BluetoothConnectionState.connected
              ? 'Connecté à ${_connectedDevice?.name ?? 'appareil'}'
              : 'Non connecté';
        });
      }
    });
  }

  Future<void> _disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      if (mounted) {
        setState(() {
          _connectedDevice = null;
          _connectionStatus = 'Déconnecté';
        });
      }
    }
  }

  Future<void> initBluetooth() async {
    if (!await FlutterBluePlus.isSupported) return;

    // Vérifier si Bluetooth est activé
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }

    // Vérifier les permissions
    if (!await _checkPermissions()) return;

    // Démarrer le scan
    await _bluetoothManager.startScan();
  }

  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        return false;
      }

      // Activer Bluetooth si nécessaire
      // if (await FlutterBluePlus.adapterState.first !=
      //     BluetoothAdapterState.on) {
      //   return await FlutterBluePlus.turnOn();
      // }
    }
    return true;
  }

  Future<void> _scanDevices() async {
    try {
      setState(() => _isScanning = true);
      await _bluetoothManager.startScan();

      // Écouter les nouveaux appareils découverts
      _bluetoothManager.discoveredDevicesStream.listen((devices) {
        if (mounted) {
          setState(() => _availableDevices = devices);
        }
      });
    } catch (e) {
      _handleBluetoothError(e, context);
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  // Future<void> _requestPermissions() async {
  //   // Demander la permission de localisation (nécessaire pour le scan Bluetooth sur Android)
  //   if (Platform.isAndroid) {
  //     bool granted = await Permission.locationWhenInUse.request().isGranted;
  //     if (!granted) {
  //       granted = await Permission.location.request().isGranted;
  //     }
  //     if (!granted) {
  //       debugPrint("Location permission not granted");
  //     }
  //   }
  // }

  void _handleBluetoothError(dynamic e, BuildContext context) {
    String errorMessage = "Erreur inconnue";

    if (e is FlutterBluePlusException) {
      errorMessage = "Erreur Bluetooth: ${e.description}";
    } else if (e is PlatformException) {
      errorMessage = "Erreur plateforme: ${e.message}";
    } else {
      errorMessage = "Erreur: ${e.toString()}";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _bluetoothManager.connect(device);
    } catch (e) {
      _handleBluetoothError(e, context);
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutQuart,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutBack,
      ),
    );

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _fadeController.forward();
    _slideController.forward();
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: _buildAppBar(context, theme, isDarkMode),
      drawer: _buildDrawer(context, isDarkMode),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF0F0F23),
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                  ]
                : [
                    const Color(0xFFF8FAFF),
                    const Color(0xFFEEF2FF),
                    const Color(0xFFE0E7FF),
                  ],
          ),
        ),
        child: Stack(
          children: [
            _buildBackgroundElements(isDarkMode),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context, isDarkMode),
                  _buildButtonGrid(context, isSmallScreen, isDarkMode),
                  _buildFooter(isDarkMode),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, ThemeData theme, bool isDarkMode) {
    return AppBar(
      elevation: 5,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF1E3A8A).withOpacity(0.3),
                    const Color(0xFF3B82F6).withOpacity(0.2),
                  ]
                : [
                    const Color(0xFFDDD6FE).withOpacity(0.8),
                    const Color(0xFFC7D2FE).withOpacity(0.6),
                  ],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [const Color(0xFF3B82F6), const Color(0xFF1E40AF)]
                    : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.blue : Colors.purple)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.electric_car,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ElectroDeclic",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  "Smart Car",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        isDarkMode ? Colors.blue[300] : const Color(0xFF6366F1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Center(
            child: Badge(
              label: Text(_connectedDevice != null ? '1' : '0'),
              child: IconButton(
                icon: Icon(
                  _connectedDevice != null
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth,
                  color: _connectedDevice != null
                      ? Colors.greenAccent
                      : Colors.white,
                ),
                onPressed: () => _showBluetoothDialog(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showBluetoothDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<List<BluetoothDevice>>(
          stream: _bluetoothManager.discoveredDevicesStream,
          builder: (context, snapshot) {
            final devices = snapshot.data ?? [];
            return AlertDialog(
              title: const Text('Appareils Bluetooth'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isScanning) const LinearProgressIndicator(),
                  if (_bluetoothManager.isConnected)
                    ListTile(
                      leading: const Icon(Icons.bluetooth_connected,
                          color: Colors.green),
                      title: Text(_bluetoothManager.connectedDevice?.name ??
                          'Appareil'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _bluetoothManager.disconnect,
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(device.name.isEmpty
                              ? 'Appareil inconnu'
                              : device.name),
                          subtitle: Text(device.remoteId.toString()),
                          onTap: () {
                            Navigator.pop(context);
                            _connectToDevice(device);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _scanDevices,
                  child: const Text('Scanner'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBackgroundElements(bool isDarkMode) {
    return Stack(
      children: [
        // Floating circles
        Positioned(
          top: 100,
          right: -50,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDarkMode
                          ? [
                              const Color(0xFF3B82F6).withOpacity(0.1),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFF6366F1).withOpacity(0.1),
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 200,
          left: -30,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_floatingAnimation.value * 0.7),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDarkMode
                          ? [
                              const Color(0xFF10B981).withOpacity(0.1),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFF06B6D4).withOpacity(0.1),
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [
                          const Color(0xFF1E40AF).withOpacity(0.2),
                          const Color(0xFF3B82F6).withOpacity(0.1),
                        ]
                      : [
                          const Color(0xFF6366F1).withOpacity(0.1),
                          const Color(0xFF8B5CF6).withOpacity(0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFF3B82F6).withOpacity(0.3)
                      : const Color(0xFF6366F1).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: isDarkMode ? Colors.amber : const Color(0xFFF59E0B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Évaluez la qualité de vos routes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.star,
                    color: isDarkMode ? Colors.amber : const Color(0xFFF59E0B),
                    size: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tableau de bord intelligent',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Analysez, pilotez et optimisez votre expérience de conduite',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color:
                        isDarkMode ? Colors.grey[300] : const Color(0xFF64748B),
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonGrid(
      BuildContext context, bool isSmallScreen, bool isDarkMode) {
    return Expanded(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 2 : 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: isSmallScreen ? 0.9 : 1.1,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 600 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: CotonButton(
                        number: index + 1,
                        index: index,
                        isDarkMode: isDarkMode,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          switch (index) {
                            case 0:
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CourbesPage()));
                              break;
                            case 1:
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CommandsPage()));
                              break;
                            case 2:
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          SoundSignalsPage()));
                              break;
                            case 3:
                              // Action pour le bouton 4
                              break;
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.copyright,
            size: 16,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            "2025 ElectroDeclic - Tous droits réservés",
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image de fond en pleine largeur
                Image.asset(
                  'assets/images/voiture.jpg', // Votre image
                  fit: BoxFit.cover,
                ),

                // Overlay sombre pour améliorer la lisibilité
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),

                // Contenu textuel positionné en bas
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'ElectroDeclic',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Smart Car Dashboard',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Partie liste du drawer (inchangée)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              children: [
                // Séparateur décoratif supérieur
                _buildDivider(isDarkMode),

                // Bouton Paramètres
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
                  page: Settings(),
                  isDarkMode: isDarkMode,
                ),

                // Séparateur avec effet de gradient
                _buildDivider(isDarkMode),

                // Bouton À propos
                _buildDrawerItem(
                  context,
                  icon: Icons.info_outlined,
                  title: 'À propos du projet',
                  page: Objectifs(),
                  isDarkMode: isDarkMode,
                ),

                // Séparateur avec effet de gradient
                _buildDivider(isDarkMode),

                // Bouton Membres
                _buildDrawerItem(
                  context,
                  icon: Icons.people_outlined,
                  title: "Membres de l'équipe",
                  page: Members(),
                  isDarkMode: isDarkMode,
                ),

                // Séparateur décoratif inférieur
                _buildDivider(isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
      child: Divider(
        height: 2,
        thickness: 2,
        color: isDarkMode
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.06),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDarkMode ? Colors.blue : theme.colorScheme.primary)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDarkMode ? Colors.blue[300] : theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => page));
        },
      ),
    );
  }
}

class CotonButton extends StatefulWidget {
  final int number;
  final int index;
  final bool isDarkMode;
  final VoidCallback onPressed;

  const CotonButton({
    required this.number,
    required this.index,
    required this.isDarkMode,
    required this.onPressed,
    super.key,
  });

  @override
  _CotonButtonState createState() => _CotonButtonState();
}

class _CotonButtonState extends State<CotonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  static const List<IconData> _icons = [
    Icons.analytics_outlined,
    Icons.gamepad_outlined,
    Icons.music_note_outlined,
    Icons.history_outlined,
  ];

  static const List<String> _labels = [
    "Courbes",
    "Pilotage",
    "Signaux",
    "Historique"
  ];

  static const List<String> _descriptions = [
    "Analyse données",
    "Contrôle manuel",
    "Gestion audio",
    "Données passées"
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _elevationAnimation = Tween<double>(begin: 8.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Color> _getButtonColors() {
    if (widget.isDarkMode) {
      return [
        [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
        [const Color(0xFF059669), const Color(0xFF10B981)],
        [const Color(0xFFDC2626), const Color(0xFFEF4444)],
        [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
      ][widget.index % 4];
    } else {
      return [
        [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
        [const Color(0xFF10B981), const Color(0xFF34D399)],
        [const Color(0xFFEF4444), const Color(0xFFF87171)],
        [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
      ][widget.index % 4];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getButtonColors();
    final icon = _icons[widget.index % _icons.length];
    final label = _labels[widget.index];
    final description = _descriptions[widget.index];

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _animationController.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _animationController.reverse();
              widget.onPressed();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _animationController.reverse();
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(0.4),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
