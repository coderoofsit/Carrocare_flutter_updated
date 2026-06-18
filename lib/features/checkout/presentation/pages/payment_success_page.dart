import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_app_bar.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/checkout/presentation/services/checkout_navigation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({super.key});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  bool _showContent = false;
  bool _navigatingToOrders = false;

  @override
  void initState() {
    super.initState();
    _prepareSuccessScreen();
  }

  Future<void> _prepareSuccessScreen() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _showContent = true);
  }

  void _onContinue() {
    if (_navigatingToOrders) return;
    setState(() => _navigatingToOrders = true);
    goToMyOrders(GoRouter.of(context));
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: _showContent ? 'Payment Successful' : 'Processing',
      leading: CarroCareAppBarLeading.none,
      body: Stack(
        children: <Widget>[
          if (_showContent)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 120,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Congratulations !!!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Payment\nis successfully done.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigatingToOrders ? null : _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!_showContent)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CarroCareLoadingOverlay(),
                  SizedBox(height: 16),
                  Text(
                    'Confirming your payment...',
                    style: TextStyle(
                      color: AppColors.grey600,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (_navigatingToOrders)
            const ColoredBox(
              color: Color(0x88000000),
              child: CarroCareLoadingOverlay(),
            ),
        ],
      ),
    );
  }
}
