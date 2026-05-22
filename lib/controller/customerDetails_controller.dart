import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/controller/vehicleDetails_controller.dart';
import 'package:inspection/model/apiResponsModel.dart';
import 'package:inspection/utils/dummyDB/Dummydb.dart';
import 'package:inspection/apiServices/api_services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SearchSource { mobile, plate, none }

class CustomerDetailsController extends ChangeNotifier {
  VoidCallback? onVehicleSelected;
  List<Map<String, dynamic>> filteredVehicles = [];
  String? selectedVehicle;
  final DummyDB dummyDB = DummyDB();
  bool isAlreadyPresent = false;
  int? customerId;

  String? _selectedBrand;
  String? _selectedModel;
  String? _selectedModelYear;
  String _selectedCountryCode = '+971';
  String customerStatusLabel = "";
  String? get selectedBrand => _selectedBrand;
  String? get selectedModel => _selectedModel;
  String? get selectedModelYear => _selectedModelYear;
  String get selectedCountryCode => _selectedCountryCode;

  final TextEditingController mobileNumController = TextEditingController();
  TextEditingController vehiclePlateController = TextEditingController();
  final TextEditingController engineController = TextEditingController();

  List<String> brandList = [];
  List<String> modelList = [];
  List<String> regNoSuggestions = [];
  List<String> transmissionList = [];
  bool isLoading = false;

  List<Map<String, String>> fuelTypeList = [];
  List<Map<String, String>> transmissionTypeList = [];
  List<Map<String, String>> serviceTypeList = [];

  String? selectedFuelId;
  String? selectedTransmissionId;
  String selectedServiceTypeId = "";

  Timer? _debounce;
  SearchSource lastSearchSource = SearchSource.none;
  String? _lastConfirmedMobile;
  String? _lastConfirmedCountryCode;
  String _lastPlateQuery = '';
  String _activeRequest = "";

  final Map<String, List<String>> _cache = {};
  bool isSearching = false;

  String get selectedCountryFlag {
    final country = dummyDB.countryMobileNumberCodeList.firstWhere(
      (item) => item['code'] == _selectedCountryCode,
      orElse: () => {'flag': '🏳️'},
    );
    return country['flag']!;
  }

  void markCustomerConfirmed() {
    _lastConfirmedMobile = mobileNumController.text.trim();
    _lastConfirmedCountryCode = selectedCountryCode;
  }

  bool hasMobileChanged() {
    return _lastConfirmedMobile != mobileNumController.text.trim() ||
        _lastConfirmedCountryCode != selectedCountryCode;
  }

  void setBrand(String value) {
    _selectedBrand = value;
    notifyListeners();
  }

  void setModel(String? value) {
    _selectedModel = value;
    notifyListeners();
  }

  void setModelYear(String? value) {
    _selectedModelYear = value;
    notifyListeners();
  }

  void setCountryCode(String code) {
    _selectedCountryCode = code;
    notifyListeners();
  }

  void clearSelectedVehicle() {
    selectedVehicle = null;
    notifyListeners();
  }

