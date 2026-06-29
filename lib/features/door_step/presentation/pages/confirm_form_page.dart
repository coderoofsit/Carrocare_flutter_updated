import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/core/storage/map_location_store.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/utils/validators.dart';
import 'package:carrocare_flutter/features/door_step/data/datasources/door_step_form_remote_data_source.dart';
import 'package:carrocare_flutter/features/door_step/domain/entities/confirm_form_args.dart';
import 'package:carrocare_flutter/features/map/domain/entities/map_location_result.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Matches Android [ConfirmFormActivity].
class ConfirmFormPage extends StatefulWidget {
  const ConfirmFormPage({super.key, required this.args});

  final ConfirmFormArgs args;

  @override
  State<ConfirmFormPage> createState() => _ConfirmFormPageState();
}

class _ConfirmFormPageState extends State<ConfirmFormPage> {
  final _remote = DoorStepFormRemoteDataSource(sl<ApiClient>());
  final _locationStore = MapLocationStore();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _landmark = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _country = TextEditingController();
  final TextEditingController _pincode = TextEditingController();
  final TextEditingController _vecType = TextEditingController();
  final TextEditingController _vecCategory = TextEditingController();
  final TextEditingController _vecMake = TextEditingController();
  final TextEditingController _vecModel = TextEditingController();

  String _infoDescription = '';
  bool _loadingInfo = false;
  bool _submitting = false;

  static const Color _fieldBorder = Color(0xFF8F8F8F);
  static const Color _hintColor = Color(0xFF8F8F8F);

  static const List<String> _vehicleTypes = <String>['car', 'bike'];
  static const List<String> _carCategories = <String>[
    'hatchback',
    'sedan',
    'suv',
  ];

  @override
  void initState() {
    super.initState();
    _loadSession();
    _loadSavedAddress();
    if (widget.args.mode == ConfirmFormMode.insurance) {
      _loadInsuranceInfo();
    }
  }

  Future<void> _loadSavedAddress() async {
    final address = await _locationStore.readAddress();
    if (address.isNotEmpty && mounted) {
      _address.text = address;
    }
  }

  Future<void> _openMapPicker() async {
    final result = await context.push<MapLocationResult>('/locate-on-map');
    if (result != null && mounted) {
      setState(() => _address.text = result.address);
      return;
    }
    await _loadSavedAddress();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _name.text = prefs.getString('username') ?? prefs.getString('name') ?? '';
    _email.text = prefs.getString('useremail') ?? prefs.getString('email') ?? '';
    _mobile.text =
        prefs.getString('usermobile') ?? prefs.getString('mobile') ?? '';
  }

