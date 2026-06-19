import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_gradients.dart';
import 'package:flutter/material.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.overlay,
  });

  final Widget appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.homeBackground,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: <Widget>[
                  appBar,
                  Expanded(child: body),
                ],
              ),
            ),
          ),
          if (overlay != null) overlay!,
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
