import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/utils/invoice_download_helper.dart';
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
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: _onBack,
                      child: Container(
                        width: 35,
                        height: 35,
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(5),
                        child: Image.asset('assets/images/back.png'),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'MY BILLINGS',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 45),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFEDEFF1),
                  child: RefreshIndicator(
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
                        if (state is MyBillingLoading ||
                            state is MyBillingInitial) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }
                        if (state is MyBillingFailure) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: <Widget>[
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.25,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      state.message,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadBillings,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.white,
                                      ),
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
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.2,
                              ),
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: billings.length,
                          itemBuilder: (context, index) {
                            return _BillingCard(
                              item: billings[index],
                              onDownload: () =>
                                  _downloadInvoice(billings[index]),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
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
    const labelStyle = TextStyle(
      color: Color(0xFF313030),
      fontSize: 16,
      fontWeight: FontWeight.w400,
    );
    const valueStyle = TextStyle(
      color: AppColors.black,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _row('Invoice No : ', item.invoice, labelStyle, valueStyle),
                  _row('Date : ', item.date, labelStyle, valueStyle),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDownload,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  'assets/vectors/ic_download.svg',
                  width: 50,
                  height: 50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: labelStyle),
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}
