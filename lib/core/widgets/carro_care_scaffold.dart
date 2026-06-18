import 'package:carrocare_flutter/core/theme/app_gradients.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_app_bar.dart';
import 'package:flutter/material.dart';

class CarroCareScaffold extends StatelessWidget {
  const CarroCareScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.leading = CarroCareAppBarLeading.back,
    this.actions = const <Widget>[],
    this.footer,
    this.appBarTransparent = false,
    this.showAppBarBorder = true,
    this.subtitle,
    this.floatingActionButton,
    this.backgroundDecoration,
  });

  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final CarroCareAppBarLeading leading;
  final List<Widget> actions;
  final Widget? footer;
  final bool appBarTransparent;
  final bool showAppBarBorder;
  final String? subtitle;
  final Widget? floatingActionButton;
  final Decoration? backgroundDecoration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration:
            backgroundDecoration ??
            const BoxDecoration(gradient: AppGradients.screenBackground),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              CarroCareAppBar(
                title: title,
                leading: leading,
                onLeadingTap: onBack,
                actions: actions,
                transparent: appBarTransparent,
                showBorder: showAppBarBorder,
                subtitle: subtitle,
              ),
              Expanded(child: body),
              if (footer != null) footer!,
            ],
          ),
        ),
      ),
    );
  }
}
