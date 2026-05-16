import 'dart:async';

import 'package:flutter/material.dart';

class Objectifs extends StatefulWidget {
  const Objectifs({super.key});

  @override
  _ObjectifsState createState() => _ObjectifsState();
}

class _ObjectifsState extends State<Objectifs>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  late Timer _timer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': "Innovation Mobile",
      'icon': Icons.rocket_launch,
      'content':
          "Notre voiture connectée intègre une IA de pointe pour une conduite autonome sécurisée. Le système analyse en temps réel l'environnement routier avec une précision inégalée.",
      'color': Colors.blueAccent,
    },
    {
      'title': "Analyse Intelligente",
      'icon': Icons.insights,
      'content':
          "Grâce à nos capteurs haute performance, nous évaluons la qualité des routes et fournissons des données précieuses pour l'entretien des infrastructures.",
      'color': Colors.lightBlue,
    },
    {
      'title': "Expérience Utilisateur",
      'icon': Icons.phone_iphone,
      'content':
          "Notre application offre un contrôle complet et une visualisation claire des données de conduite, avec des alertes personnalisées pour une expérience optimale.",
      'color': Colors.cyan,
    },
    {
      'title': "Équipe Passionnée",
      'icon': Icons.people,
      'content':
          "ElectroDeclic rassemble des étudiants talentueux déterminés à repousser les limites de la technologie mobile. Notre club est lauréat de plusieurs hackathons nationaux.",
      'color': Colors.tealAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      _fadeController.reset();
      final nextPage = _currentPage < _slides.length - 1 ? _currentPage + 1 : 0;
      _pageController
          .animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOutQuint,
          )
          .then((_) => _fadeController.forward());
    });
    _fadeController.forward();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'À Propos du Projet',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimary,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: Stack(
        children: [
          // Background dynamique avec dégradé animé
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        Colors.blueGrey.shade900,
                        Colors.blueGrey.shade800,
                        Colors.black87,
                      ]
                    : [
                        Colors.blue.shade50,
                        Colors.blue.shade100,
                        Colors.white,
                      ],
              ),
            ),
          ),

          // Effet de particules subtiles
          IgnorePointer(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/techno_bg.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                      _fadeController.reset();
                      _fadeController.forward();
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.scale(
                            scale: _fadeAnimation.value * 0.2 + 0.8,
                            child: child,
                          ),
                        );
                      },
                      child: _buildSlide(_slides[index], isDarkMode),
                    );
                  },
                ),
              ),
              _buildIndicators(),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Card(
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        shadowColor: slide['color'].withOpacity(0.4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      Colors.blueGrey.shade800.withOpacity(0.8),
                      Colors.blueGrey.shade900.withOpacity(0.9),
                    ]
                  : [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.98),
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  slide['icon'],
                  size: 48,
                  color: slide['color'],
                ),
                const SizedBox(height: 20),
                Text(
                  slide['title'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.blueGrey.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    slide['content'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: isDarkMode
                          ? Colors.grey.shade300
                          : Colors.blueGrey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildTechChips(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechChips(bool isDarkMode) {
    final techs = ["IA Embarquée", "Capteurs IoT", "Cloud", "Flutter"];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: techs
          .map((tech) => Chip(
                backgroundColor: isDarkMode
                    ? Colors.blueGrey.shade700.withOpacity(0.5)
                    : Colors.blue.shade50,
                label: Text(
                  tech,
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.blue.shade200
                        : Colors.blue.shade700,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _slides.asMap().entries.map((entry) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _currentPage == entry.key ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentPage == entry.key
                ? Colors.blueAccent
                : Colors.blueGrey.withOpacity(0.4),
          ),
        );
      }).toList(),
    );
  }
}
