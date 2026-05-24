import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:roady_car/Bluetooth/bluetooth_manager.dart';

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
  ControlMode _mode = ControlMode.manual;
  bool _isDirectionPressed = false;
  String? _pressedDirection;
  
  bool _obstacleDetected = false;

  BluetoothManager? _bluetoothManager;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  Timer? _pedalTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bluetoothManager = Provider.of<BluetoothManager>(context);
    
    _connectionSubscription?.cancel();
    _connectionSubscription =
        _bluetoothManager!.isConnectedStream.listen((isConnected) {
      if (!isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Déconnecté du dispositif')),
          );
        }
      } else {
        _subscribeToData();
      }
    });

    if (_bluetoothManager!.isConnected) {
      _subscribeToData();
    }
  }

  void _subscribeToData() {
    _dataSubscription?.cancel();
    _dataSubscription = _bluetoothManager!.dataStream.listen((data) {
      try {
        final dataStr = utf8.decode(data).trim();
        if (dataStr.startsWith('D:')) {
          final val = dataStr.substring(2);
          if (mounted) {
            setState(() {
              _obstacleDetected = (val == '1');
            });
          }
        }
      } catch (e) {
        debugPrint("Erreur parsing: $e");
      }
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _pedalTimer?.cancel();
    super.dispose();
  }

  void _sendCommand(String command) {
    if (command.isEmpty ||
        _bluetoothManager == null ||
        !_bluetoothManager!.isConnected) {
      return;
    }

    _bluetoothManager!
        .sendCommand(command)
        .catchError((e) {
      debugPrint('Erreur: ${e.toString()}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contrôle Voiture", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
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
        child: SafeArea(
          child: Column(
            children: [
              _buildModeSelector(isDark),
              Expanded(
                child: _mode == ControlMode.manual
                    ? _buildManualControl(theme, isDark)
                    : _buildAutoControl(theme, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
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
          borderRadius: BorderRadius.circular(25),
          selectedColor: Colors.white,
          fillColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF6366F1),
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          constraints: const BoxConstraints(minHeight: 45, minWidth: 0),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
              child: const Text('MANUEL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.15),
              child: const Text('AUTO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualControl(ThemeData theme, bool isDark) {
    return Column(
      children: [
        _buildSpeedDisplay(theme, isDark),
        Expanded(child: _buildDirectionalPad(theme, isDark)),
        _buildPedalControls(theme, isDark),
      ],
    );
  }

  Widget _buildSpeedDisplay(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2), size: 28),
          const SizedBox(width: 12),
          Text(
            '${_speed.toStringAsFixed(1)} km/h',
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionalPad(ThemeData theme, bool isDark) {
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
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 15,
              child: _buildDirectionButton(Icons.arrow_upward, 'Avancer', theme, isDark, 'top'),
            ),
            Positioned(
              bottom: 15,
              child: _buildDirectionButton(Icons.arrow_downward, 'Reculer', theme, isDark, 'bottom'),
            ),
            Positioned(
              left: 15,
              child: _buildDirectionButton(Icons.arrow_back, 'Gauche', theme, isDark, 'left'),
            ),
            Positioned(
              right: 15,
              child: _buildDirectionButton(Icons.arrow_forward, 'Droite', theme, isDark, 'right'),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _speed = 0.0;
                  _acceleration = 0.0;
                  _brake = 0.0;
                });
                _sendCommand('E');
                HapticFeedback.heavyImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade600,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.stop, size: 40, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionButton(
      IconData icon, String label, ThemeData theme, bool isDark, String direction) {
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
      onTapUp: (_) {
        setState(() {
          _isDirectionPressed = false;
          _pressedDirection = null;
        });
        _sendCommand('S0'); // Envoie un arrêt dès le relâchement !
      },
      onTapCancel: () {
        setState(() {
          _isDirectionPressed = false;
          _pressedDirection = null;
        });
        _sendCommand('S0');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: isPressed ? 65 : 75,
        height: isPressed ? 65 : 75,
        decoration: BoxDecoration(
          color: isPressed
              ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF6366F1))
              : (isDark ? Colors.grey.shade800 : Colors.white),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isPressed ? 0.0 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 30,
          color: isPressed
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildPedalControls(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPedalButton(
                label: 'FREIN',
                icon: Icons.stop_circle_outlined,
                color: Colors.red,
                isDark: isDark,
                onHoldStart: () {
                  _pedalTimer?.cancel();
                  _pedalTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
                    setState(() {
                       _brake = (_brake + 10).clamp(0.0, 100.0);
                       _acceleration = (_acceleration - 15).clamp(0.0, 100.0);
                       _speed = _acceleration * 0.8;
                    });
                    int speedValue = (_acceleration * 2.55).toInt();
                    _sendCommand('S$speedValue');
                  });
                },
                onHoldEnd: () {
                  _pedalTimer?.cancel();
                  setState(() => _brake = 0);
                }
              ),
              _buildPedalButton(
                label: 'ACCÉLÉRER',
                icon: Icons.electric_bolt,
                color: Colors.green,
                isDark: isDark,
                onHoldStart: () {
                  _pedalTimer?.cancel();
                  _pedalTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
                    setState(() {
                       _acceleration = (_acceleration + 5).clamp(0.0, 100.0);
                       _speed = _acceleration * 0.8;
                    });
                    int speedValue = (_acceleration * 2.55).toInt();
                    _sendCommand('S$speedValue');
                  });
                },
                onHoldEnd: () {
                  _pedalTimer?.cancel();
                }
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text('Frein', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                     const SizedBox(height: 4),
                     LinearProgressIndicator(
                       value: _brake / 100, 
                       color: Colors.red, 
                       backgroundColor: Colors.red.withOpacity(0.2),
                       minHeight: 8,
                       borderRadius: BorderRadius.circular(4),
                     ),
                   ]
                 )
               ),
               const SizedBox(width: 32),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     Text('Accélération', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                     const SizedBox(height: 4),
                     LinearProgressIndicator(
                       value: _acceleration / 100, 
                       color: Colors.green, 
                       backgroundColor: Colors.green.withOpacity(0.2),
                       minHeight: 8,
                       borderRadius: BorderRadius.circular(4),
                     ),
                   ]
                 )
               ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPedalButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onHoldStart,
    required VoidCallback onHoldEnd,
  }) {
    return GestureDetector(
      onTapDown: (_) {
         HapticFeedback.heavyImpact();
         onHoldStart();
      },
      onTapUp: (_) => onHoldEnd(),
      onTapCancel: () => onHoldEnd(),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.3) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 3),
          boxShadow: [
             BoxShadow(
               color: color.withOpacity(0.2), 
               blurRadius: 15, 
               spreadRadius: 2
             )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ]
        )
      )
    );
  }

  Widget _buildAutoControl(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF6366F1), size: 30),
                const SizedBox(width: 16),
                Text(
                  'PILOTAGE AUTO',
                  style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _obstacleDetected ? Icons.warning_amber : Icons.radar, 
                      color: _obstacleDetected ? Colors.red : Colors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'DÉTECTION D\'OBSTACLES',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _obstacleDetected 
                        ? Colors.red.withOpacity(0.2) 
                        : Colors.green.withOpacity(0.1),
                    border: Border.all(
                      color: _obstacleDetected ? Colors.red : Colors.green,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_obstacleDetected ? Colors.red : Colors.green).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ]
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _obstacleDetected ? Icons.dangerous : Icons.check_circle_outline,
                          color: _obstacleDetected ? Colors.red : Colors.green,
                          size: 80,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _obstacleDetected ? "OBSTACLE!" : "VOIE LIBRE",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _obstacleDetected ? Colors.red : Colors.green,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () {
              setState(() {
                _speed = 0.0;
                _acceleration = 0.0;
                _brake = 0.0;
              });
              _sendCommand('E');
              HapticFeedback.heavyImpact();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emergency, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'ARRÊT D\'URGENCE',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
