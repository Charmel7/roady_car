import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// Clé de navigation globale
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class Members extends StatefulWidget {
  const Members({super.key});

  @override
  State<Members> createState() => _MembersState();
}

class _MembersState extends State<Members> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Notre Équipe',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: colorScheme.primary,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDeveloperSection(
              name: 'SENOU',
              surname: 'M. André',
              role: 'Formateur',
              description:
                  'Étudiant en génie énergétique et procédés à l\'UNSTIM. ',
              imagePath: 'assets/menbre/André.jpg',
              email: 'andresenou03@gmail.com',
              whatsapp: '+22996322349',
              linkedin: 'linkedin.com/in/andresenou',
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 20),
            _buildDeveloperSection(
              name: 'AFFOUKOU',
              surname: 'Prosper Charmel',
              role: 'Participant',
              description:
                  'Étudiant en deuxième année des Classes préparatoires à INSPEI ',
              imagePath: 'assets/menbre/img.png',
              email: 'prosperaffoukou@outlook.com',
              whatsapp: '+2290146656416',
              linkedin: 'linkedin.com/in/prosper-charmel',
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 20),
            _buildDeveloperSection(
              name: 'TOKANNOU',
              surname: 'Kérane',
              role: 'Participante',
              description: 'Étudiante'
                  ' en deuxième année des Classes préparatoires à INSPEI ',
              imagePath: 'assets/menbre/kerane.jpg',
              email: 'kerane.tks@gmail.com',
              whatsapp: '+2290145767950',
              linkedin: 'linkedin.com/in/kerane-tokannou-8b004b329 ',
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 20),
            _buildDeveloperSection(
              name: 'KINTI',
              surname: 'Linus',
              role: 'Participant',
              description:
                  "Étudiant en 2 ème année des équipements motorisés à l'ENSGEP/UNSTIM",
              imagePath: 'assets/menbre/linus.jpg',
              email: 'yenanlinus@gmail.com',
              whatsapp: '+2290141618684',
              linkedin: 'linkedin.com/in/linus-kinti ',
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 20),
            _buildDeveloperSection(
              name: 'BOTCHI',
              surname: 'Parfait',
              role: 'Participant',
              description:
                  "Étudiant en deuxième année de classe préparatoire à l'INSPEI ",
              imagePath: 'assets/menbre/parfait.jpg',
              email: 'parfaitbotchi1@gmail.com',
              whatsapp: '+22960115726',
              linkedin: 'linkedin.com/in/parfait-botchi ',
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 20),
            _buildDeveloperSection(
              name: 'MEHOUNOU',
              surname: 'Styve',
              role: 'Participant',
              description:
                  "Étudiant en froid et climatisation en deuxième année à l'ENSGEP",
              imagePath: 'assets/menbre/styve.jpg',
              email: 'mehounoustyve@gmail.com',
              whatsapp: '+2290157513589',
              linkedin: '',
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 20),
            _buildDeveloperSection(
              name: 'YLANDJO',
              surname: 'Hoscard G.',
              role: 'Participant',
              description:
                  "Étudiant en Équipements Motorisés  en deuxième année à l'ENSGEP",
              imagePath: 'assets/menbre/hoscard.jpg',
              email: 'ylandjojoseph@gmail.com',
              whatsapp: '+2290146283329',
              linkedin: '',
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 20),
            _buildDeveloperSection(
              name: 'DOSSOU',
              surname: 'Maresse',
              role: 'Participant',
              description:
                  "Étudiant  en deuxième année de Froid et Climatisation  à l'ENSGEP",
              imagePath: 'assets/menbre/maresse.jpg',
              email: 'maressedossou84@gmail.com',
              whatsapp: '+2290169436407',
              linkedin: ' www.linkedin.com/in/maresse-dossou-a971ba363',
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 20),
            _buildDeveloperSection(
              name: 'MAKIE',
              surname: 'Daniel',
              role: 'Participant',
              description:
                  "Étudiant  en deuxième année de Froid et Climatisation  à l'ENSGEP",
              imagePath: 'assets/menbre/daniel.png',
              email: 'mkedaniel04@gmail.com',
              whatsapp: '+2290151414430',
              linkedin:
                  ' https://www.linkedin.com/in/daniel-mke-196876247?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app ',
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 20),
            _buildDeveloperSection(
              name: 'HOUESSOU',
              surname: ' Faith ',
              role: 'Formateur',
              description: " Ingénieur en Génie Energétique et Procédés",
              imagePath: 'assets/menbre/faith.png',
              email: 'faith03houessou@gmail.com',
              whatsapp: '+2290161909361',
              linkedin: '',
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 20),
            _buildDeveloperSection(
              name: ' IDOHOU',
              surname: 'Cyrus',
              role: 'Chargé de communication',
              description: " Étudiant en Génie Énergétique et Procédés",
              imagePath: 'assets/menbre/cyrus.jpg',
              email: 'cyrusidohou942@gmail.com',
              whatsapp: '+2290154736660',
              linkedin:
                  ' https://www.linkedin.com/in/cyrus-idohou-2a8834370?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app ',
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 20),
            _buildDeveloperSection(
              name: 'SETO',
              surname: 'Comlan Crépin',
              role: 'Participant',
              description:
                  'Étudiant en deuxième année des Classes préparatoires à INSPEI ',
              imagePath: 'assets/menbre/crepin.jpg',
              email: 'crepinseto3@gmail.com',
              whatsapp: '+2290161706743',
              linkedin: '',
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

Widget _buildGlassCard({
  required IconData icon,
  required String title,
  required Widget child,
  Color iconColor = const Color(0xFF1E3C72),
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1E3C72).withOpacity(0.08),
          blurRadius: 15,
          spreadRadius: 1,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.grey.withOpacity(0.05),
          blurRadius: 5,
          spreadRadius: 1,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header stylisé
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                iconColor,
                iconColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Contenu
        Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    ),
  );
}

