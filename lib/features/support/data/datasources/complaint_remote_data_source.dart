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
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'submit_complaint.php',
      data: <String, dynamic>{
        'customer_id': customerId,
        'name': name,
        'mobile': mobile,
        'email': email,
        'note': note,
        if (images != null && images.isNotEmpty) 'images': images,
      },
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> fetchMyComplaints({
    required String customerId,
    required String mobile,
    required String email,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'my_complaints.php',
      data: <String, dynamic>{
        'customer_id': customerId,
        'mobile': mobile,
        'email': email,
      },
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
