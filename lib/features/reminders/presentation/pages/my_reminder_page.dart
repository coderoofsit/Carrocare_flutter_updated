import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/profile_subpage_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Matches Android [MyRemainderActivity] — local validation only, no API.
class MyReminderPage extends StatefulWidget {
  const MyReminderPage({super.key});

  @override
  State<MyReminderPage> createState() => _MyReminderPageState();
}

class _MyReminderPageState extends State<MyReminderPage> {
  static const Color _fieldBorder = Color(0xFF8F8F8F);
  static const Color _hintColor = Color(0xFF8F8F8F);

  static const List<String> _remainderTypes = <String>[
    'Services Remainder',
    'Bike/Car Insurance Remainder',
  ];
  static const List<String> _serviceCounts = <String>['1', '2', '3', '4', '5'];
  static const List<String> _setRemainder = <String>[
    '1 Month',
    '2 Weeks',
    '1 Week',
    '3 Days',
    '1 Day',
  ];
  static const List<String> _insuranceBrands = <String>[
    'Bajaj Allianz Car insurance',
    'Bharti axa Car insurance',
    'Cholamandalam Car insurance',
    'Digit Car Insurance',
    'Edelweiss Car Insurance',
    'Future Generali Car Insurance',
    'HDFC ERGO Car Insurance',
    'IFFCO Tokio Car Insurance',
    'Kotak Mahindra Car Insurance',
    'Liberty Car Insurance',
    'National Car Insurance',
    'New India Assurance Car Insurance',
    'Oriental Car Insurance',
    'Universal Sompo Car Insurance',
    'Reliance Car Insurance',
    'Royal Sundaram Car Insurance',
    'SBI Car Insurance',
    'Shriram Car Insurance',
    'Tata AIG Car Insurance',
    'United India Car Insurance',
    'Raheja QBE Car Insurance',
  ];

  String _reminderType = '';
  bool _showService = false;
  bool _showInsurance = false;

  final TextEditingController _serviceCount = TextEditingController();
  final TextEditingController _lastSerDate = TextEditingController();
  final TextEditingController _lastDriKms = TextEditingController();
  final TextEditingController _nextSerDate = TextEditingController();
  final TextEditingController _nextDriKms = TextEditingController();
  final TextEditingController _setSerReminder = TextEditingController();

  final TextEditingController _insBrand = TextEditingController();
  final TextEditingController _policyNo = TextEditingController();
  final TextEditingController _engineNo = TextEditingController();
  final TextEditingController _paidDate = TextEditingController();
  final TextEditingController _paidAmount = TextEditingController();
  final TextEditingController _vecReg = TextEditingController();
  final TextEditingController _renewalDate = TextEditingController();
  final TextEditingController _setInsReminder = TextEditingController();

