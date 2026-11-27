import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/utils/custom_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// After a Basic / Quick inspection submit, the server sends the WhatsApp messages in the
/// background. This polls the existing status API for a short while and shows ONE toast with
/// the outcome (on whatever screen is open), so it can be confirmed that sending works.
///
/// "Accepted" means the WhatsApp API accepted the message; it is never shown as delivered.
/// While the Meta templates are in review the expected result is "template not approved"
/// (code 132001): that still confirms the server reached WhatsApp with valid credentials.
///
/// Turn the toast off with SHOW_WHATSAPP_STATUS=false in .env (debug prints stay).
class WhatsAppStatusWatcher {
  static const Duration _interval = Duration(seconds: 4);
  static const int _maxPolls = 15; // about 60 seconds
  static const Set<String> _templateCodes = {
    "132000", "132001", "132012", "132015", "132016"
  };

  static bool get _toastEnabled =>
      (dotenv.env['SHOW_WHATSAPP_STATUS'] ?? 'true').trim().toLowerCase() !=
      'false';

  /// Starts watching in the background; returns immediately.
  static void watch(int jobId, {required bool bodyShopReferral}) {
    unawaited(_poll(jobId, bodyShopReferral));
  }

  static Future<void> _poll(int jobId, bool expectBodyShop) async {
    Map<String, dynamic>? last;
    for (var i = 0; i < _maxPolls; i++) {
      await Future.delayed(_interval);
      final data = await _fetch(jobId);
      if (data == null) continue;
      last = data;
      if (_isComplete(data, expectBodyShop)) break;
    }
    final result = _describe(last, expectBodyShop);
    if (_toastEnabled) {
      CustomToast.showGlobal(
        title: "WhatsApp status",
        message: result.message,
        type: result.type,
        duration: const Duration(seconds: 8),
      );
    }
  }

  static Future<Map<String, dynamic>?> _fetch(int jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      final response = await http
          .post(
            Uri.parse(ApiServices.bodyShopReferralStatus),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({"jobId": jobId}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is Map && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ------------------------------------------------------------------------------------------

  /// Customer rows that exist (link and/or PDF), in that order.
  static List<MapEntry<String, Map<String, dynamic>>> _customerRows(
      Map<String, dynamic> data) {
    final customer = data['customer'];
    if (customer is! Map) return const [];
    final rows = <MapEntry<String, Map<String, dynamic>>>[];
    for (final e in [
      MapEntry("Customer signature link", customer['link']),
      MapEntry("Customer PDF", customer['pdf']),
    ]) {
      final row = e.value;
      if (row is Map && row['requested'] == true) {
        rows.add(MapEntry(e.key, Map<String, dynamic>.from(row)));
      }
    }
    return rows;
  }

  static bool _isFinal(Map<String, dynamic> row) {
    final s = row['status'];
    return s != null && s != 'PENDING' && s != 'SENDING';
  }

  static bool _isComplete(Map<String, dynamic> data, bool expectBodyShop) {
    final customer = _customerRows(data);
    final customerDone =
        customer.isNotEmpty && customer.every((e) => _isFinal(e.value));
    final bodyShopDone = !expectBodyShop ||
        (data['requested'] == true && _isFinal(data));
    return customerDone && bodyShopDone;
  }

  static ({String message, ToastType type}) _describe(
      Map<String, dynamic>? data, bool expectBodyShop) {
    if (data == null) {
      return (
        message:
            "Could not read the WhatsApp status. The submission may still be uploading; check again on the job card later.",
        type: ToastType.info,
      );
    }
    final lines = <String>[];
    var worst = 0; // 0 success, 1 info, 2 warning, 3 error

    void add(String who, Map<String, dynamic>? row) {
      final r = _line(row);
      lines.add("$who: ${r.text}");
      if (r.level > worst) worst = r.level;
    }

    final customer = _customerRows(data);
    if (customer.isEmpty) {
      add("Customer", null);
    } else {
      for (final e in customer) {
        add(e.key, e.value);
      }
    }
    if (expectBodyShop) {
      add("Body Shop", data['requested'] == true ? data : null);
    }
    final reachedMeta = [
      ...customer.map((e) => e.value),
      if (expectBodyShop) data,
    ].any((r) =>
        r['status'] == 'ACCEPTED' ||
        _templateCodes.contains('${r['errorCode']}'));
    if (reachedMeta && worst > 0) {
      lines.add("Connection to WhatsApp is working.");
    }
    return (
      message: lines.join("\n"),
      type: switch (worst) {
        0 => ToastType.success,
        1 => ToastType.info,
        2 => ToastType.warning,
        _ => ToastType.error,
      },
    );
  }

  static ({String text, int level}) _line(Map<String, dynamic>? row) {
    if (row == null || row['requested'] != true) {
      return (
        text: "no result yet (submission may still be uploading)",
        level: 1
      );
    }
    final status = row['status'];
    final code = row['errorCode']?.toString();
    final msg = (row['message'] ?? '').toString();
    switch (status) {
      case 'ACCEPTED':
        final test = msg.toLowerCase().contains('test mode');
        return (
          text: test
              ? "accepted by WhatsApp (test mode: sent to the test number)"
              : "accepted by WhatsApp",
          level: 0
        );
      case 'PENDING':
      case 'SENDING':
        return (text: "still sending", level: 1);
      case 'SKIPPED':
        return (
          text: "not sent, WhatsApp is switched off on the server (WA_MODE=off)",
          level: 2
        );
      case 'NO_RECIPIENT':
        return (text: (row['statusLabel'] ?? 'no recipient').toString(), level: 2);
      default:
        if (code != null && _templateCodes.contains(code)) {
          return (
            text: "template not approved yet (Meta $code)",
            level: 2
          );
        }
        return (
          text: "failed: $msg${code == null ? '' : ' ($code)'}",
          level: 3
        );
    }
  }

  /// Compact form for the debug log (no phone numbers).
  static Map<String, dynamic> _summary(Map<String, dynamic> data) {
    String? s(dynamic row) =>
        row is Map && row['requested'] == true ? "${row['status']}${row['errorCode'] == null ? '' : ' ${row['errorCode']}'}" : null;
    final c = data['customer'];
    return {
      "customerLink": s(c is Map ? c['link'] : null),
      "customerPdf": s(c is Map ? c['pdf'] : null),
      "bodyShop": s(data),
      "whatsappEnabled": data['whatsappEnabled'],
    };
  }
}
