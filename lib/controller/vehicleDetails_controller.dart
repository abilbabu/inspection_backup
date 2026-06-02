import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/customerDetails_controller.dart';
import 'package:inspection/model/apiResponsModel.dart';
import 'package:inspection/utils/dummyDB/Dummydb.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParsedPlate {
  final bool isValid;
  final String? emirate;
  final String? code;
  final String? number;

  ParsedPlate.valid(this.emirate, this.code, this.number) : isValid = true;

  ParsedPlate.invalid()
    : isValid = false,
      emirate = null,
      code = null,
      number = null;
}

class VehicleSnapshot {
  final String vin;
  final String plate;
  final String odometer;
  final String mobile;
  final String countryCode;
  final int? vehicleId;
  final int? customerId;
  final int? jobcardId;
  final String? vinImageUrl;
  final String? plateImageUrl;

  VehicleSnapshot({
    required this.vin,
    required this.plate,
    required this.odometer,
    required this.mobile,
    required this.countryCode,
    this.vehicleId,
    this.customerId,
    this.jobcardId,
    this.vinImageUrl,
    this.plateImageUrl,
  });
}

class VehicleDetailsController with ChangeNotifier {
  double fuelValue = 0;
  List<String> fuelMarks = ["E", "1/4", "1/2", "3/4", "F"];

  final DummyDB dummyDB = DummyDB();
  final TextEditingController vinController = TextEditingController();
  final TextEditingController odometerController = TextEditingController();
  final TextEditingController plateController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormFieldState<String>> regKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> vinKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> oddKey =
      GlobalKey<FormFieldState<String>>();

  File? vinImage;
  File? odometerImage;
  File? plateImage;
  File? vinDisplayImage;
  File? plateDisplayImage;
  File? odometerDisplayImage;

  int? custId;
  VehicleSnapshot? _lastSubmittedSnapshot;

  String? custName;
  String? custType;
  String? custLanguage;
  String? _vinImageUrl;
  String? _plateImageUrl;
  String? get vinImageUrl => _vinImageUrl;
  String? get plateImageUrl => _plateImageUrl;
  String? selectedCustomerTypeId;
  String? selectedEmirate = "AUH";
  String? selectedPlateCode;
  String selectedLanguages = "EN";
  String get selectedLanguage => selectedLanguages;

  bool isScanning = false;
  bool isLoading = false;
  bool isSuccess = false;
  bool isAlreadyPresent = false;
  List<Map<String, String>> customerTypeList = [];