  Future<void> _loadInsuranceInfo() async {
    setState(() => _loadingInfo = true);
    try {
      final model =
          await _remote.getServicePrice(widget.args.servicePriceKey);
      if (!mounted) return;
      setState(() => _infoDescription = model.description);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingInfo = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _address.dispose();
    _landmark.dispose();
    _city.dispose();
    _state.dispose();
    _country.dispose();
    _pincode.dispose();
    _vecType.dispose();
    _vecCategory.dispose();
    _vecMake.dispose();
    _vecModel.dispose();
    super.dispose();
  }

  Future<void> _pickVehicleType() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: _vehicleTypes
            .map(
              (e) => ListTile(
                title: Text(e),
                onTap: () => Navigator.pop(context, e),
              ),
            )
            .toList(),
      ),
    );
    if (value == null) return;
    setState(() {
      _vecType.text = value;
      if (value == 'bike') {
        _vecCategory.text = 'bike';
      } else {
        _vecCategory.clear();
      }
    });
  }

  Future<void> _pickCategory() async {
    if (_vecType.text.toLowerCase() != 'car') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose Vehicle type')),
      );
      return;
    }
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: _carCategories
            .map(
              (e) => ListTile(
                title: Text(e),
                onTap: () => Navigator.pop(context, e),
              ),
            )
            .toList(),
      ),
    );
    if (value != null) setState(() => _vecCategory.text = value);
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _mobile.text.trim().isEmpty ||
        _address.text.trim().isEmpty ||
        _landmark.text.trim().isEmpty ||
        _city.text.trim().isEmpty ||
        _state.text.trim().isEmpty ||
        _country.text.trim().isEmpty ||
        _pincode.text.trim().isEmpty ||
        _vecType.text.trim().isEmpty ||
        _vecMake.text.trim().isEmpty ||
        _vecModel.text.trim().isEmpty ||
        _vecCategory.text.trim().isEmpty) {
      _toast('Please enter all details');
      return;
    }
    if (_mobile.text.trim().length != 10) {
      _toast('Please enter valid mobile number');
      return;
    }
    if (_pincode.text.trim().length != 6) {
      _toast('Please enter valid pincode');
      return;
    }
    if (!Validators.isValidEmail(_email.text.trim())) {
      _toast('Please enter valid email');
      return;
    }

    setState(() => _submitting = true);
    try {
      final data = await _remote.submitCustomerForm(
        name: _name.text.trim(),
        mobile: _mobile.text.trim(),
        email: _email.text.trim(),
        addressLine: _address.text.trim(),
        landmark: _landmark.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim(),
        country: _country.text.trim(),
        pincode: _pincode.text.trim(),
        vehicleType: _vecType.text.trim(),
        make: _vecMake.text.trim(),
        model: _vecModel.text.trim(),
        category: _vecCategory.text.trim(),
        form: widget.args.formField,
      );
      final code = (data['code'] ?? '').toString();
      final message = (data['message'] ?? '').toString();
      if (!mounted) return;
      if (code == '200') {
        _toast(message.isEmpty ? 'Submitted successfully' : message);
        context.pop();
      } else {
        _toast(message.isEmpty ? 'Submission failed' : message);
      }
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

  void _showInfo() {
    if (_infoDescription.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.args.headerTitle),
        content: SingleChildScrollView(
          child: Text(_stripHtml(_infoDescription)),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showInfo = widget.args.mode == ConfirmFormMode.insurance;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/home');
      },
      child: CarroCareScaffold(
        title: widget.args.headerTitle,
        onBack: () => context.go('/home'),
        actions: <Widget>[
          if (showInfo)
            GestureDetector(
              onTap: _loadingInfo ? null : _showInfo,
              child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                child: Opacity(
                  opacity: _infoDescription.isEmpty ? 0.45 : 1,
                  child: Image.asset('assets/images/info.png'),
                ),
              ),
            ),
        ],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
                        const Text(
                          'Please Enter Details !!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _inputField(controller: _name, hint: 'Name'),
                        _inputField(
                          controller: _email,
                          hint: 'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _inputField(
                          controller: _mobile,
                          hint: 'Mobile',
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                        ),
                        _inputField(controller: _address, hint: 'Address', onTap: _openMapPicker),
                        _inputField(controller: _landmark, hint: 'Landmark'),
                        _inputField(controller: _city, hint: 'City'),
                        _inputField(controller: _state, hint: 'State'),
                        _inputField(controller: _country, hint: 'Country'),
                        _inputField(
                          controller: _pincode,
                          hint: 'Pincode',
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                        _selectField(
                          label: _vecType.text.isEmpty
                              ? 'Vehicle Type'
                              : _vecType.text,
                          onTap: _pickVehicleType,
                        ),
                        _selectField(
                          label: _vecCategory.text.isEmpty
                              ? 'Vehicle Category'
                              : _vecCategory.text,
                          onTap: _pickCategory,
                        ),
                        _inputField(controller: _vecMake, hint: 'Make'),
                        _inputField(controller: _vecModel, hint: 'Model'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('NEXT'),
                        ),
                      ],
                    ),
          ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int? maxLength,
    VoidCallback? onTap,
  }) {
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: _fieldBorder),
    );
    final focusedFieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: AppColors.primary),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: TextField(
        controller: controller,
        readOnly: onTap != null,
        onTap: onTap,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: const TextStyle(fontSize: 16, color: AppColors.black),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.white,
          hintText: hint,
          counterText: '',
          hintStyle: const TextStyle(color: _hintColor, fontSize: 16),
          suffixIcon: onTap == null
              ? null
              : const Icon(Icons.map_outlined, color: AppColors.primary),
          border: fieldBorder,
          enabledBorder: fieldBorder,
          focusedBorder: focusedFieldBorder,
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
    final placeholder =
        label == 'Vehicle Type' || label == 'Vehicle Category';
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
            Image.asset('assets/images/down_arrow.png', width: 20, height: 20),
          ],
        ),
      ),
    );
  }
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
