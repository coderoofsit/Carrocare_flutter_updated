import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:flutter/material.dart';

/// Red header + gradient body shell used on profile sub-screens.
class ProfileSubpageScaffold extends StatelessWidget {
  const ProfileSubpageScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.body,
    this.footer,
  });

  final String title;
  final VoidCallback onBack;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: title,
      onBack: onBack,
      footer: footer,
      body: body,
    );
  }
}
