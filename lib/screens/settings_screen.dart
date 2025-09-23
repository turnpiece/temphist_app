import 'package:flutter/material.dart';
import '../constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColour,
      appBar: AppBar(
        backgroundColor: kBackgroundColour,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColour),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: kTextColour,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('About'),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About TempHist',
            subtitle: 'Version 1.0.0',
            onTap: () {
              // TODO: Navigate to about screen
            },
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () {
              // TODO: Navigate to privacy screen
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Data'),
          _buildSettingsTile(
            icon: Icons.storage,
            title: 'Clear Cache',
            subtitle: 'Remove all cached data',
            onTap: () {
              // TODO: Implement cache clearing
            },
          ),
          _buildSettingsTile(
            icon: Icons.location_off,
            title: 'Clear Locations',
            subtitle: 'Remove all visited locations',
            onTap: () {
              // TODO: Implement location clearing
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help using the app',
            onTap: () {
              // TODO: Navigate to help screen
            },
          ),
          _buildSettingsTile(
            icon: Icons.bug_report_outlined,
            title: 'Report Bug',
            subtitle: 'Report an issue',
            onTap: () {
              // TODO: Navigate to bug report
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: kTextColour.withOpacity(0.7),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kCardColour,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kTextColour.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: kTextColour.withOpacity(0.7),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: kTextColour,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: kTextColour.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: kTextColour,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }
}
