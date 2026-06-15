import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/profile_subpage_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Matches Android [NotificationActivity] shell (list API was never wired).
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileSubpageScaffold(
      title: 'Notifications',
      onBack: () => context.pop(),
      body: const Center(
        child: Text(
          'No notifications',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
