import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/model/customer_inspection_history_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerInspectionHistoryController extends ChangeNotifier {
  bool isLoading = false;
  bool isMoreLoading = false;
  bool hasMore = false;
  int currentPage = 0;
  final int pageSize = 20;
  int totalElements = 0;
  int totalPages = 0;
  String? errorMsg;

  int? currentCustomerId;
  int? currentJobId;
  String? currentCustomerMobile;
  String? customerName;
  String? customerMobile;
  bool isExistingCustomer = false;

  List<CustomerInspectionHistoryModel> historyList = [];

  Future<void> fetchHistory({
    int? customerId,
    int? jobId,
    String? customerMobile,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      currentPage = 0;
      historyList.clear();
      hasMore = false;
    }

    currentCustomerId = customerId ?? currentCustomerId;
    currentJobId = jobId ?? currentJobId;
    currentCustomerMobile = customerMobile ?? currentCustomerMobile;

    isLoading = true;
    errorMsg = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');

      final body = {
        if (currentCustomerId != null) "customerId": currentCustomerId,
        if (currentJobId != null) "jobId": currentJobId,
        if (currentJobId != null) "excludeJobId": currentJobId,
        if (currentCustomerMobile != null && currentCustomerMobile!.isNotEmpty)
          "customerMobile": currentCustomerMobile,
        "page": 0,
        "size": pageSize,
      };

      final response = await http.post(
        Uri.parse(ApiServices.getPreviousInspectionHistory),
        headers: {
          "Content-Type": "application/json",
          if (userToken != null && userToken.isNotEmpty)
            "Authorization": "Bearer $userToken",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded["statusCode"] == 200 && decoded["data"] != null) {
          final historyData = CustomerInspectionHistoryResponse.fromJson(decoded["data"]);
          historyList = historyData.content;
          currentPage = historyData.page;
          totalElements = historyData.totalElements;
          totalPages = historyData.totalPages;
          hasMore = historyData.hasMore;
          isExistingCustomer = historyData.isExistingCustomer;
          customerName = historyData.customerName ?? customerName;
          this.customerMobile = historyData.customerMobile ?? this.customerMobile;
        } else {
          errorMsg = decoded["message"]?.toString() ?? "Failed to fetch inspection history";
        }
      } else {
        errorMsg = "Server error (${response.statusCode})";
      }
    } catch (e) {
      errorMsg = "Network error: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isMoreLoading || !hasMore || isLoading) return;

    isMoreLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');

      final nextPage = currentPage + 1;
      final body = {
        if (currentCustomerId != null) "customerId": currentCustomerId,
        if (currentJobId != null) "jobId": currentJobId,
        if (currentJobId != null) "excludeJobId": currentJobId,
        if (currentCustomerMobile != null && currentCustomerMobile!.isNotEmpty)
          "customerMobile": currentCustomerMobile,
        "page": nextPage,
        "size": pageSize,
      };

      final response = await http.post(
        Uri.parse(ApiServices.getPreviousInspectionHistory),
        headers: {
          "Content-Type": "application/json",
          if (userToken != null && userToken.isNotEmpty)
            "Authorization": "Bearer $userToken",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded["statusCode"] == 200 && decoded["data"] != null) {
          final historyData = CustomerInspectionHistoryResponse.fromJson(decoded["data"]);
          historyList.addAll(historyData.content);
          currentPage = historyData.page;
          totalElements = historyData.totalElements;
          totalPages = historyData.totalPages;
          hasMore = historyData.hasMore;
        }
      }
    } catch (e) {
      // Ignore load more error or show banner
    } finally {
      isMoreLoading = false;
      notifyListeners();
    }
  }
}
