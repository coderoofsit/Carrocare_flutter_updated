import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/support/data/datasources/help_remote_data_source.dart';
import 'package:carrocare_flutter/features/support/presentation/constants/help_topics.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/profile_subpage_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HelpAndSupportPage extends StatefulWidget {
  const HelpAndSupportPage({super.key});

  @override
  State<HelpAndSupportPage> createState() => _HelpAndSupportPageState();
}

class _HelpAndSupportPageState extends State<HelpAndSupportPage> {
  final HelpRemoteDataSource _dataSource =
      HelpRemoteDataSource(sl<ApiClient>());
  int? _expandedIndex;
  final Map<int, TextEditingController> _controllers = <int, TextEditingController>{};
  bool _submitting = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(String title, String message) async {
    if (message.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your message')),
      );
      return;
    }
    setState(() => _submitting = true);
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = await _dataSource.submitHelp(
        type: title,
        question: message.trim(),
        customerId: prefs.getString('customer_id') ?? '',
        token: prefs.getString('token') ?? '',
      );
      if (!mounted) return;
      final code = (data['code'] ?? '').toString();
      final text = (data['message'] ?? data['result'] ?? 'Submitted').toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
      if (code == '200') {
        setState(() => _expandedIndex = null);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timeout.Try after sometime')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubpageScaffold(
      title: 'HELP AND SUPPORT',
      onBack: () => context.pop(),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              color: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                leading: const Icon(Icons.report_problem, color: Colors.white, size: 28),
                title: const Text(
                  'Need to lodge a complaint?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Click here to register & track your complaints',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                onTap: () => context.push('/complaint'),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: kHelpTopics.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFBDBDBD)),
              itemBuilder: (context, index) {
                final title = kHelpTopics[index];
                final expanded = _expandedIndex == index;
                _controllers.putIfAbsent(index, TextEditingController.new);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedIndex = expanded ? null : index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/vectors/ic_baseline_arrow_forward_ios_24.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                AppColors.black,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (expanded) ...<Widget>[
                      TextField(
                        controller: _controllers[index],
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Type here....',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed: _submitting
                              ? null
                              : () => _submit(title, _controllers[index]!.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(120, 40),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text('Submit'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
