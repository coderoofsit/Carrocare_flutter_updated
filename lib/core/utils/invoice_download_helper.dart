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
    String loadingMessage = 'Downloading invoice…',
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

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(loadingMessage)),
          ],
        ),
        duration: const Duration(minutes: 2),
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final path = '${dir.path}/$safeName';

      await _dio.download(downloadUrl, path);

      final result = await OpenFilex.open(path);
      if (!context.mounted) return;
      messenger?.hideCurrentSnackBar();
      if (result.type != ResultType.done) {
        _toast(
          context,
          'Downloaded to app storage: $safeName',
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      messenger?.hideCurrentSnackBar();
      _toast(context, 'Invoice Download Failed.');
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
