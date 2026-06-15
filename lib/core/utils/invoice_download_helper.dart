import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class InvoiceDownloadHelper {
  InvoiceDownloadHelper({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<void> downloadAndOpen({
    required BuildContext context,
    required String downloadUrl,
    required String fileName,
  }) async {
    if (downloadUrl.isEmpty) {
      _toast(context, 'Invoice Download Failed. Please Contact Admin.');
      return;
    }
    try {
      final parts = downloadUrl.split('=');
      if (parts.length >= 2 && parts.last.trim() == '0') {
        _toast(context, 'Invoice Download Failed. Please Contact Admin.');
        return;
      }
    } catch (_) {
      _toast(context, 'Invoice Download Failed. Please Contact Admin.');
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final path = '${dir.path}/$safeName';

      await _dio.download(downloadUrl, path);

      final result = await OpenFilex.open(path);
      if (!context.mounted) return;
      if (result.type != ResultType.done) {
        _toast(
          context,
          'Downloaded to app storage: $safeName',
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      _toast(context, 'Invoice Download Failed.');
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