  Future<void> getCustomerTypeList({String? defaultValue}) async {
    final url = Uri.parse(ApiServices.customerTypeList);
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
        if (res["data"] == null || res["data"].isEmpty) {
          customerTypeList = [];
        } else {
          customerTypeList = (res["data"] as List)
              .map(
                (item) => {
                  "id": item["cttId"].toString(),
                  "label": item["cttName"].toString(),
                },
              )
              .toList();
        }
        customerTypeList.firstWhere(
          (e) => e["label"]!.toLowerCase() == "normal",
          orElse: () => {},
        );

        if (defaultValue != null && defaultValue.isNotEmpty) {
          final bool exists = customerTypeList.any(
            (e) => e["id"] == defaultValue,
          );
          if (exists) {
            selectedCustomerTypeId = defaultValue;
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint("📍 StackTrace: $stackTrace");
    }
    notifyListeners();
  }

  void setCustomerType(String? id) {
    selectedCustomerTypeId = id;
    notifyListeners();
  }

  void setLanguage(String lang) {
    selectedLanguages = lang;
    notifyListeners();
  }

  void setLoading() {
    isLoading = true;
    notifyListeners();
  }

  void setSuccess() {
    isSuccess = true;
    notifyListeners();
  }

  void resetStatus() {
    isLoading = false;
    isSuccess = false;
  }

  VehicleDetailsController() {
    selectedPlateCode = PlateDummyDB.numericCodes.first;
  }

  List<String> get plateCodeList {
    return PlateDummyDB.getCodesByEmirate(selectedEmirate!);
  }

  void setEmirate(String value) {
    selectedEmirate = value;
    final codes = PlateDummyDB.getCodesByEmirate(value);
    selectedPlateCode = codes.isNotEmpty ? codes.first : null;
    notifyListeners();
  }

  void setPlateCode(String value) {
    selectedPlateCode = value;
    notifyListeners();
  }

  set vinImageUrl(String? value) {
    _vinImageUrl = value;
    notifyListeners();
  }

  set plateImageUrl(String? value) {
    _plateImageUrl = value;
    notifyListeners();
  }

  ParsedPlate parseUaePlate(String plate) {
    final value = plate.trim().toUpperCase();
    final regex = RegExp(
      r'^(AUH|DXB|SHJ|AJM|RAK|FUJ|UAQ|RAK)\s+([A-Z]{1,2}|\d{1,2})\s+(\d{2,5})$',
    );
    final match = regex.firstMatch(value);
    if (match == null) {
      return ParsedPlate.invalid();
    }
    return ParsedPlate.valid(match.group(1), match.group(2), match.group(3));
  }

  void restorePlateFromApiSmart(String plate) {
    if (plate.trim().isEmpty) return;
    final parsed = parseUaePlate(plate);
    if (!parsed.isValid) {
      plateController.text = plate;
      selectedEmirate = null;
      selectedPlateCode = null;
      plateImageUrl = null;
      notifyListeners();
      return;
    }
    selectedEmirate = parsed.emirate;
    final codes = PlateDummyDB.getCodesByEmirate(parsed.emirate!);
    selectedPlateCode = codes.contains(parsed.code) ? parsed.code : codes.first;
    plateController.text = parsed.number!;
    notifyListeners();
  }

  String get fullPlateNumber {
    final emirate = selectedEmirate ?? '';
    final code = selectedPlateCode ?? '';
    final number = plateController.text.trim();
    return [emirate, code, number].where((e) => e.isNotEmpty).join(' ');
  }

  void saveSnapshot(
    CustomerDetailsController customerCtrl,
    Map<String, dynamic> apiData,
  ) {
    _lastSubmittedSnapshot = VehicleSnapshot(
      vin: vinController.text.trim(),
      plate: fullPlateNumber,
      odometer: odometerController.text.trim(),
      mobile: customerCtrl.mobileNumController.text.trim(),
      countryCode: customerCtrl.selectedCountryCode,
      vehicleId: apiData["vehicleId"],
      customerId: apiData["customerId"],
      jobcardId: apiData["jobcardId"],
      vinImageUrl: vinImageUrl,
      plateImageUrl: plateImageUrl,
    );
  }

  VehicleSnapshot? getLastSnapshot() {
    return _lastSubmittedSnapshot;
  }

  bool hasCustomerChanged(CustomerDetailsController customerCtrl) {
    if (_lastSubmittedSnapshot == null) return true;
    return _lastSubmittedSnapshot!.mobile !=
            customerCtrl.mobileNumController.text.trim() ||
        _lastSubmittedSnapshot!.countryCode != customerCtrl.selectedCountryCode;
  }

  bool hasVehicleChanged() {
    if (_lastSubmittedSnapshot == null) return true;
    final bool textChanged =
        vinController.text.trim() != _lastSubmittedSnapshot!.vin ||
        fullPlateNumber != _lastSubmittedSnapshot!.plate ||
        odometerController.text.trim() != _lastSubmittedSnapshot!.odometer;
    final bool imageChanged =
        vinImage != null || plateImage != null || odometerImage != null;
    return textChanged || imageChanged;
  }

  void restoreFromSnapshot() {
    if (_lastSubmittedSnapshot == null) return;
    vinController.text = _lastSubmittedSnapshot!.vin;
    odometerController.text = _lastSubmittedSnapshot!.odometer;
    restorePlateFromApiSmart(_lastSubmittedSnapshot!.plate);
    vinImageUrl = _lastSubmittedSnapshot!.vinImageUrl;
    plateImageUrl = _lastSubmittedSnapshot!.plateImageUrl;
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }

  bool hasAllMandatoryImages() {
    final bool hasVin =
        vinImage != null || vinDisplayImage != null || vinImageUrl != null;
    final bool hasPlate =
        plateImage != null ||
        plateDisplayImage != null ||
        plateImageUrl != null;
    final bool hasOdometer =
        odometerImage != null || odometerDisplayImage != null;
    return hasVin && hasPlate && hasOdometer;
  }

  Future<ApiResponse> postVehicleDetails({
    required BuildContext context,
    required int? customerId,
  }) async {
    final customerCtrl = Provider.of<CustomerDetailsController>(
      context,
      listen: false,
    );
    final bool isNewCustomer =
        customerCtrl.customerStatusLabel == "New Customer";
    final bool isNewVehicle =
        isNewCustomer || customerCtrl.selectedVehicle == "new";
    MultipartFile? vinMultipart;
    MultipartFile? regMultipart;
    MultipartFile? odoMultipart;
    final Map<String, dynamic> payload = {
      "custCountryCode": customerCtrl.selectedCountryCode.replaceAll('+', ''),
      "custMobile": customerCtrl.mobileNumController.text.trim(),
      "vVinNo": vinController.text.trim(),
      "vRegNo": fullPlateNumber,
      "vOdometer": odometerController.text.trim(),
      "status": 0,
      "custType": selectedCustomerTypeId,
      "custLanguage": selectedLanguages,
      "custName": nameController.text.trim(),
      "vFuelMark": fuelMarks[fuelValue.round()],
    };
    try {
      isLoading = true;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      if (isNewVehicle) {
        if (vinImage != null) {
          vinMultipart = await MultipartFile.fromFile(vinImage!.path);
          payload["vVinImgfile"] = vinMultipart;
        }
        if (plateImage != null) {
          regMultipart = await MultipartFile.fromFile(plateImage!.path);
          payload["vRegNoImgfile"] = regMultipart;
        }
        if (odometerImage != null) {
          odoMultipart = await MultipartFile.fromFile(odometerImage!.path);
          payload["vOdometerImgfile"] = odoMultipart;
        }
      } else {
        if (vinImage != null) {
          vinMultipart = await MultipartFile.fromFile(vinImage!.path);
          payload["vVinImgfile"] = vinMultipart;
        } else if (vinDisplayImage != null) {
          payload["existingVinImgUrl"] = vinImageUrl;
        }
        if (plateImage != null) {
          regMultipart = await MultipartFile.fromFile(plateImage!.path);
          payload["vRegNoImgfile"] = regMultipart;
        } else if (plateDisplayImage != null) {
          payload["existingRegImgUrl"] = plateImageUrl;
        }
        if (odometerImage != null) {
          odoMultipart = await MultipartFile.fromFile(odometerImage!.path);
          payload["vOdometerImgfile"] = odoMultipart;
        }
      }
      final dio = Dio();
      dio.options.headers.remove("Content-Type");
      dio.options.headers["Authorization"] = "Bearer $userToken";
      dio.options.headers["Accept"] = "application/json";
      final response = await dio.post(
        ApiServices.openJobcard,
        data: FormData.fromMap(payload),
        options: Options(validateStatus: (_) => true),
      );
      isLoading = false;
      notifyListeners();
      if (response.statusCode == 200) {
        saveSnapshot(customerCtrl, response.data['data']);
        customerCtrl.markCustomerConfirmed();
        vinImage = null;
        plateImage = null;
        odometerImage = null;
        notifyListeners();
        return ApiResponse(
          success: true,
          data: response.data['data'],
          status: response.data['status'],
          statusCode: response.data['statusCode'],
          timeStamp: response.data['timeStamp'],
        );
      }
      return ApiResponse(success: false, status: response.data['status']);
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return ApiResponse(success: false, status: "Failed");
    }
  }

  void clearAll(BuildContext context, {bool keepName = false}) {
    final customerCtrl = Provider.of<CustomerDetailsController>(
      context,
      listen: false,
    );
    vinController.clear();
    odometerController.clear();
    plateController.clear();
    vinImage = null;
    odometerImage = null;
    plateImage = null;
    customerCtrl.setCountryCode('+971');
    selectedEmirate = "AUH";
    selectedPlateCode = PlateDummyDB.getCodesByEmirate("AUH").first;
    if (!keepName) {
      nameController.clear();
    }
    selectedCustomerTypeId = null;
    selectedLanguages = 'EN';
    vinDisplayImage = null;
    plateDisplayImage = null;
    odometerDisplayImage = null;
    vinImageUrl = null;
    plateImageUrl = null;
    _lastSubmittedSnapshot = null;
    fuelValue = 0;
    isScanning = false;
    isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      vinKey.currentState?.reset();
      oddKey.currentState?.reset();
      regKey.currentState?.reset();
    });
    notifyListeners();
  }

  void clearAllControllers(BuildContext context) {
    final customerCtrl = Provider.of<CustomerDetailsController>(
      context,
      listen: false,
    );
    final vehicleCtrl = Provider.of<VehicleDetailsController>(
      context,
      listen: false,
    );
    customerCtrl.mobileNumController.clear();
    customerCtrl.vehiclePlateController.clear();
    customerCtrl.selectedVehicle = null;
    customerCtrl.filteredVehicles.clear();
    customerCtrl.customerStatusLabel = "";
    customerCtrl.setCountryCode('+971');
    nameController.clear();
    selectedCustomerTypeId = null;
    selectedLanguages = 'EN';
    vehicleCtrl.clearAll(context);
  }

  Future<void> processCapturedImage({
    required File image,
    required TextEditingController controller,
    required String filterType,
  }) async {
    try {
      isScanning = true;
      notifyListeners();
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            hideBottomControls: false,
            lockAspectRatio: false,
            initAspectRatio: CropAspectRatioPreset.original,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
      if (croppedFile == null) {
        return;
      }
      final File finalImage = File(croppedFile.path);
      final inputImage = InputImage.fromFile(finalImage);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await recognizer.processImage(inputImage);
      await recognizer.close();
      String text = recognizedText.text.toUpperCase();
      if (filterType == 'vin') {
        final regex = RegExp(r'[A-HJ-NPR-Z0-9]{17}');
        text = regex.firstMatch(text)?.group(0) ?? text;
        vinImage = File(croppedFile.path);
        vinDisplayImage = File(croppedFile.path);
      } else if (filterType == 'odometer') {
        final matches = RegExp(r'\d{2,8}').allMatches(text);
        if (matches.isNotEmpty) {
          final numbers = matches.map((m) => int.parse(m.group(0)!)).toList();
          text = numbers.reduce((a, b) => a > b ? a : b).toString();
        } else {
          text = '';
        }
        odometerImage = finalImage;
        odometerDisplayImage = finalImage;
      } else if (filterType == 'plate') {
        final matches = RegExp(r'\d+').allMatches(text);
        if (matches.isNotEmpty) {
          final numbers = matches.map((m) => m.group(0)!).toList();
          numbers.sort((a, b) => b.length.compareTo(a.length)); // longest first
          text = numbers.first;
          // optional: limit to 5 digits
          if (text.length > 5) {
            text = text.substring(0, 5);
          }
        } else {
          text = '';
        }
        plateImage = finalImage;
        plateDisplayImage = finalImage;
      }
      controller.text = text.trim();
    } finally {
      isScanning = false;
      notifyListeners();
    }
  }

  void clearField(String type) {
    if (type == 'vin') {
      vinController.clear();
      vinDisplayImage = null;
    } else if (type == 'odometer') {
      odometerController.clear();
      odometerDisplayImage = null;
    } else if (type == 'plate') {
      plateController.clear();
      plateDisplayImage = null;
    }
    notifyListeners();
  }
}
