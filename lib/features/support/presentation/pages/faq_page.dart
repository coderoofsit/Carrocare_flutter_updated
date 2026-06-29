import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/features/support/presentation/constants/faq_content.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/content_section_header.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/faq_accordion_tile.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/profile_subpage_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  int? _expandedIndex;

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
      title: 'FAQ',
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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const ContentSectionHeader(title: 'FAQ'),
                const SizedBox(height: 20),
                Text(
                  'General Questions',
                  style: AppTypography.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: 14),
                ...List<Widget>.generate(kGeneralFaqItems.length, (index) {
                  final item = kGeneralFaqItems[index];
                  return FaqAccordionTile(
                    item: item,
                    expanded: _expandedIndex == index,
                    onTap: () {
                      setState(() {
                        _expandedIndex = _expandedIndex == index ? null : index;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
