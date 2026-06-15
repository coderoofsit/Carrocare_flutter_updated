import 'package:carrocare_flutter/core/theme/app_colors.dart';
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
  static const Color _androidGrayBg = Color(0xFFEDEFF1);
  static const Color _androidFieldBorder = Color(0xFF8F8F8F);
  static const Color _androidHint = Color(0xFF8F8F8F);

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
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => context.pop(),
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
                      'ADD VEHICLE',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: _androidGrayBg,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(7),
                        child: Column(
                          children: <Widget>[
                            _selectField(
                              label: _vehicleCategory.isEmpty
                                  ? 'Vehicle Category'
                                  : _vehicleCategory,
                              onTap: () => _pickCategory(),
                            ),
                            if (_vehicleCategory.toLowerCase() != 'bike') ...<Widget>[
                              _selectField(
                                label: _makeModel.isEmpty ? 'Make and Model' : _makeModel,
                                onTap: _vehicleCategory.isEmpty ? null : _pickMakeModel,
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
                            _inputField(controller: _vehicleNo, hint: 'Vehicle No.'),
                            _inputField(controller: _color, hint: 'Vehicle Color'),
                            _selectField(
                              label: _apartment.isEmpty ? 'Apartment Name' : _apartment,
                              onTap: () => _pickList('Apartment Name', _apartments, (v) {
                                setState(() => _apartment = v);
                              }),
                            ),
                            _inputField(controller: _parkingLot, hint: 'Parking lot no.'),
                            _selectField(
                              label: _parkingArea.isEmpty ? 'Parking Area' : _parkingArea,
                              onTap: () => _pickList('Parking Area', _parkingAreas, (v) {
                                setState(() => _parkingArea = v);
                              }),
                            ),
                            _selectField(
                              label: _preferredSchedule.isEmpty
                                  ? 'Preferred Schedule'
                                  : _preferredSchedule,
                              onTap: () => _pickList('Preferred Schedule', _schedules, (v) {
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
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _actionBtn(
                                    title: 'CANCEL',
                                    onTap: () => context.pop(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _actionBtn(
                                    title: 'SUBMIT',
                                    onTap: _submit,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _androidFieldBorder, width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 18,
          color: AppColors.black,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 18,
            color: _androidHint,
            fontWeight: FontWeight.w300,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _selectField({
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _androidFieldBorder, width: 1),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  color: label.startsWith('Vehicle') ||
                          label.startsWith('Make') ||
                          label.startsWith('Apartment') ||
                          label.startsWith('Parking') ||
                          label.startsWith('Preferred')
                      ? _androidHint
                      : AppColors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Image.asset('assets/images/down_arrow.png', width: 20, height: 20),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({required String title, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
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
      builder: (_) => ListView(
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