  Future<void> postVehicleRegNoList(String data) async {
    try {
      final currentRequest = data;
      isSearching = true;
      notifyListeners();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      final response = await http.post(
        Uri.parse(ApiServices.searchVehicleRegNo),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode({"vRegNo": data}),
      );
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        List<String> results = (res['data'] as List)
            .map((e) => e.toString())
            .toList();
        if (currentRequest != _activeRequest) return;
        _cache[data] = results;
        regNoSuggestions = results;
      } else {
        regNoSuggestions.clear();
      }
    } catch (e) {
      regNoSuggestions.clear();
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  Future<void> getBrandList() async {
    isLoading = true;
    notifyListeners();
    final url = Uri.parse(ApiServices.vehicleBrand);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      var response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        brandList = res['data'].cast<String>();
      } else {
        brandList = [];
      }
    } catch (e) {
      brandList = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> postModelList(String brand) async {
    isLoading = true;
    notifyListeners();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      final response = await http.post(
        Uri.parse(ApiServices.vechileMode),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode({"brand": brand}),
      );
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        modelList = (res['data'] as List)
            .map((e) => e.toString())
            .toSet()
            .toList();
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Model fetch error: $e");
    }
    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> getFuelTypeList({String? defaultFuel}) async {
    isLoading = true;
    notifyListeners();
    final url = Uri.parse(ApiServices.fuelList);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        fuelTypeList = (res['data'] as List)
            .map(
              (item) => {
                "id": item["futId"].toString(),
                "label": item["futName"].toString(),
              },
            )
            .toList();
        if (defaultFuel != null &&
            fuelTypeList.any((e) => e["id"] == defaultFuel)) {
          selectedFuelId = defaultFuel;
        } else {
          final petrol = fuelTypeList.firstWhere(
            (e) => e["label"]!.toLowerCase() == "Petrol",
            orElse: () => fuelTypeList.first,
          );
          selectedFuelId = petrol["id"];
        }
      } else {
        fuelTypeList = [];
      }
    } catch (e) {
      fuelTypeList = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> getTransmissionList({String? defaultValue}) async {
    final url = Uri.parse(ApiServices.transmissionList);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        transmissionTypeList = (res["data"] as List)
            .map(
              (item) => {
                "id": item["trtId"].toString(),
                "label": item["trtName"].toString(),
              },
            )
            .toList();
        if (defaultValue != null &&
            transmissionTypeList.any((e) => e["id"] == defaultValue)) {
          selectedTransmissionId = defaultValue;
        } else {
          final amt = transmissionTypeList.firstWhere(
            (e) => e["label"]!.toLowerCase() == "AMT",
            orElse: () => transmissionTypeList.first,
          );
          selectedTransmissionId = amt["id"];
        }
      }
    } catch (e) {
      print("Transmission error: $e");
    }
    notifyListeners();
  }

  Future<void> getServiceTypeList({String? defaultValue}) async {
    final url = Uri.parse(ApiServices.serviceTypeList);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      if (userToken == null || userToken.isEmpty) {
        notifyListeners();
        return;
      }
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res["data"] == null) {
          serviceTypeList = [];
        } else if ((res["data"] as List).isEmpty) {
          serviceTypeList = [];
        } else {
          serviceTypeList = (res["data"] as List)
              .map(
                (item) => {
                  "id": item["sttId"].toString(),
                  "label": item["sttName"].toString(),
                },
              )
              .toList();
        }
        if (defaultValue != null) {
          final bool exists = serviceTypeList.any(
            (e) => e["id"] == defaultValue,
          );

          if (exists) {
            selectedServiceTypeId = defaultValue;
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint("📍 StackTrace: $stackTrace");
    }
    notifyListeners();
  }

  void setFuelType(String? value) {
    selectedFuelId = value;
    notifyListeners();
  }

  void setTransmission(String? value) {
    if (value == null) {
      selectedTransmissionId = null;
      notifyListeners();
      return;
    }
    final exists = transmissionTypeList.any((e) => e["id"] == value);
    if (exists) {
      selectedTransmissionId = value;
    } else {
      selectedTransmissionId = null;
    }
    notifyListeners();
  }

  void setServiceType(String value) {
    selectedServiceTypeId = value;
    notifyListeners();
  }

  Future<bool> postPhonePlateNumber(BuildContext context) async {
    isLoading = true;
    notifyListeners();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      final url = Uri.parse(ApiServices.fetchCustomerVehicleDetails);
      final body = {
        "custMobile": mobileNumController.text.trim(),
        "regNo": vehiclePlateController.text.trim(),
      };
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode(body),
      );
      final decoded = jsonDecode(response.body);
      final int apiStatusCode = decoded["statusCode"];
      if (apiStatusCode == 1005) {
        _handleNewCustomer();
        return false;
      }
      if (apiStatusCode == 200) {
        _handleExistingCustomer(decoded["data"], context);
        return true;
      }
      _resetLoading();
      return false;
    } catch (e) {
      _resetLoading();
      return false;
    }
  }

  void searchByMobileDebounced(BuildContext context) {
    lastSearchSource = SearchSource.mobile;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mobileNumController.text.trim().length >= 7) {
        postPhonePlateNumber(context);
      }
    });
  }

  void searchByPlateDebounced(BuildContext context) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      final text = vehiclePlateController.text.trim();
      if (text == _lastPlateQuery) return;
      _lastPlateQuery = text;
      if (text.length >= 2) {
        if (_cache.containsKey(text)) {
          regNoSuggestions = _cache[text]!;
          notifyListeners();
          return;
        }
        _activeRequest = text;
        postVehicleRegNoList(text);
      } else {
        regNoSuggestions.clear();
        notifyListeners();
      }
    });
  }

  CustomerDetailsController() {
    vehiclePlateController.addListener(_onPlateChanged);
  }

  void _onPlateChanged() {
    final text = vehiclePlateController.text.trim();
    if (text.isEmpty) {
      filteredVehicles.clear();
      selectedVehicle = null;
      notifyListeners();
      return;
    }
    final lower = text.toLowerCase();
    filteredVehicles = filteredVehicles.where((vehicle) {
      final reg = vehicle["vRegNo"].toString().toLowerCase();
      return reg.contains(lower);
    }).toList();
    notifyListeners();
  }

  void _handleNewCustomer() {
    customerStatusLabel = "New Customer";
    resetForNewCustomer();
    filteredVehicles.clear();
    selectedVehicle = null;
    isAlreadyPresent = false;
    _resetLoading();
  }

  void _handleExistingCustomer(
    Map<String, dynamic>? cust,
    BuildContext context,
  ) {
    if (cust == null) {
      _resetLoading();
      return;
    }
    final vehicleCtrl = context.read<VehicleDetailsController>();
    final String? apiMobile = cust["custMobile"];
    final String? apiCountryCode = cust["custCountryCode"];
    if (apiMobile != null && apiMobile.isNotEmpty) {
      mobileNumController.text = apiMobile;
    }
    if (apiCountryCode != null && apiCountryCode.isNotEmpty) {
      _selectedCountryCode = "+$apiCountryCode";
    }
    vehicleCtrl.nameController.text = cust["custName"] ?? "";
    vehicleCtrl.selectedCustomerTypeId = cust["custType"] ?? "";
    vehicleCtrl.selectedLanguages = cust["custLanguage"] ?? "";
    customerId = cust["custId"];
    filteredVehicles.clear();
    regNoSuggestions.clear();
    if (cust["vehicles"] is List) {
      for (var v in cust["vehicles"]) {
        final regNo = v["regNo"] ?? "";
        filteredVehicles.add({
          "vId": v["vehicleId"],
          "vRegNo": regNo,
          "vMake": v["make"],
          "vModel": v["model"],
          "vModelYear": v["modelYear"],
          "vEng": v["engineNo"],
          "vVinNo": v["vVinNo"],
          "vOdometer": v["odometer"],
          "vRegNoImg": v["vRegNoImg"],
          "vVinImg": v["vVinImg"],
        });
        regNoSuggestions.add(regNo);
      }
    }
    if (filteredVehicles.isNotEmpty) {
      selectedVehicle = filteredVehicles.first["vId"].toString();
      onVehicleSelected?.call();
    }
    customerStatusLabel = "Existing Customer";
    isAlreadyPresent = true;
    notifyListeners();
    _resetLoading();
  }

  Map<String, dynamic>? getSelectedVehicleData() {
    if (selectedVehicle == null) return null;
    return filteredVehicles.firstWhere(
      (v) => v["vId"].toString() == selectedVehicle,
      orElse: () => {},
    );
  }

  void setSelectedVehicle(String? value) {
    selectedVehicle = value;
    notifyListeners();
  }

  void _resetLoading() {
    isLoading = false;
    notifyListeners();
  }

  Future<ApiResponse> postCustomerVehicleDetails(
    Map<String, dynamic>? data,
  ) async {
    isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      if (token == null) {
        return ApiResponse(success: false, status: "Token Is Null");
      }
      final apiData = data?["apiData"];
      final Map<String, dynamic> payload = {
        "vehicleId": apiData?["vehicleId"] ?? "",
        "customerId": apiData?["customerId"] ?? "",
        "jobcardId": apiData?["jobcardId"] ?? "",
        "vMake": _selectedBrand,
        "vModel": _selectedModel,
        "vModelYear": _selectedModelYear,
        "vEng": engineController.text.trim(),
        "vFuelTypeId": selectedFuelId,
        "vTransmissionTypeId": selectedTransmissionId,
        "vTypeId": selectedServiceTypeId,
        "status": 1,
      };
      final url = Uri.parse(ApiServices.updateOpenJobcard);
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode != 200) {
        return ApiResponse(success: false, status: response.body);
      }
      final result = jsonDecode(response.body);
      return ApiResponse(
        success: result["statusCode"] == 200,
        statusCode: result['statusCode'],
        timeStamp: result['timeStamp'],
        status: result['status'],
        data: result['data'],
      );
    } catch (e) {
      return ApiResponse(success: false, status: e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int? resolveCustomerId() {
    if (isAlreadyPresent && customerId != null) {
      return customerId;
    }
    return null;
  }

  void resetForNewCustomer() {
    engineController.clear();
    _selectedModel = null;
    _selectedModelYear = null;
    selectedFuelId = null;
    selectedTransmissionId = null;
    selectedServiceTypeId = "";
    filteredVehicles = [];
    selectedVehicle = null;
    customerId = null;
    isAlreadyPresent = false;
    notifyListeners();
  }

  void clearAllData(BuildContext context) {
    final customerCtrl = context.read<CustomerDetailsController>();
    final vehicleCtrl = context.read<VehicleDetailsController>();
    customerCtrl.mobileNumController.clear();
    customerCtrl.vehiclePlateController.clear();
    customerCtrl.setCountryCode('+971');
    customerCtrl.selectedVehicle = null;
    customerCtrl.filteredVehicles.clear();
    customerCtrl.customerStatusLabel = "";
    customerCtrl.resetForNewCustomer();
    vehicleCtrl.clearAll(context);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    vehiclePlateController.dispose();
    super.dispose();
  }
}