  @override
  void dispose() {
    _serviceCount.dispose();
    _lastSerDate.dispose();
    _lastDriKms.dispose();
    _nextSerDate.dispose();
    _nextDriKms.dispose();
    _setSerReminder.dispose();
    _insBrand.dispose();
    _policyNo.dispose();
    _engineNo.dispose();
    _paidDate.dispose();
    _paidAmount.dispose();
    _vecReg.dispose();
    _renewalDate.dispose();
    _setInsReminder.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController target) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    target.text = '${picked.year}-${picked.month}-${picked.day}';
  }

  Future<void> _pickFromList({
    required List<String> options,
    required void Function(String value) onSelected,
  }) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: options
            .map(
              (e) => ListTile(
                title: Text(e),
                onTap: () => Navigator.pop(context, e),
              ),
            )
            .toList(),
      ),
    );
    if (value != null) onSelected(value);
  }

  void _onReminderTypeSelected(String value) {
    setState(() {
      _reminderType = value;
      _showService = value == 'Services Remainder';
      _showInsurance = value == 'Bike/Car Insurance Remainder';
    });
  }

  void _submitService() {
    if (_serviceCount.text.isEmpty ||
        _lastSerDate.text.isEmpty ||
        _lastDriKms.text.isEmpty ||
        _nextSerDate.text.isEmpty ||
        _nextDriKms.text.isEmpty ||
        _setSerReminder.text.isEmpty) {
      _toast('Please enter all details');
      return;
    }
    _toast('Success');
    context.pop();
  }

  void _submitInsurance() {
    if (_insBrand.text.isEmpty ||
        _policyNo.text.isEmpty ||
        _engineNo.text.isEmpty ||
        _paidDate.text.isEmpty ||
        _paidAmount.text.isEmpty ||
        _vecReg.text.isEmpty ||
        _renewalDate.text.isEmpty ||
        _setInsReminder.text.isEmpty) {
      _toast('Please enter all details');
      return;
    }
    _toast('Success');
    context.pop();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubpageScaffold(
      title: 'My Remainder',
      onBack: () => context.pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _selectField(
              label: _reminderType.isEmpty ? 'Select Reminder' : _reminderType,
              onTap: () => _pickFromList(
                options: _remainderTypes,
                onSelected: _onReminderTypeSelected,
              ),
            ),
            if (_showService) ...<Widget>[
              const SizedBox(height: 8),
              _selectField(
                label: _serviceCount.text.isEmpty
                    ? 'Service Count'
                    : _serviceCount.text,
                onTap: () => _pickFromList(
                  options: _serviceCounts,
                  onSelected: (v) => setState(() => _serviceCount.text = v),
                ),
              ),
              _inputField(
                controller: _lastSerDate,
                hint: 'Last Service Date',
                readOnly: true,
                onTap: () => _pickDate(_lastSerDate),
              ),
              _inputField(controller: _lastDriKms, hint: 'Last Driven Kms'),
              _inputField(
                controller: _nextSerDate,
                hint: 'Next Service Date',
                readOnly: true,
                onTap: () => _pickDate(_nextSerDate),
              ),
              _inputField(controller: _nextDriKms, hint: 'Next Driven Kms'),
              _selectField(
                label: _setSerReminder.text.isEmpty
                    ? 'Set Service Reminder'
                    : _setSerReminder.text,
                onTap: () => _pickFromList(
                  options: _setRemainder,
                  onSelected: (v) => setState(() => _setSerReminder.text = v),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _actionButton('CANCEL', () => context.pop()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton('SUBMIT', _submitService),
                  ),
                ],
              ),
            ],
            if (_showInsurance) ...<Widget>[
              const SizedBox(height: 8),
              _selectField(
                label: _insBrand.text.isEmpty ? 'Insurance Brand' : _insBrand.text,
                onTap: () => _pickFromList(
                  options: _insuranceBrands,
                  onSelected: (v) => setState(() => _insBrand.text = v),
                ),
              ),
              _inputField(controller: _policyNo, hint: 'Policy Number'),
              _inputField(controller: _engineNo, hint: 'Engine Number'),
              _inputField(
                controller: _paidDate,
                hint: 'Paid Date',
                readOnly: true,
                onTap: () => _pickDate(_paidDate),
              ),
              _inputField(
                controller: _paidAmount,
                hint: 'Paid Amount',
                keyboardType: TextInputType.number,
              ),
              _inputField(controller: _vecReg, hint: 'Vehicle Registration No'),
              _inputField(
                controller: _renewalDate,
                hint: 'Renewal Date',
                readOnly: true,
                onTap: () => _pickDate(_renewalDate),
              ),
              _selectField(
                label: _setInsReminder.text.isEmpty
                    ? 'Set Insurance Reminder'
                    : _setInsReminder.text,
                onTap: () => _pickFromList(
                  options: _setRemainder,
                  onSelected: (v) => setState(() => _setInsReminder.text = v),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _actionButton('CANCEL', () => context.pop()),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionButton('SUBMIT', _submitInsurance),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _fieldBorder),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, color: AppColors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _hintColor, fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _selectField({
    required String label,
    required VoidCallback onTap,
  }) {
    final placeholder = label.startsWith('Select') ||
        label.startsWith('Service Count') ||
        label.startsWith('Set ') ||
        label.startsWith('Insurance Brand');
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _fieldBorder),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: placeholder ? _hintColor : AppColors.black,
                ),
              ),
            ),
            Image.asset(
              'assets/images/down_arrow.png',
              width: 20,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String title, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(title),
    );
  }
}
