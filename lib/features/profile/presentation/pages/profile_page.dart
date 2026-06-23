import 'package:carrocare_flutter/core/storage/map_location_store.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_gradients.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/core/utils/validators.dart';
import 'package:carrocare_flutter/features/map/domain/entities/map_location_result.dart';
import 'package:carrocare_flutter/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Matches Android [ProfileActivity] / `activity_profile.xml`.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _apartmentBuilding = TextEditingController();
  final TextEditingController _flatNo = TextEditingController();
  final TextEditingController _gst = TextEditingController();
  final TextEditingController _address = TextEditingController();

  String _apartmentName = '';
  String _latitude = '';
  String _longitude = '';
  String _token = '';
  String _customerId = '';
  String _userType = 'apartment';
  bool _didBindProfile = false;

  static const Color _hintColor = Color(0xFF8F8F8F);

  static final BorderRadius _fieldRadius = BorderRadius.circular(12);

  static final OutlineInputBorder _enabledFieldBorder = OutlineInputBorder(
    borderRadius: _fieldRadius,
    borderSide: BorderSide.none,
  );

  static final OutlineInputBorder _focusedFieldBorder = OutlineInputBorder(
    borderRadius: _fieldRadius,
    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
  );

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _customerId = prefs.getString('customer_id') ?? '';
    _userType = prefs.getString('user_wants') ?? 'apartment';
    if (!mounted) return;
    context.read<ProfileBloc>().add(
          ProfileLoadRequested(token: _token, customerId: _customerId),
        );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _apartmentBuilding.dispose();
    _flatNo.dispose();
    _gst.dispose();
    _address.dispose();
    super.dispose();
  }

  void _bindProfile(ProfileLoaded state) {
    if (_didBindProfile &&
        state.profile.customerId == _customerId &&
        _name.text.isNotEmpty) {
      return;
    }
    _didBindProfile = true;
    _userType = state.userType;
    _name.text = state.profile.name;
    _email.text = state.profile.email;
    _mobile.text = state.profile.mobile;
    _apartmentName = state.profile.apartmentName;
    _apartmentBuilding.text = state.profile.apartmentBuilding;
    _flatNo.text = state.profile.flatNo;
    _gst.text = state.profile.gst;
    _address.text = state.profile.address;
    _latitude = state.profile.latitude;
    _longitude = state.profile.longitude;
    _token = state.profile.token;
    _customerId = state.profile.customerId;
  }

  bool _isApartmentMode(String userType) =>
      userType.toLowerCase() == 'apartment' || userType.isEmpty;

  bool _isDoorstepMode(String userType) => userType.toLowerCase() == 'doorstep';

  Future<void> _pickApartment(List<String> apartments) async {
    if (apartments.isEmpty) return;
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => ListView(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Apartment Name',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          ...apartments.map(
            (e) => ListTile(
              title: Text(e),
              onTap: () => Navigator.pop(context, e),
            ),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => _apartmentName = result);
    }
  }

  Future<void> _openMapPicker() async {
    final result = await context.push<MapLocationResult>('/locate-on-map');
    if (result != null) {
      setState(() {
        _address.text = result.address;
        _latitude = result.latitude.toString();
        _longitude = result.longitude.toString();
      });
      return;
    }
    final store = MapLocationStore();
    final address = await store.readAddress();
    if (address.isNotEmpty && mounted) {
      setState(() => _address.text = address);
    }
  }

  void _submit(String userType) {
    if (_isDoorstepMode(userType)) {
      if (_name.text.trim().isEmpty ||
          _email.text.trim().isEmpty ||
          _mobile.text.trim().isEmpty ||
          _address.text.trim().isEmpty) {
        _showToast('Please enter all details');
        return;
      }
    } else {
      if (_name.text.trim().isEmpty ||
          _email.text.trim().isEmpty ||
          _mobile.text.trim().isEmpty ||
          _apartmentBuilding.text.trim().isEmpty ||
          _apartmentName.isEmpty ||
          _flatNo.text.trim().isEmpty) {
        _showToast('Please enter all details');
        return;
      }
    }

    if (_mobile.text.trim().length != 10) {
      _showToast('Please enter valid mobile number');
      return;
    }
    if (!Validators.isValidEmail(_email.text.trim())) {
      _showToast('Please enter valid email');
      return;
    }

    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(
            token: _token,
            customerId: _customerId,
            name: _name.text.trim(),
            email: _email.text.trim(),
            mobile: _mobile.text.trim(),
            apartmentName: _apartmentName,
            apartmentBuilding: _apartmentBuilding.text.trim(),
            flatNo: _flatNo.text.trim(),
            address: _address.text.trim(),
            latitude: _latitude,
            longitude: _longitude,
            gst: _gst.text.trim(),
          ),
        );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded && state.errorMessage == null) {
          setState(() => _bindProfile(state));
        }
        if (state is ProfileLoaded &&
            state.errorMessage != null &&
            state.errorMessage!.isNotEmpty) {
          _showToast(state.errorMessage!);
        }
        if (state is ProfileUpdateSuccess) {
          _showToast(state.message);
          context.go('/home');
        }
        if (state is ProfileFailure &&
            state.message.contains('Session expired')) {
          context.go('/login');
        }
      },
      builder: (context, state) {
        final ProfileLoaded? loadedState = switch (state) {
          ProfileLoaded loaded => loaded,
          ProfileUpdating updating => updating.previous,
          _ => null,
        };
        final isInitialLoading =
            state is ProfileLoading || state is ProfileInitial;
        final isUpdating = state is ProfileUpdating;
        final apartments = loadedState?.apartments ?? <String>[];
        final userType = loadedState?.userType ?? _userType;

        return CarroCareScaffold(
          title: 'Profile Details',
          onBack: () => context.go('/home'),
          backgroundDecoration: const BoxDecoration(
            gradient: AppGradients.homeBackground,
          ),
          body: Container(
            child: isInitialLoading
                ? const CarroCareLoadingOverlay()
                : state is ProfileFailure
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          15,
                          10,
                          15,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const Padding(
                              padding: EdgeInsets.only(bottom: 7),
                              child: Text(
                                'Welcome to the Carro Care !!',
                                style: TextStyle(
                                  color: AppColors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            _inputField(
                              controller: _name,
                              hint: 'Full Name',
                            ),
                            _inputField(
                              controller: _email,
                              hint: 'Email Address',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _inputField(
                              controller: _mobile,
                              hint: 'Mobile No.',
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                            ),
                            if (_isApartmentMode(userType)) ...<Widget>[
                              _selectField(
                                label: _apartmentName.isEmpty
                                    ? 'Apartment Name'
                                    : _apartmentName,
                                onTap: () => _pickApartment(apartments),
                              ),
                              _inputField(
                                controller: _apartmentBuilding,
                                hint: 'Apartment Building',
                              ),
                              _inputField(
                                controller: _flatNo,
                                hint: 'Flat Number',
                              ),
                              _inputField(
                                controller: _gst,
                                hint: 'GST Number',
                              ),
                            ],
                            if (_isDoorstepMode(userType))
                              _addressField(
                                controller: _address,
                                onGpsTap: _openMapPicker,
                              ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _actionBtn(
                                      title: 'CANCEL',
                                      onTap: () => context.go('/home'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _actionBtn(
                                      title: isUpdating
                                          ? 'UPDATING...'
                                          : 'UPDATE',
                                      onTap: isUpdating
                                          ? null
                                          : () => _submit(userType),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        style: const TextStyle(
          fontSize: 18,
          color: AppColors.black,
          fontWeight: FontWeight.w300,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.white.withValues(alpha: 0.92),
          hintText: hint,
          counterText: '',
          hintStyle: const TextStyle(
            fontSize: 18,
            color: _hintColor,
            fontWeight: FontWeight.w300,
          ),
          border: _enabledFieldBorder,
          enabledBorder: _enabledFieldBorder,
          focusedBorder: _focusedFieldBorder,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
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
    final isPlaceholder = label == 'Apartment Name';
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 18,
                  color: isPlaceholder ? _hintColor : AppColors.black,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            Transform.rotate(
              angle: 1.5708,
              child: SvgPicture.asset(
                'assets/vectors/ic_baseline_arrow_forward_ios_24.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressField({
    required TextEditingController controller,
    required VoidCallback onGpsTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: GestureDetector(
        onTap: onGpsTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final text = value.text.trim();
                    return Text(
                      text.isEmpty ? 'Address' : text,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 18,
                        color: text.isEmpty ? _hintColor : AppColors.black,
                        fontWeight: FontWeight.w300,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SvgPicture.asset(
                  'assets/vectors/ic_gps.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required String title,
    required VoidCallback? onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
