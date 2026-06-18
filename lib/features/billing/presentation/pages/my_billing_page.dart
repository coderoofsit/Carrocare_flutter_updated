import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/utils/invoice_download_helper.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_divider.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/billing/domain/entities/billing_item.dart';
import 'package:carrocare_flutter/features/billing/presentation/bloc/my_billing_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyBillingPage extends StatefulWidget {
  const MyBillingPage({super.key});

  @override
  State<MyBillingPage> createState() => _MyBillingPageState();
}

class _MyBillingPageState extends State<MyBillingPage> {
  final InvoiceDownloadHelper _downloadHelper = InvoiceDownloadHelper();

  @override
  void initState() {
    super.initState();
    _loadBillings();
  }

  Future<void> _loadBillings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final customerId = prefs.getString('customer_id') ?? '';
    if (!mounted) return;
    if (token.isEmpty || customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session missing. Please login again.')),
      );
      context.go('/login');
      return;
    }
    context.read<MyBillingBloc>().add(
          MyBillingRequested(token: token, customerId: customerId),
        );
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  Future<void> _downloadInvoice(BillingItem item) async {
    await _downloadHelper.downloadAndOpen(
      context: context,
      downloadUrl: item.downloadInvoice,
      fileName: 'Carrocare_Invoice_${item.razorpayPaymentId}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: CarroCareScaffold(
        title: 'My Billings',
        onBack: _onBack,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadBillings,
          child: BlocConsumer<MyBillingBloc, MyBillingState>(
            listener: (context, state) {
              if (state is MyBillingFailure &&
                  state.message.contains('Session expired')) {
                context.go('/login');
              }
            },
            builder: (context, state) {
              if (state is MyBillingLoading || state is MyBillingInitial) {
                return const Center(child: CarroCareLoadingOverlay());
              }
              if (state is MyBillingFailure) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: <Widget>[
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: <Widget>[
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: AppTypography.dmSans(
                              fontSize: 16,
                              color: AppColors.grey700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadBillings,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final billings = (state as MyBillingLoaded).billings;
              if (billings.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: <Widget>[
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                    Center(
                      child: Image.asset(
                        'assets/images/placeholders.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: billings.length,
                itemBuilder: (context, index) {
                  return _BillingCard(
                    item: billings[index],
                    onDownload: () => _downloadInvoice(billings[index]),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BillingCard extends StatelessWidget {
  const _BillingCard({
    required this.item,
    required this.onDownload,
  });

  final BillingItem item;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: AppDecorations.card(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Invoice',
                    style: AppTypography.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  const DottedDivider(margin: EdgeInsets.symmetric(vertical: 8)),
                  _row('Invoice No', item.invoice),
                  const SizedBox(height: 6),
                  _row('Date', item.date),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDownload,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(
                  'assets/vectors/ic_download.svg',
                  width: 32,
                  height: 32,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: AppTypography.dmSans(
              fontSize: 13,
              color: AppColors.grey500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.grey800,
            ),
          ),
        ),
      ],
    );
  }
}
