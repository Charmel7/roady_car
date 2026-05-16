import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:untitled/Bluetooth/bluetooth_manager.dart';

class SoundSignalsPage extends StatefulWidget {
  const SoundSignalsPage({super.key});

  @override
  _SoundSignalsPageState createState() => _SoundSignalsPageState();
}

class _SoundSignalsPageState extends State<SoundSignalsPage>
    with TickerProviderStateMixin {
  int? _selectedSoundIndex;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _sounds = [
    {
      "name": "Klaxon",
      "description": "Son classique de klaxon",
      "icon": Icons.car_repair,
      "command": "1",
      "color": Colors.orange,
      "gradient": [Colors.orange, Colors.orange.shade800], // Ajouté
    },
    {
      "name": "Alerte",
      "description": "Bip d'avertissement",
      "icon": Icons.warning_rounded,
      "command": "2",
      "color": Colors.red,
      "gradient": [Colors.red, Colors.red.shade800], // Ajouté
    },
    {
      "name": "Sirène",
      "description": "Sirène de police",
      "icon": Icons.emergency,
      "command": "3",
      "color": Colors.blue,
      "gradient": [Colors.blue, Colors.blue.shade800], // Ajouté
    },
    {
      "name": "Musique",
      "description": "Petit jingle amusant",
      "icon": Icons.music_note,
      "command": "MUSIC",
      "color": Colors.purple,
      "gradient": [
        Colors.purple.shade300,
        Colors.purple.shade600
      ], // Déjà présent
    },
  ];
  late BluetoothManager _bluetoothManager;
  bool _isSending = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bluetoothManager = Provider.of<BluetoothManager>(context);
  }

  void _sendSoundCommand(String soundType) async {
    if (soundType.isEmpty) return;

    // Construire la commande Bluetooth (ajoute 'H' devant le type de son)
    final String bleCommand = "H$soundType"; // "H1", "H2" ou "H3"

    setState(() => _isSending = true);

    try {
      await _bluetoothManager.sendCommand(bleCommand);
      debugPrint('Commande envoyée: $bleCommand');
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Son envoyé: ${_getSoundName(soundType)}"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // Helper pour obtenir le nom du son à partir du type
  String _getSoundName(String soundType) {
    switch (soundType) {
      case '1':
        return 'Klaxon';
      case '2':
        return 'Alerte';
      case '3':
        return 'Sirène';
      default:
        return 'Son';
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // void _sendSoundCommand(String command) {
  //   // TODO: Implémentez la communication avec l'Arduino ici
  //   // Exemple: Bluetooth.send(command);
  //
  //   // Animation de pulsation
  //   _pulseController.forward().then((_) {
  //     _pulseController.reverse();
  //   });
  //
  //   // Feedback utilisateur
  //   HapticFeedback.mediumImpact();
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Row(
  //         children: [
  //           Icon(Icons.check_circle, color: Colors.white),
  //           SizedBox(width: 8),
  //           Text("Son envoyé: $command"),
  //         ],
  //       ),
  //       backgroundColor: Colors.green.shade600,
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       duration: Duration(seconds: 2),
  //     ),
  //   );
  // }

  Widget _buildSoundCard(Map<String, dynamic> sound, int index) {
    final isSelected = _selectedSoundIndex == index;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: isSelected
                      ? sound["gradient"]
                      : [
                          isDarkMode ? Colors.grey.shade800 : Colors.white,
                          isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade50,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? sound["color"].withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: isSelected ? 15 : 8,
                    offset: Offset(0, isSelected ? 8 : 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() => _selectedSoundIndex = index);
                    HapticFeedback.selectionClick();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : sound["color"].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            sound["icon"],
                            size: 32,
                            color: isSelected ? Colors.white : sound["color"],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sound["name"],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDarkMode
                                          ? Colors.white
                                          : Colors.black87),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                sound["description"],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.8)
                                      : (isDarkMode
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isSelected && _pulseController.isAnimating
                                  ? _pulseAnimation.value
                                  : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : sound["color"].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.play_arrow,
                                    color: isSelected
                                        ? Colors.white
                                        : sound["color"],
                                  ),
                                  onPressed: () {
                                    setState(() => _selectedSoundIndex = index);
                                    _sendSoundCommand(sound["command"]);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Signaux Sonores",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        margin: EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.volume_up,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Choisissez un son à émettre",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ...List.generate(
                  _sounds.length,
                  (index) => _buildSoundCard(_sounds[index], index),
                ),
                SizedBox(height: 24),
                if (_selectedSoundIndex != null)
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _sounds[_selectedSoundIndex!]
                                    ["gradient"],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: _sounds[_selectedSoundIndex!]["color"]
                                      .withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () {
                                  _sendSoundCommand(
                                      _sounds[_selectedSoundIndex!]["command"]);
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Envoyer le son",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
