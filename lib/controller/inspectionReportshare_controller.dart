import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/model/apiResponsModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InspectionreportshareController extends ChangeNotifier {
  bool isLoading = false;

  Future<ApiResponse> shareInspectionSummary(
    int jobId, {
    required int attachmentMode,
    required int expiryHours,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('userToken');
      final requestBody = {
        "jobId": jobId,
        "expiryHours": expiryHours,
        "attachmentMode": attachmentMode,
      };
      final response = await http.post(
        Uri.parse(ApiServices.shareInspectionReport),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: jsonEncode(requestBody),
      );
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String? shareUrl = data['shareUrl'];
      if (shareUrl != null && shareUrl.isNotEmpty) {
        final String shareToken = shareUrl.split('/').last;
        final String baseUrl = dotenv.env['SHARE_URL'] ?? '';
        final String fullUrl = "$baseUrl/#/inspection-share/$shareToken";
        data['shareUrl'] = fullUrl;
      }
      return ApiResponse(
        success: true,
        statusCode: response.statusCode,
        data: data,
      );
    } catch (e) {
      return ApiResponse(success: false, statusCode: 500);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int mapModeToNumber(String mode) {
    const map = {'ALL': 0, 'NO_AUDIO': 1, 'NO_VIDEO': 2, 'NO_AUDIO_VIDEO': 3};
    return map[mode] ?? 0;
  }

  String formatExpiry(String? expiresAtStr) {
    if (expiresAtStr == null) return "";
    try {
      final expiresAt = DateTime.parse(expiresAtStr).toLocal();
      final now = DateTime.now();
      final diff = expiresAt.difference(now);
      if (diff.isNegative) return "Expired";
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final day = expiresAt.day;
      final month = _monthName(expiresAt.month);
      final year = expiresAt.year;
      return "$day $month $year, ${hours}h ${minutes.toString().padLeft(2, '0')}m";
    } catch (e) {
      return "";
    }
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }
}
