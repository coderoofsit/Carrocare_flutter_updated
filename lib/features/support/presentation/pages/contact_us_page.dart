import 'package:carrocare_flutter/core/constants/app_urls.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/profile_subpage_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  static const String _address =
      'No 65, veleeshwarar nagar,\nMangadu,\nChennai, Tamil Nadu 600122';
  static const String _phone = '7904015630';
  static const String _email = 'info@carrocare.com';

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/main-profile');
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
      'https://api.whatsapp.com/send?phone=${AppUrls.whatsAppNumber}&text=${Uri.encodeComponent(AppUrls.whatsAppMessage)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Whatsapp not installed.')),
    );
  }

  Future<void> _openDeveloperSite() async {
    final uri = Uri.parse(AppUrls.muviereck);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubpageScaffold(
      title: 'Contact Us',
      onBack: () => _onBack(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: <Widget>[
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'If you have any questions simply use the following contact details',
                      style: TextStyle(fontSize: 16, color: AppColors.black),
                    ),
                    const SizedBox(height: 16),
                    _ContactRow(
                      icon: Icons.location_on_outlined,
                      title: 'ADDRESS',
                      value: _address,
                    ),
                    const SizedBox(height: 12),
                    _ContactRow(
                      iconAsset: 'assets/images/phone.png',
                      title: 'PHONE',
                      value: _phone,
                    ),
                    const SizedBox(height: 12),
                    _ContactRow(
                      iconAsset: 'assets/images/email.png',
                      title: 'EMAIL',
                      value: _email,
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              child: InkWell(
                onTap: () => _openWhatsApp(context),
                borderRadius: BorderRadius.circular(9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: <Widget>[
                      SvgPicture.asset(
                        'assets/vectors/ic_whatsapp.svg',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Send Message',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: _openDeveloperSite,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    Text(
                      'App developed by',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.black),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Muviereck Technologies Pvt. Ltd',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.title,
    required this.value,
    this.icon,
    this.iconAsset,
  });

  final String title;
  final String value;
  final IconData? icon;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Card(
          color: AppColors.primary,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: iconAsset != null
                ? Image.asset(
                    iconAsset!,
                    width: 30,
                    height: 30,
                    color: AppColors.white,
                    colorBlendMode: BlendMode.srcIn,
                  )
                : Icon(icon, color: AppColors.white, size: 30),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
