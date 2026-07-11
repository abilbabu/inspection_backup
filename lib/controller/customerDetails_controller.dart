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
  List<Map<String, dynamic>> allCustomerVehicles = [];
  String? selectedVehicle;
  bool _isModelLoading = false;
  bool get isModelLoading => _isModelLoading;

  final DummyDB dummyDB = DummyDB();
  bool isAlreadyPresent = false;
  int? customerId;

  bool get isVehicleAlreadyPresent {
    return selectedVehicle != null && selectedVehicle != "new";
  }

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
  List<String> filterPlateSuggestions(String query) {
    if (query.trim().length < 2) {
      return [];
    }

    String normalize(String val) {
      return val.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    }

    final q = query.toLowerCase().trim();
    final normalizedQ = normalize(q);

    final matches = regNoSuggestions.where((plate) {
      return normalize(plate).contains(normalizedQ);
    }).toList();

    String getNumericPart(String plate) {
      return plate.replaceAll(RegExp(r'\D'), '');
    }

    final isQueryNumeric = RegExp(r'^\d+$').hasMatch(normalizedQ);

    matches.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();

      if (isQueryNumeric) {
        final numPartA = getNumericPart(aLower);
        final numPartB = getNumericPart(bLower);

        final idxA = numPartA.indexOf(normalizedQ);
        final idxB = numPartB.indexOf(normalizedQ);

        final effectiveIdxA = idxA == -1 ? 999 : idxA;
        final effectiveIdxB = idxB == -1 ? 999 : idxB;

        if (effectiveIdxA != effectiveIdxB) {
          return effectiveIdxA.compareTo(effectiveIdxB);
        }

        if (numPartA.length != numPartB.length) {
          return numPartA.length.compareTo(numPartB.length);
        }
      } else {
        final normA = normalize(aLower);
        final normB = normalize(bLower);

        final idxA = normA.indexOf(normalizedQ);
        final idxB = normB.indexOf(normalizedQ);

        final effectiveIdxA = idxA == -1 ? 999 : idxA;
        final effectiveIdxB = idxB == -1 ? 999 : idxB;

        if (effectiveIdxA != effectiveIdxB) {
          return effectiveIdxA.compareTo(effectiveIdxB);
        }

        if (normA.length != normB.length) {
          return normA.length.compareTo(normB.length);
        }
      }

      return aLower.compareTo(bLower);
    });

    if (matches.isEmpty) {
      if (isSearching) {
        return ["Loading..."];
      } else {
        return ["No Data Found"];
      }
    }

    return matches;
  }

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
    _selectedModel = null;
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
        notifyListeners();
        // Trigger RawAutocomplete to rebuild options by notifying text editing controller
        _forceRebuildSuggestions();
      } else {
        regNoSuggestions.clear();
        notifyListeners();
      }
    } catch (e) {
      regNoSuggestions.clear();
      notifyListeners();
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
      // log(response.body);
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
    _isModelLoading = true;
    notifyListeners();
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userToken = prefs.getString('userToken');
      final url = ApiServices.vehicleModel;
      final headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $userToken",
      };
      final body = jsonEncode({"brand": brand});
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        modelList = (res['data'] as List)
            .where((e) => e != null)
            .map((e) => e.toString())
            .toSet()
            .toList();
        _isModelLoading = false;
        notifyListeners();
        return true;
      } else {
        print("Failed to load models. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Model fetch error: $e");
    }
    _isModelLoading = false;
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
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final text = vehiclePlateController.text.trim();

      if (text == _lastPlateQuery) return;
      _lastPlateQuery = text;

      // Don't search for empty or single character query
      if (text.length < 2) {
        regNoSuggestions.clear();
        notifyListeners();
        return;
      }

      // Return cached result
      if (_cache.containsKey(text)) {
        regNoSuggestions = _cache[text]!;
        notifyListeners();
        // Trigger RawAutocomplete update
        _forceRebuildSuggestions();
        return;
      }

      _activeRequest = text;
      postVehicleRegNoList(text);
    });
  }

  void _forceRebuildSuggestions() {
    final text = vehiclePlateController.text;
    if (text.isEmpty) return;

    final originalValue = vehiclePlateController.value;
    final tempOffset = originalValue.selection.baseOffset > 0 ? 0 : 1;
    if (tempOffset <= text.length) {
      vehiclePlateController.value = originalValue.copyWith(
        selection: TextSelection.collapsed(offset: tempOffset),
      );
    }
    vehiclePlateController.value = originalValue;
  }

  CustomerDetailsController() {
    vehiclePlateController.addListener(_onPlateChanged);
  }

  void _onPlateChanged() {
    final text = vehiclePlateController.text.trim();
    if (text.isEmpty) {
      filteredVehicles = List.from(allCustomerVehicles);
      if (filteredVehicles.isNotEmpty) {
        selectedVehicle = filteredVehicles.first["vId"].toString();
      } else {
        selectedVehicle = null;
      }
      notifyListeners();
      return;
    }

    String normalize(String val) {
      return val.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    }

    final normalizedText = normalize(text);
    filteredVehicles = allCustomerVehicles.where((vehicle) {
      final reg = normalize(vehicle["vRegNo"].toString());
      return reg.contains(normalizedText);
    }).toList();
    if (filteredVehicles.isNotEmpty) {
      selectedVehicle = filteredVehicles.first["vId"].toString();
    } else {
      selectedVehicle = null;
    }
    notifyListeners();
  }

  void _handleNewCustomer() {
    customerStatusLabel = "New Customer";
    resetForNewCustomer();
    filteredVehicles.clear();
    allCustomerVehicles.clear();
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
    allCustomerVehicles.clear();
    regNoSuggestions.clear();
    if (cust["vehicles"] is List) {
      for (var v in cust["vehicles"]) {
        final regNo = v["regNo"] ?? "";
        final vehicleData = {
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
        };
        filteredVehicles.add(vehicleData);
        allCustomerVehicles.add(vehicleData);
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
    allCustomerVehicles = [];
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
    customerCtrl.allCustomerVehicles.clear();
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
