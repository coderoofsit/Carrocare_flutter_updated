import 'package:carrocare_flutter/core/network/api_client.dart';

class ComplaintRemoteDataSource {
  ComplaintRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> submitComplaint({
    required String name,
    required String mobile,
    required String email,
    required String note,
    List<String>? images,
    required String customerId,
    String? token,
    String? vehicleId,
    String? vehicleNo,
    String? labourId,
    String? labourName,
    String? labourMobile,
    String? apartmentName,
    String? complaintBy,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'submit_complaint.php',
      data: <String, dynamic>{
        'customer_id': customerId,
        'name': name,
        'mobile': mobile,
        'email': email,
        'note': note,
        if (token != null && token.isNotEmpty) 'token': token,
        if (images != null && images.isNotEmpty) 'images': images,
        if (vehicleId != null && vehicleId.isNotEmpty) 'vehicle_id': vehicleId,
        if (vehicleNo != null && vehicleNo.isNotEmpty) 'vehicle_no': vehicleNo,
        if (labourId != null && labourId.isNotEmpty) 'labour_id': labourId,
        if (labourName != null && labourName.isNotEmpty) 'labour_name': labourName,
        if (labourMobile != null && labourMobile.isNotEmpty) 'labour_mobile': labourMobile,
        if (apartmentName != null && apartmentName.isNotEmpty) 'apartment_name': apartmentName,
        if (complaintBy != null && complaintBy.isNotEmpty) 'complaint_by': complaintBy,
      },
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> fetchComplaintTargets({
    required String customerId,
    String? token,
  }) async {
    final data = <String, dynamic>{
      'customer_id': customerId,
    };
    if (token != null && token.isNotEmpty) {
      data['token'] = token;
    }
    final response = await _apiClient.dio.post<dynamic>(
      'customer_complaint_targets.php',
      data: data,
    );
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final list = map['targets'];
      if (list is List) {
        return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> fetchMyComplaints({
    required String customerId,
    required String mobile,
    required String email,
    String? token,
  }) async {
    final data = <String, dynamic>{
      'customer_id': customerId,
      'mobile': mobile,
      'email': email,
    };
    if (token != null && token.isNotEmpty) {
      data['token'] = token;
    }
    final response = await _apiClient.dio.post<dynamic>(
      'my_complaints.php',
      data: data,
    );
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      final list = map['complaints'];
      if (list is List) {
        return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    }
    return <Map<String, dynamic>>[];
  }
}
