import 'dart:convert';
import 'dart:typed_data';

import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/support/data/datasources/complaint_remote_data_source.dart';
import 'package:carrocare_flutter/features/support/presentation/widgets/profile_subpage_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ComplaintRemoteDataSource _dataSource =
      ComplaintRemoteDataSource(sl<ApiClient>());

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = <XFile>[];
  bool _submitting = false;

  List<Map<String, dynamic>> _myComplaints = <Map<String, dynamic>>[];
  bool _loadingComplaints = false;
  String _customerId = '';
  String _token = '';

  List<Map<String, dynamic>> _targets = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selectedTarget;
  bool _loadingTargets = false;
  final Set<String> _expandedComplaintIds = <String>{};

  String _formatToIndianTime(String rawDate, [String? displayTimeIst]) {
    if (displayTimeIst != null && displayTimeIst.trim().isNotEmpty) {
      return displayTimeIst.trim();
    }
    final s = rawDate.trim();
    if (s.isEmpty) return '';
    try {
      DateTime dt;
      if (s.endsWith('Z') || s.contains('+')) {
        dt = DateTime.parse(s).toUtc().add(const Duration(hours: 5, minutes: 30));
      } else if (RegExp(r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}').hasMatch(s)) {
        dt = DateTime.parse(s.replaceFirst(' ', 'T'));
      } else {
        dt = DateTime.parse(s);
      }
      return '${DateFormat('dd MMM yyyy, hh:mm a').format(dt)} (IST)';
    } catch (_) {
      return s;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token') ?? '';
      _customerId = prefs.getString('customer_id') ?? '';
      _nameController.text =
          prefs.getString('username') ?? prefs.getString('name') ?? '';
      _mobileController.text =
          prefs.getString('usermobile') ?? prefs.getString('mobile') ?? '';
      _emailController.text =
          prefs.getString('useremail') ?? prefs.getString('email') ?? '';
    });
    _fetchComplaints();
    _fetchComplaintTargets();
  }

  Future<void> _fetchComplaintTargets() async {
    if (_customerId.isEmpty) return;
    setState(() => _loadingTargets = true);
    try {
      final list = await _dataSource.fetchComplaintTargets(
        customerId: _customerId,
        token: _token,
      );
      if (mounted) {
        setState(() {
          _targets = list;
          _loadingTargets = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingTargets = false);
      }
    }
  }

  Future<void> _fetchComplaints() async {
    if (_mobileController.text.isEmpty &&
        _emailController.text.isEmpty &&
        _customerId.isEmpty) {
      return;
    }
    setState(() => _loadingComplaints = true);
    try {
      final list = await _dataSource.fetchMyComplaints(
        customerId: _customerId,
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        token: _token,
      );
      if (mounted) {
        setState(() {
          _myComplaints = list;
          _loadingComplaints = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingComplaints = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
          });
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        if (image != null) {
          setState(() {
            _selectedImages.add(image);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitComplaint() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);

    try {
      final List<String> base64Images = <String>[];
      for (final file in _selectedImages) {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last.toLowerCase();
        final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';
        base64Images.add('data:$mime;base64,${base64Encode(bytes)}');
      }

      final response = await _dataSource.submitComplaint(
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        note: _noteController.text.trim(),
        images: base64Images.isNotEmpty ? base64Images : null,
        customerId: _customerId,
        token: _token,
        vehicleId: _selectedTarget?['vehicle_id']?.toString(),
        vehicleNo: _selectedTarget?['vehicle_no']?.toString(),
        labourId: _selectedTarget?['labour_id']?.toString(),
        labourName: _selectedTarget?['labour_name']?.toString(),
        labourMobile: _selectedTarget?['labour_mobile']?.toString(),
        apartmentName: _selectedTarget?['apartment_name']?.toString(),
        complaintBy: 'customer',
      );

      if (!mounted) return;
      final code = (response['code'] ?? '').toString();
      final msg = (response['message'] ?? 'Complaint submitted successfully').toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: (code == '200' || response['status'] == 'success')
              ? Colors.green
              : Colors.red,
        ),
      );

      if (code == '200' || response['status'] == 'success') {
        _noteController.clear();
        setState(() {
          _selectedImages.clear();
          _selectedTarget = null;
        });
        await _fetchComplaints();
        _tabController.animateTo(1); // Switch to My Complaints tab
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit complaint. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade800;
      case 'in progress':
        return Colors.blue.shade700;
      case 'resolved':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade50;
      case 'in progress':
        return Colors.blue.shade50;
      case 'resolved':
        return Colors.green.shade50;
      case 'rejected':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  void _showImageDialog(String imageSrc) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.network(
                imageSrc,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Image.memory(
                  base64Decode(imageSrc.contains(',') ? imageSrc.split(',').last : imageSrc),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 60),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubpageScaffold(
      title: 'COMPLAINT SECTION',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/main-profile');
        }
      },
      body: Column(
        children: <Widget>[
          Material(
            color: AppColors.white,
            elevation: 2,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const <Tab>[
                Tab(text: 'REGISTER COMPLAINT'),
                Tab(text: 'MY COMPLAINTS'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildComplaintForm(),
                _buildMyComplaintsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Have an issue? Submit your complaint',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please fill out the details below so our support team can assist you as soon as possible.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    // Vehicle & Assigned Cleaner Dropdown (Optional / Default General)
                    const Text(
                      'Complaint Target (Vehicle / Cleaner)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>?>(
                          isExpanded: true,
                          value: _selectedTarget,
                          icon: _loadingTargets
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_drop_down),
                          hint: const Text('General Complaint (App / Billing / Other)'),
                          items: [
                            const DropdownMenuItem<Map<String, dynamic>?>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(Icons.help_outline, color: Colors.grey, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'General Complaint (App / Billing / Other)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ..._targets.map((target) {
                              final vNo = target['vehicle_no']?.toString() ?? '';
                              final lName = target['labour_name']?.toString() ?? '';
                              return DropdownMenuItem<Map<String, dynamic>?>(
                                value: target,
                                child: Row(
                                  children: [
                                    const Icon(Icons.directions_car, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        lName.isNotEmpty
                                            ? '$vNo — Cleaner: $lName'
                                            : vNo,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedTarget = val);
                          },
                        ),
                      ),
                    ),
                    if (_selectedTarget != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vehicle: ${_selectedTarget!['vehicle_no'] ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  if ((_selectedTarget!['labour_name']?.toString() ?? '').isNotEmpty)
                                    Text(
                                      'Assigned Cleaner: ${_selectedTarget!['labour_name']}',
                                      style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                                    ),
                                  if ((_selectedTarget!['apartment_name']?.toString() ?? '').isNotEmpty)
                                    Text(
                                      'Apartment: ${_selectedTarget!['apartment_name']}',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // Name Field (Required)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Mobile Field (Required)
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number *',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Mobile number is required';
                        }
                        if (value.trim().length < 8) {
                          return 'Enter a valid mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Email Field (Required)
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Note Field (Required)
                    TextFormField(
                      controller: _noteController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Complaint Note / Details *',
                        alignLabelWithHint: true,
                        hintText: 'Describe your issue in detail...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter complaint note';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Optional Image Attachment Section
                    const Text(
                      'Attach Photos (Optional)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 18),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8, top: 4),
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: FutureBuilder<List<int>>(
                                      future: _selectedImages[index].readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          return Image.memory(
                                            Uint8List.fromList(snapshot.data!),
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submitComplaint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
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
                            : const Text(
                                'SUBMIT COMPLAINT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyComplaintsList() {
    if (_loadingComplaints) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myComplaints.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchComplaints,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: const <Widget>[
            SizedBox(height: 60),
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Complaints Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You have not submitted any complaints yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchComplaints,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _myComplaints.length,
        itemBuilder: (context, index) {
          final item = _myComplaints[index];
          final String id = (item['id'] ?? '').toString();
          final String status = (item['status'] ?? 'Pending').toString();
          final String note = (item['note'] ?? '').toString();
          final String rawDate = (item['dateandtime'] ?? item['created_at'] ?? '').toString();
          final String displayTimeIst = (item['display_time_ist'] ?? '').toString();
          final List images = (item['images'] is List) ? (item['images'] as List) : [];
          final String formattedDate = _formatToIndianTime(rawDate, displayTimeIst);
          final bool isExpanded = _expandedComplaintIds.contains(id);
          final bool isLong = note.length > 80 || note.contains('\n');
          final String displayNote = (isLong && !isExpanded)
              ? '${note.substring(0, (note.length > 80 ? 80 : note.length)).trim()}...'
              : note;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Complaint #$id',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(status),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getStatusColor(status)),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (formattedDate.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                  if ((item['vehicle_no']?.toString() ?? '').isNotEmpty ||
                      (item['labour_name']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if ((item['vehicle_no']?.toString() ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.directions_car, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  item['vehicle_no'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if ((item['labour_name']?.toString() ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person, size: 14, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  'Cleaner: ${item['labour_name']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  const Divider(height: 18),
                  Text(
                    displayNote,
                    style: const TextStyle(fontSize: 14, color: AppColors.black, height: 1.35),
                  ),
                  if (isLong)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedComplaintIds.remove(id);
                          } else {
                            _expandedComplaintIds.add(id);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isExpanded ? 'Show less' : 'Tap to view message',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Attached Images:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 64,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, imgIdx) {
                          final String imgSrc = images[imgIdx].toString();
                          return GestureDetector(
                            onTap: () => _showImageDialog(imgSrc),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  imgSrc,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Image.memory(
                                    base64Decode(imgSrc.contains(',') ? imgSrc.split(',').last : imgSrc),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 30),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
