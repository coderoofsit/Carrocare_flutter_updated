import 'package:carrocare_flutter/core/constants/app_urls.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/support/domain/entities/content_web_args.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/profile_subpage_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ContentWebviewPage extends StatefulWidget {
  const ContentWebviewPage({super.key, required this.args});

  final ContentWebArgs args;

  @override
  State<ContentWebviewPage> createState() => _ContentWebviewPageState();
}

class _ContentWebviewPageState extends State<ContentWebviewPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.args.url));
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/main-profile');
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
      title: widget.args.title,
      onBack: _onBack,
      footer: GestureDetector(
        onTap: _openDeveloperSite,
        child: Container(
          width: double.infinity,
          color: const Color(0xFFEDEFF1),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: <Widget>[
              const Text(
                'App developed by',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.black),
              ),
              const SizedBox(height: 4),
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
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8),
            child: WebViewWidget(controller: _controller),
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
