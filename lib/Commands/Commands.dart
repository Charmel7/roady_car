import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:untitled/Bluetooth/bluetooth_manager.dart';
import 'package:vector_math/vector_math.dart' as vm;

class CommandsPage extends StatefulWidget {
  const CommandsPage({super.key});

  @override
  State<CommandsPage> createState() => _CommandsPageState();
}

enum ControlMode { manual, auto }

class _CommandsPageState extends State<CommandsPage> {
  double _speed = 0.0;
  double _acceleration = 0.0;
  double _brake = 0.0;
  bool _isForward = true;
  ControlMode _mode = ControlMode.manual;
  bool _isDirectionPressed = false;
  String? _pressedDirection;
  String? _connectedWifi = 'WiFi_Car_123';
  final List<String> _availableWifis = [
    'WiFi_Car_123',
    'Hotspot_Phone',
    'Home_WiFi'
  ];
  BluetoothManager? _bluetoothManager;
  late StreamSubscription<bool> _connectionSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bluetoothManager = Provider.of<BluetoothManager>(context);
    _connectionSubscription =
        _bluetoothManager!.isConnectedStream.listen((isConnected) {
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Déconnecté du dispositif')),
        );
      }
    });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  void _sendCommand(String command) {
    if (command.isEmpty ||
        _bluetoothManager == null ||
        !_bluetoothManager!.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande invalide ou non connecté')),
      );
      return;
    }

    _bluetoothManager!
        .sendCommand(command)
        .then((_) => HapticFeedback.lightImpact())
        .catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contrôle Voiture"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withOpacity(0.8)
                  ]
                : [
                    theme.colorScheme.primaryContainer.withOpacity(0.3),
                    theme.colorScheme.surface
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildStatusBar(isDark),
              _buildModeSelector(isDark),
              Expanded(
                child: _mode == ControlMode.manual
                    ? _buildManualControl(theme)
                    : _buildAutoControl(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showWifiBottomSheet(isDark),
            child: Row(
              children: [
                Icon(
                  Icons.wifi,
                  size: 18,
                  color: _connectedWifi != null
                      ? Colors.greenAccent
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(width: 4),
                Text(
                  _connectedWifi ?? "Non connecté",
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Icon(
            Icons.battery_charging_full,
            size: 18,
            color: isDark ? Colors.greenAccent : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(
            "87%",
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900]!.withOpacity(0.5) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: ToggleButtons(
          isSelected: [_mode == ControlMode.manual, _mode == ControlMode.auto],
          onPressed: (index) {
            setState(() {
              _mode = index == 0 ? ControlMode.manual : ControlMode.auto;
              _sendCommand(_mode == ControlMode.auto ? 'MA' : 'MM');
            });
            HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(20),
          selectedColor: Colors.white,
          fillColor: Theme.of(context).colorScheme.primary,
          color: isDark ? Colors.grey[600] : Colors.grey[500],
          constraints: const BoxConstraints(minHeight: 42, minWidth: 0),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child:
                  Text('MANUEL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('AUTOMATIQUE',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualControl(ThemeData theme) {
    return Column(
      children: [
        _buildSpeedDisplay(theme),
        Expanded(child: _buildDirectionalPad(theme)),
        _buildPedalControls(theme),
      ],
    );
  }

  Widget _buildSpeedDisplay(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            '${_speed.toStringAsFixed(1)} km/h',
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionalPad(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 20,
              child: _buildDirectionButton(
                  Icons.arrow_upward, 'Avancer', theme, 'top'),
            ),
            Positioned(
              bottom: 20,
              child: _buildDirectionButton(
                  Icons.arrow_downward, 'Reculer', theme, 'bottom'),
            ),
            Positioned(
              left: 20,
              child: _buildDirectionButton(
                  Icons.arrow_back, 'Gauche', theme, 'left'),
            ),
            Positioned(
              right: 20,
              child: _buildDirectionButton(
                  Icons.arrow_forward, 'Droite', theme, 'right'),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _speed = 0.0;
                  _acceleration = 0.0;
                  _brake = 0.0;
                });
                _sendCommand('S0');
                HapticFeedback.heavyImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.error,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.error.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.stop, size: 36, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionButton(
      IconData icon, String label, ThemeData theme, String direction) {
    final isPressed = _isDirectionPressed && _pressedDirection == direction;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isDirectionPressed = true;
          _pressedDirection = direction;
        });

        String command = '';
        switch (direction) {
          case 'top':
            command = 'F';
            break;
          case 'bottom':
            command = 'B';
            break;
          case 'left':
            command = 'L';
            break;
          case 'right':
            command = 'R';
            break;
        }

        _sendCommand(command);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => setState(() {
        _isDirectionPressed = false;
        _pressedDirection = null;
      }),
      onTapCancel: () => setState(() {
        _isDirectionPressed = false;
        _pressedDirection = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: isPressed ? 60 : 70,
        height: isPressed ? 60 : 70,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isPressed
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isPressed ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: isPressed ? 3 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isPressed
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isPressed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPedalControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPedalControl(
                  value: _brake,
                  onChanged: (v) {
                    setState(() => _brake = v);
                    _sendCommand('B${v.toInt()}');
                  },
                  color: theme.colorScheme.error,
                  label: "FREIN",
                  icon: Icons.fitness_center,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                      border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3)),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isForward ? Icons.arrow_upward : Icons.arrow_downward,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: () {
                        setState(() => _isForward = !_isForward);
                        _sendCommand(_isForward ? 'F' : 'B');
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isForward ? 'AVANT' : 'ARRIÈRE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildPedalControl(
                  value: _acceleration,
                  onChanged: (v) {
                    setState(() {
                      _acceleration = v;
                      _speed = v * 0.8;
                    });
                    int speedValue = (v * 2.55).toInt();
                    _sendCommand('S$speedValue');
                  },
                  color: Colors.green,
                  label: "ACCÉLÉRER",
                  icon: Icons.flash_on,
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FREIN: ${_brake.toInt()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              Text(
                'ACCÉLÉRATION: ${_acceleration.toInt()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoControl(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Text(
                  'MODE AUTOMATIQUE',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withOpacity(0.7)),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Text('ACTIF', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_car,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'STATUT DU VÉHICULE',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusIndicator(
                        'Vitesse',
                        '${_speed.toStringAsFixed(1)} km/h',
                        Icons.speed,
                        theme.colorScheme.primary,
                        theme),
                    _buildStatusIndicator(
                      'Batterie',
                      '87%',
                      Icons.battery_charging_full,
                      Colors.green,
                      theme,
                    ),
                    _buildStatusIndicator(
                      'Distance',
                      '1.4 km',
                      Icons.alt_route,
                      theme.colorScheme.secondary,
                      theme,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text(
                      'DÉTECTION D\'OBSTACLES',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 200),
                        painter: RadarPainter(isDark: isDark),
                      ),
                      const Positioned(
                        bottom: 20,
                        child: Icon(Icons.directions_car,
                            size: 36, color: Colors.white),
                      ),
                      Positioned(
                          bottom: 80,
                          left: 80,
                          child: _buildRadarObject(30, true)),
                      Positioned(
                          bottom: 100,
                          right: 100,
                          child: _buildRadarObject(45, false)),
                      Positioned(
                          bottom: 120,
                          left: 120,
                          child: _buildRadarObject(60, false)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.play_circle, color: theme.colorScheme.secondary),
                    const SizedBox(width: 12),
                    Text(
                      'ACTIONS AUTOMATIQUES',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAutoActionButton(
                          'Exploration', Icons.explore, theme, 'AX'),
                      const SizedBox(width: 12),
                      _buildAutoActionButton(
                          'Ligne droite', Icons.straight, theme, 'AL'),
                      const SizedBox(width: 12),
                      _buildAutoActionButton(
                          'Circuit', Icons.repeat, theme, 'AC'),
                      const SizedBox(width: 12),
                      _buildAutoActionButton(
                          'Stationnement', Icons.local_parking, theme, 'AS'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                _speed = 0.0;
                _acceleration = 0.0;
                _brake = 100.0;
              });
              _sendCommand('E');
              HapticFeedback.heavyImpact();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.error),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emergency, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    Text(
                      'ARRÊT D\'URGENCE',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPedalControl({
    required double value,
    required Function(double) onChanged,
    required Color color,
    required String label,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: theme.textTheme.labelSmall?.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onVerticalDragUpdate: (details) {
            final newValue = (value - details.delta.dy / 2).clamp(0.0, 100.0);
            onChanged(newValue);
          },
          child: Container(
            width: 30,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  width: 1.0),
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: value,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(
      String label, String value, IconData icon, Color color, ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 30, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildRadarObject(int distance, bool isClose) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isClose
            ? Colors.red.withOpacity(0.8)
            : Colors.orange.withOpacity(0.6),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isClose ? Colors.red : Colors.orange,
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$distance cm',
          style: const TextStyle(color: Colors.white, fontSize: 9),
        ),
      ),
    );
  }

  Widget _buildAutoActionButton(
      String label, IconData icon, ThemeData theme, String command) {
    return GestureDetector(
      onTap: () {
        _sendCommand(command);
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                width: 1.0)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.secondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWifiBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Réseaux WiFi disponibles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableWifis.length,
                  itemBuilder: (context, index) {
                    final wifi = _availableWifis[index];
                    return ListTile(
                      leading: const Icon(Icons.wifi),
                      title: Text(wifi),
                      trailing: _connectedWifi == wifi
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() => _connectedWifi = wifi);
                        Navigator.pop(context);
                        HapticFeedback.lightImpact();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations'),
        content: const Text('Contrôle manuel et automatique de la voiture\n\n'
            '• Utilisez les flèches pour diriger\n'
            '• Bouton central pour arrêt d\'urgence\n'
            '• Mode automatique pour les parcours prédéfinis'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final bool isDark;

  RadarPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.grey[700]! : Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height - 20),
      Offset(size.width, size.height - 20),
      paint,
    );

    for (int i = 1; i <= 3; i++) {
      final radius = size.height * 0.25 * i;
      final rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height - 20),
        radius: radius,
      );
      canvas.drawArc(rect, vm.radians(180), vm.radians(180), false, paint);
    }

    for (int i = 1; i <= 2; i++) {
      final angle = i * 45;
      final x1 = size.width / 2;
      final y1 = size.height - 20;
      final x2 = x1 + size.height * 0.7 * cos(vm.radians(angle.toDouble()));
      final y2 = y1 - size.height * 0.7 * sin(vm.radians(angle.toDouble()));

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
