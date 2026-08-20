import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_gradients.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/features/vehicles/core/vehicle_category_utils.dart';
import 'package:carrocare_flutter/features/vehicles/data/repositories/vehicles_repository.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/add_vehicle_args.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key, this.args});

  final AddVehicleArgs? args;

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _repo = sl<VehiclesRepository>();

  final TextEditingController _vehicleNo = TextEditingController();
  final TextEditingController _color = TextEditingController();
  final TextEditingController _parkingLot = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();

  String _vehicleCategory = '';
  String _makeModel = '';
  String _make = '';
  String _model = '';
  String _apartment = '';
  String _parkingArea = '';
  String _preferredSchedule = '';
  String _preferredTime = '';
  bool _loading = false;

  List<String> _makeModels = <String>[];
  List<String> _apartments = <String>[];
  List<String> _parkingAreas = <String>[];

  static const List<String> _categories = <String>[
    'hatchback',
    'sedan',
    'suv',
    'bike',
  ];
  static const List<String> _schedules = <String>['Morning', 'Evening'];
  static const List<String> _morning = <String>[
    '5:00 AM - 6:00 AM',
    '6:00 AM - 7:00 AM',
    '7:00 AM - 8:00 AM',
    '8:00 AM - 9:00 AM',
    '9:00 AM - 10:00 AM',
  ];
  static const List<String> _evening = <String>[
    '5:00 PM - 6:00 PM',
    '6:00 PM - 7:00 PM',
    '7:00 PM - 8:00 PM',
    '8:00 PM - 9:00 PM',
  ];

  static final OutlineInputBorder _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppDecorations.inputRadius),
    borderSide: const BorderSide(color: AppColors.grey200),
  );

  static final OutlineInputBorder _focusedFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppDecorations.inputRadius),
    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
  );

  @override
  void initState() {
    super.initState();
    final preset = widget.args?.preselectedCategory;
    if (preset != null && preset.isNotEmpty) {
      _vehicleCategory = normalizeVehicleCategory(preset);
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    var apartments = <String>[];
    var parking = <String>[];
    var makeModels = <String>[];

    try {
      apartments = await _repo.getApartmentNames();
      if (kDebugMode) {
        debugPrint(
          '[AddVehicle] apartment dropdown: count=${apartments.length}, '
          'data=$apartments',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[AddVehicle] apartment list failed: $e');
        debugPrint('$stackTrace');
      }
    }

    try {
      parking = await _repo.getParkingAreas();
      if (kDebugMode) {
        debugPrint(
          '[AddVehicle] parking area dropdown: count=${parking.length}, '
          'data=$parking',
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[AddVehicle] parking area list failed: $e');
        debugPrint('$stackTrace');
      }
    }

    if (_vehicleCategory.isNotEmpty) {
      try {
        makeModels = await _repo.getMakeModels(_vehicleCategory);
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('[AddVehicle] make/model list failed: $e');
          debugPrint('$stackTrace');
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _apartments = apartments;
      _parkingAreas = parking;
      _makeModels = makeModels;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _vehicleNo.dispose();
    _color.dispose();
    _parkingLot.dispose();
    _makeController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Add Vehicle',
      onBack: () => context.pop(),
      backgroundDecoration: const BoxDecoration(
        gradient: AppGradients.washScreenBackground,
      ),
      body: _loading
          ? const CarroCareLoadingOverlay()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Register your vehicle',
                    style: AppTypography.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fill in the details below to add your vehicle for wash services.',
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      color: AppColors.grey600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FormSection(
                    title: 'Vehicle details',
                    children: <Widget>[
                      _selectField(
                        label: _vehicleCategory.isEmpty
                            ? 'Vehicle Category'
                            : _vehicleCategory,
                        isPlaceholder: _vehicleCategory.isEmpty,
                        onTap: () => _pickCategory(),
                      ),
                      if (_vehicleCategory.toLowerCase() != 'bike') ...<Widget>[
                        _selectField(
                          label: _makeModel.isEmpty
                              ? 'Make and Model'
                              : _makeModel,
                          isPlaceholder: _makeModel.isEmpty,
                          onTap: _vehicleCategory.isEmpty
                              ? null
                              : _pickMakeModel,
                        ),
                      ] else ...<Widget>[
                        _inputField(
                          controller: _makeController,
                          hint: 'Make',
                          onChanged: (v) => _make = v,
                        ),
                        _inputField(
                          controller: _modelController,
                          hint: 'Model',
                          onChanged: (v) => _model = v,
                        ),
                      ],
                      _inputField(
                        controller: _vehicleNo,
                        hint: 'Vehicle No.',
                      ),
                      _inputField(
                        controller: _color,
                        hint: 'Vehicle Color',
                      ),
                    ],
                  ),
                  _FormSection(
                    title: 'Parking & location',
                    children: <Widget>[
                      _selectField(
                        label: _apartment.isEmpty
                            ? 'Apartment Name'
                            : _apartment,
                        isPlaceholder: _apartment.isEmpty,
                        onTap: () => _pickList('Apartment Name', _apartments, (
                          v,
                        ) {
                          setState(() => _apartment = v);
                        }),
                      ),
                      _inputField(
                        controller: _parkingLot,
                        hint: 'Parking lot no.',
                      ),
                      _selectField(
                        label: _parkingArea.isEmpty
                            ? 'Parking Area'
                            : _parkingArea,
                        isPlaceholder: _parkingArea.isEmpty,
                        onTap: () => _pickList('Parking Area', _parkingAreas, (
                          v,
                        ) {
                          setState(() => _parkingArea = v);
                        }),
                      ),
                    ],
                  ),
                  _FormSection(
                    title: 'Wash schedule',
                    children: <Widget>[
                      _selectField(
                        label: _preferredSchedule.isEmpty
                            ? 'Preferred Schedule'
                            : _preferredSchedule,
                        isPlaceholder: _preferredSchedule.isEmpty,
                        onTap: () => _pickList('Preferred Schedule', _schedules, (
                          v,
                        ) {
                          setState(() {
                            _preferredSchedule = v;
                            _preferredTime = '';
                          });
                        }),
                      ),
                      _selectField(
                        label: _preferredTime.isEmpty
                            ? 'Preferred Time'
                            : _preferredTime,
                        isPlaceholder: _preferredTime.isEmpty,
                        onTap: () {
                          if (_preferredSchedule.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Choose Preferred Schedule'),
                              ),
                            );
                            return;
                          }
                          final times = _preferredSchedule == 'Morning'
                              ? _morning
                              : _evening;
                          _pickList('Preferred Time', times, (v) {
                            setState(() => _preferredTime = v);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _actionBtn(
                          title: 'Cancel',
                          onTap: () => context.pop(),
                          outlined: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionBtn(
                          title: 'Submit',
                          onTap: _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.dmSans(
        fontSize: 15,
        color: AppColors.grey500,
      ),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: _fieldBorder,
      enabledBorder: _fieldBorder,
      focusedBorder: _focusedFieldBorder,
      disabledBorder: _fieldBorder,
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.dmSans(
          fontSize: 15,
          color: AppColors.grey800,
        ),
        decoration: _fieldDecoration(hint),
      ),
    );
  }

  Widget _selectField({
    required String label,
    required bool isPlaceholder,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDecorations.inputRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDecorations.inputRadius),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDecorations.inputRadius),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.dmSans(
                      fontSize: 15,
                      color: isPlaceholder
                          ? AppColors.grey500
                          : AppColors.grey800,
                      fontWeight: isPlaceholder
                          ? FontWeight.w400
                          : FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: AppColors.grey500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required String title,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: outlined ? AppColors.white : AppColors.primary,
        foregroundColor: outlined ? AppColors.primary : AppColors.white,
        minimumSize: const Size.fromHeight(50),
        elevation: outlined ? 0 : 2,
        side: outlined
            ? const BorderSide(color: AppColors.primary, width: 1.5)
            : BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
        ),
      ),
      child: Text(
        title,
        style: AppTypography.quicksand(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: outlined ? AppColors.primary : AppColors.white,
        ),
      ),
    );
  }

  Future<void> _pickCategory() async {
    _pickList('Vehicle Category', _categories, (v) async {
      setState(() {
        _vehicleCategory = v;
        _makeModel = '';
        _make = '';
        _model = '';
        _makeModels = <String>[];
      });
      _makeController.clear();
      _modelController.clear();
      if (v.toLowerCase() != 'bike') {
        final list = await _repo.getMakeModels(v);
        if (!mounted) return;
        setState(() => _makeModels = list);
      }
    });
  }

  Future<void> _pickMakeModel() async {
    if (_makeModels.isEmpty) return;
    _pickList('Make and Model', _makeModels, (v) {
      final split = v.split('-');
      setState(() {
        _makeModel = v;
        _make = split.isNotEmpty ? split.first : '';
        _model = split.length > 1 ? split[1] : '';
      });
      _makeController.text = _make;
      _modelController.text = _model;
    });
  }

  Future<void> _pickList(
    String title,
    List<String> items,
    ValueChanged<String> onSelected,
  ) async {
    if (items.isEmpty) return;
    final result = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: ListView(
          children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          ...items.map(
            (e) => ListTile(
              title: Text(e),
              onTap: () => Navigator.pop(context, e),
            ),
          ),
        ],
      ),
    ),
  );
    if (result != null) onSelected(result);
  }

  Future<void> _submit() async {
    final isBike = _vehicleCategory.toLowerCase() == 'bike';
    if (_vehicleCategory.isEmpty ||
        _vehicleNo.text.trim().isEmpty ||
        _color.text.trim().isEmpty ||
        _apartment.isEmpty ||
        _parkingLot.text.trim().isEmpty ||
        _parkingArea.isEmpty ||
        _preferredSchedule.isEmpty ||
        _preferredTime.isEmpty ||
        (isBike && (_make.isEmpty || _model.isEmpty)) ||
        (!isBike && _makeModel.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter all the details')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('customer_id') ?? '';
    final token = prefs.getString('token') ?? '';

    if (customerId.isEmpty || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session missing. Please login again.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _repo.addVehicle(
        vehicleType: isBike ? 'Bike' : 'Car',
        category: normalizeVehicleCategory(_vehicleCategory),
        make: _make,
        model: _model,
        vehicleNo: _vehicleNo.text.trim(),
        color: _color.text.trim(),
        apartmentName: _apartment,
        parkingLotNo: _parkingLot.text.trim(),
        parkingArea: _parkingArea,
        preferredSchedule: _preferredSchedule,
        preferredTime: _preferredTime,
        customerId: customerId,
        token: token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle added successfully')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
