import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/content_section_header.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/profile_subpage_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const String _paragraphOne =
      'Carro Care is a professional car washing and service in chennai. We are making sure your car is cleaned how you like it. In addition to our car wash services, We have express detail services for the outside as well as the inside of the car.';
  static const String _paragraphTwo =
      'Easy way to wash a car, Select service, Fix a time, Mention a Location and our team will be in your location is simplified with our mobile app. We believe in making customer satisfaction.';

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/main-profile');
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubpageScaffold(
      title: 'About Us',
      onBack: () => _onBack(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Card(
          elevation: 2,
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.grey200),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const ContentSectionHeader(title: 'ABOUT COMPANY'),
                const SizedBox(height: 18),
                Text(
                  _paragraphOne,
                  style: AppTypography.dmSans(
                    fontSize: 15,
                    color: AppColors.grey700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _paragraphTwo,
                  style: AppTypography.dmSans(
                    fontSize: 15,
                    color: AppColors.grey700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                const _FeatureGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  static const List<_FeatureData> _features = <_FeatureData>[
    _FeatureData(
      icon: Icons.settings_outlined,
      title: "WE'RE EXPERTS",
      description: 'We are experts in car washing',
    ),
    _FeatureData(
      icon: Icons.person_outline,
      title: "WE'RE FRIENDLY",
      description: 'We are very friendly when we approach our clients',
    ),
    _FeatureData(
      icon: Icons.directions_car_outlined,
      title: "WE'RE ACCURATE",
      description: 'We are accurate to provide services to clients',
    ),
    _FeatureData(
      icon: Icons.emoji_events_outlined,
      title: "WE'RE TRUSTED",
      description: 'We are very trusted workers for our clients',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 20,
          children: _features
              .map(
                (feature) => SizedBox(
                  width: itemWidth,
                  child: _FeatureBlock(feature: feature),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _FeatureData {
  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _FeatureBlock extends StatelessWidget {
  const _FeatureBlock({required this.feature});

  final _FeatureData feature;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          color: AppColors.grey700,
          alignment: Alignment.center,
          child: Icon(
            feature.icon,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          feature.title,
          style: AppTypography.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.grey800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          feature.description,
          style: AppTypography.dmSans(
            fontSize: 13,
            color: AppColors.grey600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
