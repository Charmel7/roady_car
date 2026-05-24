import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roady_car/ThemeProvider.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    bool isSwitched = true;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Text(
          'Paramètres',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'PRÉFÉRENCES'),
          _buildSettingItem(
            context,
            icon: Icons.language_rounded,
            title: 'Langue',
            subtitle: 'Choisir la langue de l\'application',
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context,
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Gérer les paramètres de notification',
            trailing: const Icon(Icons.arrow_forward_ios_outlined),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context,
            icon: Icons.volume_off_outlined,
            title: 'Son',
            subtitle: 'Désactiver le son',
            trailing: Switch(
              activeColor: theme.colorScheme.primary,
              value: isSwitched,
              onChanged: (value) {},
            ),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context,
            icon: Icons.dark_mode_rounded,
            title: 'Thème sombre',
            subtitle: 'Activer ou désactiver le thème sombre',
            trailing: Switch(
              activeColor: theme.colorScheme.primary,
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'CAPTEURS'),
          _buildSettingItem(
            context,
            icon: Icons.gps_not_fixed_outlined,
            title: 'Gyroscope',
            subtitle: 'Désactiver le gyroscope',
            trailing: Switch(
              activeColor: theme.colorScheme.primary,
              value: isSwitched,
              onChanged: (value) {},
            ),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context,
            icon: Icons.solar_power_outlined,
            title: 'Température et humidité',
            subtitle: 'Désactiver le thermomètre',
            trailing: Switch(
              activeColor: theme.colorScheme.primary,
              value: isSwitched,
              onChanged: (value) {},
            ),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            context,
            icon: Icons.surround_sound,
            title: 'Ultrason',
            subtitle: 'Désactiver le capteur ultrason',
            trailing: Switch(
              activeColor: theme.colorScheme.primary,
              value: isSwitched,
              onChanged: (value) {},
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Visualiser les courbes ici',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Copyright ElectroDeclic',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: trailing,
      onTap: () {},
      hoverColor: theme.colorScheme.primary.withOpacity(0.05),
    );
  }
}
