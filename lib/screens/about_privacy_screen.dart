import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AboutPrivacyScreen extends StatefulWidget {
  const AboutPrivacyScreen({super.key});

  @override
  State<AboutPrivacyScreen> createState() => _AboutPrivacyScreenState();
}

class _AboutPrivacyScreenState extends State<AboutPrivacyScreen> {
  String _appVersion = 'Loading...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.7';
        _buildNumber = '6';
      });
    }
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://temphist.com/privacy';
    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy URL to clipboard
        await Clipboard.setData(const ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Privacy policy URL copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback: copy URL to clipboard
      await Clipboard.setData(const ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy policy URL copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          SizedBox.expand(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF242456), // kBackgroundColour
                    Color(0xFF343499), // kBackgroundColourDark
                  ],
                ),
              ),
            ),
          ),
          // Content
          Column(
            children: [
              // Custom app bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Privacy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App logo and name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            'assets/logo.svg',
                            width: 40,
                            height: 40,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TempHist',
                                style: TextStyle(
                                  color: Color(0xFFFF6B6B), // kAccentColour
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Version $_appVersion (Build $_buildNumber)',
                                style: const TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Privacy title
                      const Text(
                        'Privacy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      const Text(
                        'TempHist respects your privacy and operates with minimal data collection:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Privacy bullet points
                      _buildPrivacyBullet(
                        'No personal data collected',
                        'TempHist does not collect, store, or share any personal information.',
                      ),
                      
                      _buildPrivacyBullet(
                        'Location use',
                        'If you grant permission, the app uses your current location once to retrieve historical weather data for your area. Location data is never stored or shared.',
                      ),
                      
                      _buildPrivacyBullet(
                        'No tracking or analytics',
                        'The app does not include analytics, advertising, or third-party tracking.',
                      ),
                      
                      _buildPrivacyBullet(
                        'Anonymous data processing',
                        'Weather and climate data are provided via the TempHist API, which sources historical weather data from trusted providers. Requests are processed anonymously.',
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Full privacy policy button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _openPrivacyPolicy,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B), // kAccentColour
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Open Full Privacy Policy',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Contact information
                      const Center(
                        child: Text(
                          'Questions? Contact Turnpiece Ltd. at turnpiece.com',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBullet(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet point
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '• ',
              style: const TextStyle(
                color: Color(0xFF51CF66), // kSummaryColour
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF51CF66), // kSummaryColour
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
