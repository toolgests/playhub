import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _sendEmail(BuildContext context, String email, {String subject = ''}) async {
    final uri = Uri.parse(
      'mailto:$email${subject.isNotEmpty ? '?subject=${Uri.encodeComponent(subject)}' : ''}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contact email: $email')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contact email: $email')),
      );
    }
  }

  Future<void> _launchWebUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Custom Top App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'PRIVACY POLICY',
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Contact Us',
                      icon: const Icon(Icons.mail_outline_rounded,
                          color: AppColors.cyan),
                      onPressed: () => _sendEmail(
                        context,
                        'eagledigitalworks@gmail.com',
                        subject: 'PlayHub Privacy Query',
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Policy Content
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 32),
                  children: [
                    // Overview Glass Header
                    GlassContainer(
                      radius: 20,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.verified_user_rounded,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PlayHub Privacy Policy',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Effective date: 01/11/2026',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.cyan,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _infoRow('Developer', 'EagleDevTeam'),
                          const SizedBox(height: 6),
                          _infoRow('Compliance', 'India DPDP Act, 2023'),
                          const SizedBox(height: 6),
                          _infoRow('Grievance Officer', 'SR ECOM ENTERPRISE'),
                          const SizedBox(height: 6),
                          _infoRow('Contact', 'eagledigitalworks@gmail.com'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 1
                    _PolicyCard(
                      number: '1',
                      title: 'Who we are and what this policy covers',
                      content:
                          'This Privacy Policy explains how EagleDevTeam ("we", "us", "our") handles information when you use the PlayHub mobile app ("PlayHub" or "the app").\n\n'
                          'PlayHub lets anyone play HTML5 games without creating an account. There is no login or sign-in, and we never ask for your name, email address or phone number.\n\n'
                          'We are the Data Fiduciary for personal data processed through PlayHub under India\'s Digital Personal Data Protection Act, 2023 ("DPDP Act"). If you use PlayHub from another country, we also follow the privacy laws that apply to you there.\n\n'
                          'Where we rely on your consent, for example for personalised ads, we ask for it clearly inside the app. You can withdraw consent at any time, as explained in section 7.',
                    ),
                    const SizedBox(height: 14),

                    // Section 2
                    _PolicyCard(
                      number: '2',
                      title: 'Information we collect',
                      content:
                          'PlayHub works without an account, so we collect very little, and none of it is your name, email or phone number.\n\n'
                          '• Information collected automatically:\n'
                          '  - Device and app data: device model, Android version, app version, language, time zone and a random app installation ID.\n'
                          '  - Usage data: the games you open, how long you play and the screens you visit, so we can improve the catalog and fix problems.\n'
                          '  - Advertising ID: your Android Advertising ID, used by our ad partner to show and measure ads. You can reset it or turn off personalised ads in your device settings.\n'
                          '  - Diagnostics: crash reports and performance data.\n'
                          '  - Approximate location: your country or region, worked out from your IP address, to show suitable games and ads. We do not collect your precise GPS location.\n\n'
                          '• Information stored only on your phone:\n'
                          '  Your favorite games, recently played games and app settings are saved on your phone, not on our servers. They are removed when you clear the app\'s data or uninstall the app.\n\n'
                          '• Information you choose to send us:\n'
                          '  If you email us for support, we receive your email address and whatever you write, and use it only to reply.\n\n'
                          'We do not collect contacts, photos, SMS messages, precise location or payment details, and we do not ask for permissions the app does not need.',
                    ),
                    const SizedBox(height: 14),

                    // Section 3
                    _PolicyCard(
                      number: '3',
                      title: 'How we use information',
                      content:
                          'We use information only for specific, lawful purposes. If we want to use it for something new, we will ask first.',
                      customChild: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            _usageTile(
                              purpose: 'Run the app: load catalog & games',
                              dataUsed: 'Device and app data',
                              basis: 'To provide the service you use',
                            ),
                            const SizedBox(height: 8),
                            _usageTile(
                              purpose: 'Show ads and measure them',
                              dataUsed: 'Advertising ID, device data, approx. location',
                              basis: 'Consent (personalised ads); Legitimate use (non-personalised)',
                            ),
                            const SizedBox(height: 8),
                            _usageTile(
                              purpose: 'Improve the app and fix crashes',
                              dataUsed: 'Usage data, diagnostics',
                              basis: 'Consent',
                            ),
                            const SizedBox(height: 8),
                            _usageTile(
                              purpose: 'Keep app secure & stop abuse',
                              dataUsed: 'Device data, IP address',
                              basis: 'Legitimate use',
                            ),
                            const SizedBox(height: 8),
                            _usageTile(
                              purpose: 'Reply to support emails',
                              dataUsed: 'Your email and message',
                              basis: 'Consent',
                            ),
                            const SizedBox(height: 8),
                            _usageTile(
                              purpose: 'Meet legal duties',
                              dataUsed: 'Any of the above, only as required',
                              basis: 'Legal obligation',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 4
                    _PolicyCard(
                      number: '4',
                      title: 'Third-party games, ads and services',
                      content:
                          'PlayHub uses trusted partners for its games, ads and app services. Each partner handles data under its own privacy policy.\n\n'
                          '• Games: The HTML5 games in PlayHub come from Playgama (LeadToChanges L.L.C-FZ, Dubai, UAE) and their game developers. Games load inside the app, and the game provider may use cookies or similar technology to run the game, save progress, measure play and show ads inside the game.\n\n'
                          '• Advertising: We show ads through Google AdMob. Ad partners may collect your Advertising ID, device data and approximate location to show and measure ads.\n\n'
                          '• App services: We use Firebase (Google) to deliver notifications, dynamic configuration, analytics and crash reports.\n\n'
                          'Links to other websites or services are covered by their own privacy policies.',
                      customChild: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.sports_esports_rounded, size: 16),
                              label: const Text('Playgama Privacy Policy'),
                              onPressed: () =>
                                  _launchWebUrl('https://playgama.com/confidential'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.security_rounded, size: 16),
                              label: const Text('Google Privacy Policy'),
                              onPressed: () =>
                                  _launchWebUrl('https://policies.google.com/privacy'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 5
                    _PolicyCard(
                      number: '5',
                      title: 'How we share information',
                      content:
                          'We do not sell your information. We share it only with:\n\n'
                          '• Service providers that help us run PlayHub (hosting, analytics, crash reporting), under contracts that limit how they use it.\n'
                          '• Game and ad partners, as described in section 4.\n'
                          '• Authorities, when the law, a court or a government body requires it, or to protect PlayHub, its users or the public from fraud or harm.\n'
                          '• A new owner, if PlayHub is merged, sold or transferred. They must follow this policy or tell you about changes.\n\n'
                          'We may share combined or anonymous reports that cannot identify you, for example total plays per game.',
                    ),
                    const SizedBox(height: 14),

                    // Section 6
                    _PolicyCard(
                      number: '6',
                      title: 'How long we keep data and how to delete it',
                      content:
                          'We keep information only as long as we need it:\n'
                          '• Usage data and diagnostics: up to 14 months, then deleted or made anonymous.\n'
                          '• Support emails: up to 12 months after your issue is closed.\n'
                          '• Data on your phone: until you clear the app\'s data or uninstall the app.\n\n'
                          'Because there are no accounts, you are always in control:\n'
                          '• Clear your data: go to Android Settings > Apps > PlayHub > Storage > Clear data, or uninstall the app.\n'
                          '• Stop ad tracking: reset or delete your Advertising ID in Android settings.\n'
                          '• Ask us to delete the rest: email eagledigitalworks@gmail.com with the subject "Delete my data". We will delete what we can link to your request within 30 days.',
                    ),
                    const SizedBox(height: 14),

                    // Section 7
                    _PolicyCard(
                      number: '7',
                      title: 'Your rights and choices',
                      content:
                          'Under India\'s DPDP Act and other laws that apply to you, you can:\n\n'
                          '• Know what information we hold about you and how we use it.\n'
                          '• Get a copy, correct or erase information we hold about you.\n'
                          '• Withdraw consent at any time, for example for personalised ads.\n'
                          '• Nominate another person to use these rights for you if you die or cannot act.\n'
                          '• Raise a grievance with our Grievance Officer and, if you are not satisfied, complain to the Data Protection Board of India.\n\n'
                          'To use these rights, email eagledigitalworks@gmail.com. Since PlayHub has no accounts, we may ask for your app installation ID (shown in Settings > About) to find your data. We reply within 30 days.\n\n'
                          'Other choices:\n'
                          '• Ads: Turn off personalised ads in the app, or reset your Advertising ID in Android settings.\n'
                          '• Notifications: Turn them off in Android settings.\n'
                          '• Grievance Officer: SR ECOM ENTERPRISE',
                    ),
                    const SizedBox(height: 14),

                    // Section 8
                    _PolicyCard(
                      number: '8',
                      title: 'Children',
                      content:
                          'PlayHub is a general audience app that anyone can open without signing in. We do not knowingly collect personal information from children, and we never ask for a child\'s name or contact details.\n\n'
                          'We do not show personalised ads to users we know are under 18. If you are a parent and believe your child has sent us personal information, email eagledigitalworks@gmail.com and we will delete it.',
                    ),
                    const SizedBox(height: 14),

                    // Section 9
                    _PolicyCard(
                      number: '9',
                      title: 'Security',
                      content:
                          'We protect information with encryption in transit (HTTPS), access controls and secure cloud services. No system is completely secure, but because PlayHub has no accounts or passwords, there is very little personal information to expose.\n\n'
                          'If a data breach affects your personal information, we will tell you and the Data Protection Board of India without delay, as the law requires.',
                    ),
                    const SizedBox(height: 14),

                    // Section 10
                    _PolicyCard(
                      number: '10',
                      title: 'Data stored outside India',
                      content:
                          'Our partners may store or process data on servers outside India, for example in the countries where Google, Playgama or our ad partners operate. We only transfer data where the law allows it, and our partners must protect it to the standard in this policy.',
                    ),
                    const SizedBox(height: 14),

                    // Section 11
                    _PolicyCard(
                      number: '11',
                      title: 'Changes to this policy',
                      content:
                          'We may update this policy when PlayHub or the law changes. We will change the effective date at the top. For important changes, such as a new purpose for your data, we will show a notice in the app before the change takes effect.',
                    ),
                    const SizedBox(height: 14),

                    // Section 12
                    _PolicyCard(
                      number: '12',
                      title: 'Contact us',
                      content:
                          'If you have questions about this Privacy Policy or your data, please contact us:\n\n'
                          'Developer: EagleDevTeam\n'
                          'Email: eagledigitalworks@gmail.com\n'
                          'Grievance Officer: SR ECOM ENTERPRISE',
                      customChild: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.email_rounded, size: 18),
                          label: const Text('Email eagledigitalworks@gmail.com'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cyan,
                            side: const BorderSide(color: AppColors.cyan),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _sendEmail(
                            context,
                            'eagledigitalworks@gmail.com',
                            subject: 'PlayHub Privacy Inquiry',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _usageTile({
    required String purpose,
    required String dataUsed,
    required String basis,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.violet.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            purpose,
            style: const TextStyle(
              color: AppColors.cyan,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data: $dataUsed',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Legal Basis: $basis',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.number,
    required this.title,
    required this.content,
    this.customChild,
  });

  final String number;
  final String title;
  final String content;
  final Widget? customChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      radius: 18,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
          if (customChild != null) customChild!,
        ],
      ),
    );
  }
}

