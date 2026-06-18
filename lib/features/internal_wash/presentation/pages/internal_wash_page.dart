import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/internal_wash/domain/entities/internal_wash_form.dart';
import 'package:carrocare_flutter/features/internal_wash/presentation/constants/preferred_time_slots.dart';
import 'package:carrocare_flutter/features/internal_wash/presentation/widgets/internal_wash_field.dart';
import 'package:carrocare_flutter/features/internal_wash/presentation/widgets/preferred_time_sheet.dart';
import 'package:carrocare_flutter/features/orders/domain/repositories/orders_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InternalWashArgs {
  const InternalWashArgs({
    required this.orderId,
    required this.vehicleId,
    required this.vehicleMake,
    required this.vehicleModel,
  });

  final String orderId;
  final String vehicleId;
  final String vehicleMake;
  final String vehicleModel;
}

class InternalWashPage extends StatefulWidget {
  const InternalWashPage({super.key, required this.args});

  final InternalWashArgs args;

  @override
  State<InternalWashPage> createState() => _InternalWashPageState();
}

class _InternalWashPageState extends State<InternalWashPage> {
  final OrdersRepository _repository = sl<OrdersRepository>();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  InternalWashForm? _form;

  String _date1 = '';
  String _time1 = '';
  String _date2 = '';
  String _time2 = '';
  final TextEditingController _comment1 = TextEditingController();
  final TextEditingController _comment2 = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment1.dispose();
    _comment2.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    try {
      final form = await _repository.getInternalWashForm(
        token: prefs.getString('token') ?? '',
        customerId: prefs.getString('customer_id') ?? '',
        vehicleId: widget.args.vehicleId,
        orderId: widget.args.orderId,
      );
      if (!mounted) return;
      setState(() {
        _form = form;
        _date1 = form.scheduleDate1;
        _time1 = form.scheduleTime1;
        _date2 = form.scheduleDate2;
        _time2 = form.scheduleTime2;
        _comment1.text = form.comment1;
        _comment2.text = form.comment2;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickDate({required bool isSecond}) async {
    final editable = isSecond ? _form?.date2Editable : _form?.date1Editable;
    if (editable != true) {
      _toast('Not editable');
      return;
    }
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    final formatted = DateFormat('yyyy-MM-dd').format(picked);
    setState(() {
      if (isSecond) {
        _date2 = formatted;
      } else {
        _date1 = formatted;
      }
    });
  }

  Future<void> _pickTime({required bool isSecond}) async {
    final editable = isSecond ? _form?.date2Editable : _form?.date1Editable;
    if (editable != true) {
      _toast('Not editable');
      return;
    }
    final date = isSecond ? _date2 : _date1;
    if (date.isEmpty) {
      _toast('Choose Preferred Schedule');
      return;
    }
    final slot = await showPreferredTimeSheet(
      context,
      kInternalWashPreferredTimes,
    );
    if (slot == null) return;
    setState(() {
      if (isSecond) {
        _time2 = slot;
      } else {
        _time1 = slot;
      }
    });
  }

  Future<void> _submit() async {
    final form = _form;
    if (form == null) return;

    if (form.scheduleDate1.isEmpty) {
      if (_date1.isEmpty || _time1.isEmpty) {
        _toast('Choose Date and Time');
        return;
      }
    } else if (form.scheduleDate2.isEmpty) {
      if (_date2.isEmpty || _time2.isEmpty) {
        _toast('Choose Date and Time');
        return;
      }
    }

    setState(() => _submitting = true);
    final prefs = await SharedPreferences.getInstance();
    try {
      final message = await _repository.scheduleInternalCleanNew(
        token: prefs.getString('token') ?? '',
        customerId: prefs.getString('customer_id') ?? '',
        vehicleId: widget.args.vehicleId,
        orderId: widget.args.orderId,
        scheduleDate1: _date1,
        scheduleTime1: _time1,
        comment1: _comment1.text.trim(),
        scheduleDate2: _date2,
        scheduleTime2: _time2,
        comment2: _comment2.text.trim(),
        id: form.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final orderInfo =
        'Order Id : ${widget.args.orderId}\n\nVehicle Id : ${widget.args.vehicleId}';
    final vehicleInfo =
        'Vehicle Make : ${widget.args.vehicleMake}\n\nVechicle Model : ${widget.args.vehicleModel}';

    return CarroCareScaffold(
      title: 'Internal Clean',
      onBack: () => context.pop(),
      body: _loading
          ? const CarroCareLoadingOverlay()
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      InternalWashField(
                        value: orderInfo,
                        hint: 'Order Id',
                        maxLines: 3,
                      ),
                      InternalWashField(
                        value: vehicleInfo,
                        hint: 'Vehicle id',
                        maxLines: 3,
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Text(
                          'Internal Wash 1',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      InternalWashCalendarField(
                        value: _date1,
                        onTap: () => _pickDate(isSecond: false),
                      ),
                      InternalWashArrowField(
                        value: _time1,
                        hint: 'Preferred Time',
                        onTap: () => _pickTime(isSecond: false),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: TextField(
                          controller: _comment1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Type Message here',
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Text(
                          'Internal Wash 2',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      InternalWashCalendarField(
                        value: _date2,
                        onTap: () => _pickDate(isSecond: true),
                      ),
                      InternalWashArrowField(
                        value: _time2,
                        hint: 'Preferred Time',
                        onTap: () => _pickTime(isSecond: true),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: TextField(
                          controller: _comment2,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Type Message here',
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(50, 10, 50, 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Text(
                                    'SUBMIT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