Widget _buildDeveloperSection({
  required String name,
  required String surname,
  required String role,
  required String description,
  required String imagePath,
  required String email,
  required String whatsapp,
  required String linkedin,
  required bool isDarkMode,
}) {
  return _buildGlassCard(
    icon: Icons.person_outline,
    title: role,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Column(
          children: [
            const SizedBox(height: 8),
            // Photo et informations en colonne pour les petits écrans
            if (isSmallScreen) ...[
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$name ',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3C72),
                          ),
                        ),
                        TextSpan(
                          text: surname,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3C72).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF1E3C72).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E3C72),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Layout pour les grands écrans (tablettes)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Colonne de gauche - Photo
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Colonne de droite - Informations
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$name ',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E3C72),
                                      ),
                                    ),
                                    TextSpan(
                                      text: surname,
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF1E3C72).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFF1E3C72)
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  description,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1E3C72),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Contact cards
            Column(
              children: [
                _buildContactCard(
                  icon: Icons.email_outlined,
                  title: 'Email Professionnel',
                  value: email,
                  onTap: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: email,
                    );
                    if (await canLaunchUrl(emailLaunchUri)) {
                      await launchUrl(emailLaunchUri);
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  icon: Icons.phone_android_rounded,
                  title: 'Contact WhatsApp',
                  value: whatsapp,
                  onTap: () async {
                    final Uri whatsappUri =
                        Uri.parse('https://wa.me/$whatsapp');
                    if (await canLaunchUrl(whatsappUri)) {
                      await launchUrl(whatsappUri);
                    }
                  },
                  iconColor: const Color(0xFF25D366),
                ),
                const SizedBox(height: 12),
                _buildContactCard(
                  icon: Icons.link,
                  title: 'LinkedIn',
                  value: linkedin,
                  onTap: () async {
                    final Uri linkedinUri = Uri.parse('https://$linkedin');
                    if (await canLaunchUrl(linkedinUri)) {
                      await launchUrl(linkedinUri);
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildContactCard({
  required IconData icon,
  required String title,
  required String value,
  required VoidCallback onTap,
  Color iconColor = const Color(0xFF1E3C72),
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    ),
  );
}
