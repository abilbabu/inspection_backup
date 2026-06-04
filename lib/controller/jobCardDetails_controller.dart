import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/customerDetails_controller.dart';
import 'package:inspection/model/apiResponsModel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class JobcarddetailsController extends ChangeNotifier {
  bool isLoading = false;
  bool hasLoaded = false;

  Map<String, dynamic>? jobCardData;
  Map<String, dynamic>? technicianData;
  Map<String, dynamic>? supervisorData;
  int? userDepartment;

  String fuelTypeName = "";
  String transmissionTypeName = "";
  String customerTypeName = "";
  String serviceTypeName = "";

  List fuelList = [];
  List transmissionList = [];
  List customerTypeList = [];
  List serviceTypeList = [];
  List<Map<String, dynamic>> jobcardList = [];
  bool isJobcardLoading = false;
  bool isTechnicianAssigned = false;
  int? assignedTechnicianId;
  int? jobSuperVisorId;
  String? assignedTechnicianName;
  bool isDownloading = false;

  Future<ApiResponse> postJobCardDetails(int jobId) async {
    if (hasLoaded && jobCardData != null) {
      return ApiResponse(success: true, data: jobCardData);
    }
    hasLoaded = true;
    isLoading = true;
    notifyListeners();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      if (userToken == null || userToken.isEmpty) {
        isLoading = false;
        notifyListeners();
        return ApiResponse(success: false, status: "No Token Found");
      }
      final url = Uri.parse(ApiServices.getCustomerVehicleByJobId);
      final body = {"jobId": jobId};
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode(body),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        jobCardData = decoded['data'];
        isLoading = false;
        final jobcard = jobCardData!["jobcard"];
        technicianData = jobcard["jobTechnicianId"];
        supervisorData = jobcard["jobSuperVisorId"];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        userDepartment =
            int.tryParse(prefs.getString("userDepartment") ?? "0") ?? 0;
        if (technicianData != null) {
          isTechnicianAssigned = true;
        } else {
          isTechnicianAssigned = false;
        }
        if (technicianData != null) {
          assignedTechnicianId = technicianData!["userId"];
          assignedTechnicianName = technicianData!["userName"] ?? "";
        }
        if (supervisorData != null) {
          jobSuperVisorId = supervisorData!["userId"];
        }
        notifyListeners();
        return ApiResponse(
          success: true,
          data: decoded['data'],
          status: decoded['status'],
          timeStamp: decoded['timeStamp'],
          statusCode: decoded['statusCode'],
        );
      }
      isLoading = false;
      notifyListeners();
      return ApiResponse(success: false, status: decoded['status']);
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return ApiResponse(success: false, status: "Unexpected Error");
    }
  }

  Map<String, dynamic>? _findById(List list, int id) {
    for (final item in list) {
      if (item is Map && int.tryParse(item['id'].toString()) == id) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  void setDownloading(bool value) {
    isDownloading = value;
    notifyListeners();
  }

  void mapFuelAndTransmissionNames(CustomerDetailsController custCtrl) {
    if (jobCardData == null) return;
    fuelList = custCtrl.fuelTypeList;
    transmissionList = custCtrl.transmissionTypeList;
    serviceTypeList = custCtrl.serviceTypeList;
    final jobcard = jobCardData?['jobcard'];
    final vehicle = jobcard?['vehicle'];
    final customer = jobcard?['customer'];
    final fuelId = int.tryParse(vehicle?['vFuelTypeId']?.toString() ?? '') ?? 0;
    final transId =
        int.tryParse(vehicle?['vTransmissionTypeId']?.toString() ?? '') ?? 0;
    final custTypeId =
        int.tryParse(customer?['custType']?.toString() ?? '') ?? 0;
    final serviceTypeId =
        int.tryParse(vehicle?['vTypeId']?.toString() ?? '') ?? 0;
    fuelTypeName = _findById(fuelList, fuelId)?['label'] ?? 'N/A';
    transmissionTypeName =
        _findById(transmissionList, transId)?['label'] ?? 'N/A';
    customerTypeName =
        _findById(customerTypeList, custTypeId)?['label'] ?? 'N/A';
    serviceTypeName =
        _findById(serviceTypeList, serviceTypeId)?['label'] ?? 'N/A';
    notifyListeners();
  }

  void reset() {
    jobCardData = null;
    fuelTypeName = "";
    transmissionTypeName = "";
    customerTypeName = "";
    serviceTypeName = "";
    notifyListeners();
    hasLoaded = false;
    isLoading = false;
  }

  Future<String?> downloadInspectionPdf(int jobId, String phone) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('userToken');
      if (token == null) return null;
      final dio = Dio();
      final response = await dio.post(
        ApiServices.generateInspectionPdf,
        data: {"orderId": jobId},
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          responseType: ResponseType.bytes,
        ),
      );
      if (response.statusCode != 200 || response.data == null) {
        return null;
      }
      Directory dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final jobCardNumber =
          jobCardData?['jobcard']?['jobCardNo']?.toString() ?? jobId.toString();
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      final baseName = "ALMJBC-$jobCardNumber($cleanPhone)";
      int count = 1;
      String filePath = "";
      while (true) {
        final suffix = count.toString().padLeft(2, '0');
        filePath = "${dir.path}/$baseName$suffix.pdf";
        final file = File(filePath);
        if (!await file.exists()) {
          await file.writeAsBytes(response.data, flush: true);
          break;
        }
        count++;
      }
      return filePath;
    } catch (e) {
      print("PDF Download Error: $e");
      return null;
    }
  }

  String formatPhone(String code, String mobile) {
    String cleanCode = code.replaceAll("+", "");
    String cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    if (cleanMobile.startsWith("0")) {
      cleanMobile = cleanMobile.substring(1);
    }
    return "$cleanCode$cleanMobile";
  }

  Future<void> openWhatsApp(String phone, String message) async {
    final Uri url = Uri.parse(
      "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}",
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> getInspectionListByUserId() async {
    isLoading = true;
    isJobcardLoading = true;
    notifyListeners();
    final url = Uri.parse(ApiServices.allInspectionList);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      String? userId = prefs.getString('userId');
      if (userId == null) {
        isLoading = false;
        isJobcardLoading = false;
        notifyListeners();
        return;
      }
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode({"userId": int.parse(userId)}),
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        final List rawList = res["data"] ?? [];
        jobcardList = rawList
            .where((item) {
              final int status =
                  int.tryParse(item["jobStatus"]?.toString() ?? "") ?? -1;
              return ![0, 1, 2, -1].contains(status);
            })
            .map<Map<String, dynamic>>((item) {
              final vehicle = item["vehicle"] ?? {};
              return {
                "jobId": item["jobId"]?.toString() ?? "",
                "jobNo": item["jobNo"]?.toString() ?? "",
                "make": vehicle["vMake"] ?? "",
                "model": vehicle["vModel"] ?? "",
                "year": vehicle["vModelYear"]?.toString() ?? "",
                "odometer": vehicle["vOdometer"]?.toString() ?? "",
                "plateNo": vehicle["vRegNo"]?.toString() ?? "",
                "vinNo": vehicle["vVinNo"]?.toString() ?? "",
                "jobStatus": item["jobStatus"]?.toString() ?? "",
                "vehicleTypeId": vehicle["vTypeId"] ?? -1,
                "jobCreatedOn": item["jobCreatedOn"] ?? "",
                "jobTechnicianId": item["jobTechnicianId"],
                "inspections": item["inspections"] ?? [],
              };
            })
            .toList();
      }
    } catch (e) {
      print("❗ EXCEPTION: $e");
    }
    isLoading = false;
    isJobcardLoading = false;
    notifyListeners();
  }
}
