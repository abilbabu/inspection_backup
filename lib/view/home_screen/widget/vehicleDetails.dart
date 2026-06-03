// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/customerDetails_controller.dart';
import 'package:inspection/controller/vehicleDetails_controller.dart';
import 'package:inspection/model/apiResponsModel.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/utils/dummyDB/Dummydb.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:provider/provider.dart';
import 'package:inspection/view/global_widgets/cameraCaptureScreen.dart';

class VehicleDetails extends StatefulWidget {
  const VehicleDetails({super.key});

  @override
  State<VehicleDetails> createState() => _VehicleDetailsState();
}

class _VehicleDetailsState extends State<VehicleDetails> {
  final _formKey = GlobalKey<FormState>();
  bool showClearIcon = true;
  bool hasMobileError = false;
  late FocusNode plateSearchFocus;

  @override
  void initState() {
    super.initState();
    plateSearchFocus = FocusNode();
    final customerCtrl = Provider.of<CustomerDetailsController>(
      context,
      listen: false,
    );
    final vehicleCtrl = Provider.of<VehicleDetailsController>(
      context,
      listen: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<VehicleDetailsController>();
      await vehicleCtrl.getCustomerTypeList();
      vehicleCtrl.restoreFromSnapshot();
      vehicleCtrl.resetStatus();
    });
    customerCtrl.onVehicleSelected = () {
      final data = customerCtrl.getSelectedVehicleData();
      if (data != null) {
        vehicleCtrl.vinController.text = data["vVinNo"] ?? "";
        vehicleCtrl.restorePlateFromApiSmart(data["vRegNo"] ?? "");
        vehicleCtrl.odometerController.clear();
        vehicleCtrl.vinImageUrl = data["vVinImg"];
        vehicleCtrl.plateImageUrl = data["vRegNoImg"];
      } else {
        vehicleCtrl.vinController.clear();
        vehicleCtrl.plateController.clear();
        vehicleCtrl.odometerController.clear();
        vehicleCtrl.vinImageUrl = null;
        vehicleCtrl.plateImageUrl = null;
      }
      vehicleCtrl.notify();
    };
  }

  @override
  void dispose() {
    plateSearchFocus.dispose();
    super.dispose();
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text("Discard changes?"),
              content: const Text(
                "Unsaved changes will be cleared. Are you sure you want to go back?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("NO"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("YES"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final clearAllControllers = Provider.of<VehicleDetailsController>(
      context,
      listen: false,
    ).clearAllControllers;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        final shouldExit = await _showExitConfirmation();
        if (shouldExit) {
          clearAllControllers(context);
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Customer & Vehicle Details",
          onBackPress: () async {
            final shouldExit = await _showExitConfirmation();
            if (shouldExit) {
              clearAllControllers(context);
              context.go('/home');
            }
          },
        ),
        body: Consumer<VehicleDetailsController>(
          builder: (context, controller, child) {
            final customerCtrl = context.watch<CustomerDetailsController>();
            final vehicleData = customerCtrl.getSelectedVehicleData();
            final isNewVehicle = customerCtrl.selectedVehicle == "new";
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        _buildMobileSearchRow(context),
                        SizedBox(height: 8),
                        if (vehicleData != null && !isNewVehicle)
                          _vehicleNameContainer(vehicleData),
                        SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 1,
                            ),
                            color: Colors.grey.shade100,
                          ),
                          child: Column(
                            children: [
                              _customerDetailsSection(context),
                              SizedBox(height: 8),
                              _buildRegistrationPlateRow(context),
                              _buildScanField(
                                label: "VIN Number",
                                hint: "VIN Number",
                                formKey: controller.vinKey,
                                controller: controller.vinController,
                                imageFile: controller.vinDisplayImage,
                                imageUrl: controller.vinImageUrl,
                                showClearIcon:
                                    context
                                        .read<CustomerDetailsController>()
                                        .customerStatusLabel ==
                                    "New Customer",
                                keyboardType: TextInputType.text,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(17),
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-HJ-NPR-Z0-9]'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'VIN number is required';
                                  } else if (value.length != 17) {
                                    return 'VIN must be exactly 17 characters';
                                  }
                                  return null;
                                },
                                onScan: () async {
                                  final dynamic result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CameraCaptureScreen(
                                        isVideo: false,
                                      ),
                                    ),
                                  );
                                  if (result != null &&
                                      result is Map &&
                                      result['file'] != null) {
                                    controller.processCapturedImage(
                                      image:
                                          result['file'], // Extract the File object from the map
                                      controller: controller.vinController,
                                      filterType: 'vin',
                                    );
                                  }
                                },
                                onClear: () => controller.clearField('vin'),
                              ),
                              _buildScanField(
                                formKey: controller.oddKey,
                                label: "Odometer",
                                hint: "Odometer Reading",
                                controller: controller.odometerController,
                                imageFile: controller.odometerDisplayImage,
                                showClearIcon:
                                    context
                                        .read<CustomerDetailsController>()
                                        .customerStatusLabel ==
                                    "New Customer",
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(7),
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Odometer reading is required';
                                  } else if (int.tryParse(value) == null) {
                                    return 'Enter a valid number';
                                  }
                                  return null;
                                },
                                onScan: () async {
                                  final dynamic result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CameraCaptureScreen(
                                        isVideo: false,
                                      ),
                                    ),
                                  );
                                  if (result != null &&
                                      result is Map &&
                                      result['file'] != null) {
                                    controller.processCapturedImage(
                                      image: result['file'],
                                      controller: controller.odometerController,
                                      filterType: 'odometer',
                                    );
                                  }
                                },
                                onClear: () =>
                                    controller.clearField('odometer'),
                              ),
                              _buildFuelMark(context),
                              SizedBox(height: 15),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: CustomButtonWidget(
                              text: controller.isLoading
                                  ? "Please wait..."
                                  : controller.isSuccess
                                  ? "COMPLETED"
                                  : "PROCEED",
                              textSize: 16,
                              isDisabled:
                                  controller.isLoading || controller.isSuccess,
                              showLoader: controller.isLoading,
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                final vehicleCtrl = context
                                    .read<VehicleDetailsController>();
                                final customerController = context
                                    .read<CustomerDetailsController>();
                                final int? customerId = customerController
                                    .resolveCustomerId();
                                final bool customerChanged = vehicleCtrl
                                    .hasCustomerChanged(customerController);
                                final bool vehicleChanged = vehicleCtrl
                                    .hasVehicleChanged();
                                final selectedVehicle = customerController
                                    .getSelectedVehicleData();
                                if (!customerChanged && !vehicleChanged) {
                                  final snapshot = vehicleCtrl
                                      .getLastSnapshot();
                                  if (snapshot == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Previous vehicle data not found",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  final Map<String, dynamic> apiData = {
                                    "vehicleId": snapshot.vehicleId,
                                    "customerId": snapshot.customerId,
                                    "jobcardId": snapshot.jobcardId,
                                  };
                                  context.go(
                                    "/customerdetails",
                                    extra: {
                                      "apiData": apiData,
                                      "customerId": snapshot.customerId,
                                      "mobileNumber": snapshot.mobile,
                                      "countryCode": snapshot.countryCode,
                                      "custType":
                                          vehicleCtrl.selectedCustomerTypeId,
                                      "make": selectedVehicle?["vMake"] ?? "",
                                      "model": selectedVehicle?["vModel"] ?? "",
                                      "year":
                                          selectedVehicle?["vModelYear"]
                                              ?.toString() ??
                                          "",
                                      "fuelType":
                                          selectedVehicle?["vFuelTypeId"] ?? "",
                                      "transmissionType":
                                          selectedVehicle?["vTransmissionTypeId"] ??
                                          "",
                                      "serviceType":
                                          selectedVehicle?["vTypeId"] ?? "",
                                      "engineNo":
                                          selectedVehicle?["vEng"] ?? "",
                                    },
                                  );
                                  return;
                                }
                                vehicleCtrl.setLoading();
                                ApiResponse result = await vehicleCtrl
                                    .postVehicleDetails(
                                      context: context,
                                      customerId: customerId,
                                    );
                                if (!mounted) {
                                  return;
                                }
                                if (result.success == true &&
                                    result.data != null) {
                                  vehicleCtrl.setSuccess();
                                  context.go(
                                    "/customerdetails",
                                    extra: {
                                      "apiData": result.data,
                                      "customerId": result.data["customerId"],
                                      "mobileNumber": customerController
                                          .mobileNumController
                                          .text
                                          .trim(),
                                      "countryCode": customerController
                                          .selectedCountryCode,
                                      "custType":
                                          vehicleCtrl.selectedCustomerTypeId,
                                      "make": selectedVehicle?["vMake"] ?? "",
                                      "model": selectedVehicle?["vModel"] ?? "",
                                      "year":
                                          selectedVehicle?["vModelYear"]
                                              ?.toString() ??
                                          "",
                                      "fuelType":
                                          selectedVehicle?["vFuelTypeId"] ?? "",
                                      "transmissionType":
                                          selectedVehicle?["vTransmissionTypeId"] ??
                                          "",
                                      "serviceType":
                                          selectedVehicle?["vTypeId"] ?? "",
                                      "engineNo":
                                          selectedVehicle?["vEng"] ?? "",
                                    },
                                  );
                                } else {
                                  vehicleCtrl.resetStatus();
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    vehicleCtrl.resetStatus();
                                  });
                                  ScaffoldMessenger.of(context)
                                    ..removeCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result.status ??
                                              "Failed to upload vehicle details",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor:
                                            ColorConstants.errorcolor,
                                      ),
                                    );
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                if (controller.isScanning)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 12),
                          Text(
                            "Scanning...",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _vehicleNameContainer(Map<String, dynamic> vehicleData) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: BoxBorder.all(color: ColorConstants.greenColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_car,
            size: 18,
            color: ColorConstants.greenColor,
          ),
          const SizedBox(width: 8),
          Text(
            "${vehicleData['vMake'] ?? ''} ${vehicleData['vModel'] ?? ''} (${vehicleData['vModelYear'] ?? ''})",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorConstants.greenColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerDetailsSection(BuildContext context) {
    return Consumer<VehicleDetailsController>(
      builder: (context, vehicleCtrl, child) {
        return Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Customer Name',
                    style: ApptextstyleConstants.lightText(
                      fontSize: 13,
                      color: ColorConstants.blackColor,
                    ),
                    children: [
                      TextSpan(
                        text: '*',
                        style: ApptextstyleConstants.boldText(
                          color: ColorConstants.errorcolor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5),
                TextFormField(
                  controller: vehicleCtrl.nameController,
                  textCapitalization: TextCapitalization.sentences,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    hintText: "Enter the Customer Name",
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    floatingLabelStyle: TextStyle(
                      color: ColorConstants.blackColor,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 15,
                    ),
                    errorStyle: ApptextstyleConstants.lightText(
                      fontSize: 9,
                      color: Colors.red,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.greyColor,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: ColorConstants.greyColor,
                        width: 1.2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: ColorConstants.errorcolor,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: ColorConstants.errorcolor,
                        width: 1.2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Customer name is required.';
                    } else if (value.length < 2) {
                      return 'Customer name is required.';
                    }
                    return null;
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'Customer Type',
                          style: ApptextstyleConstants.lightText(
                            fontSize: 13,
                            color: ColorConstants.blackColor,
                          ),
                          children: [
                            TextSpan(
                              text: '*',
                              style: ApptextstyleConstants.boldText(
                                color: ColorConstants.errorcolor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 15,
                          ),
                          errorStyle: ApptextstyleConstants.lightText(
                            fontSize: 9,
                            color: Colors.red,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: ColorConstants.greyColor,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: ColorConstants.greyColor,
                              width: 1.2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: ColorConstants.errorcolor,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: ColorConstants.errorcolor,
                              width: 1.2,
                            ),
                          ),
                        ),
                        hint: Text(
                          "Select Customer Type",
                          style: ApptextstyleConstants.lightText(
                            fontSize: 12,
                            color: ColorConstants.greyColor,
                          ),
                        ),
                        value:
                            vehicleCtrl.selectedCustomerTypeId != null &&
                                vehicleCtrl.customerTypeList.any(
                                  (e) =>
                                      e['id'] ==
                                      vehicleCtrl.selectedCustomerTypeId,
                                )
                            ? vehicleCtrl.selectedCustomerTypeId
                            : null,
                        items: vehicleCtrl.customerTypeList.map((type) {
                          return DropdownMenuItem<String>(
                            value: type['id'],
                            child: Text(
                              type['label']!,
                              style: ApptextstyleConstants.lightText(
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            vehicleCtrl.setCustomerType(value);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Customer type is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'Preffered Language',
                          style: ApptextstyleConstants.lightText(
                            fontSize: 12,
                            color: ColorConstants.blackColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        hint: Text(
                          "Select Language",
                          style: ApptextstyleConstants.lightText(
                            fontSize: 12,
                            color: ColorConstants.greyColor,
                          ),
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 15,
                          ),
                          errorStyle: const TextStyle(
                            height: 0.8,
                            fontSize: 11,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: ColorConstants.greyColor,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: ColorConstants.greyColor,
                              width: 1.2,
                            ),
                          ),
                        ),
                        value: vehicleCtrl.selectedLanguage.isEmpty
                            ? null
                            : vehicleCtrl.selectedLanguage,
                        items: vehicleCtrl.dummyDB.languageList
                            .map(
                              (lang) => DropdownMenuItem<String>(
                                value: lang,
                                child: Text(
                                  lang,
                                  style: ApptextstyleConstants.lightText(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: vehicleCtrl.isAlreadyPresent
                            ? null
                            : (value) {
                                vehicleCtrl.setLanguage(value!);
                              },
                        validator: (_) => null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildFuelMark(BuildContext context) {
    return Consumer<VehicleDetailsController>(
      builder: (context, vController, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RichText(
                      text: TextSpan(
                        text: 'Fuel Mark',
                        style: ApptextstyleConstants.lightText(
                          fontSize: 13,
                          color: ColorConstants.blackColor,
                        ),
                        children: [
                          TextSpan(
                            text: '*',
                            style: ApptextstyleConstants.boldText(
                              color: ColorConstants.errorcolor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.green,
                        inactiveTrackColor: Colors.grey.shade300,
                        thumbColor: Colors.green,
                        overlayColor: Colors.green.withOpacity(0.2),
                        trackHeight: 6,
                        activeTickMarkColor: Colors.green,
                        inactiveTickMarkColor: Colors.grey,
                        tickMarkShape: const RoundSliderTickMarkShape(
                          tickMarkRadius: 4,
                        ),
                      ),
                      child: Slider(
                        value: vController.fuelValue,
                        min: 0,
                        max: 4,
                        divisions: 4,
                        label: vController
                            .fuelMarks[vController.fuelValue.round()],
                        onChanged: (value) {
                          vController.fuelValue = value;
                          // ignore: invalid_use_of_protected_member
                          vController.notifyListeners();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: vController.fuelMarks.map((e) {
                          int index = vController.fuelMarks.indexOf(e);
                          return Text(
                            e,
                            style: TextStyle(
                              color: index == vController.fuelValue.round()
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegistrationPlateRow(BuildContext context) {
    return Consumer<VehicleDetailsController>(
      builder: (context, controller, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: "Registration Number",
                style: ApptextstyleConstants.lightText(
                  fontSize: 13,
                  color: ColorConstants.blackColor,
                ),
                children: [
                  TextSpan(
                    text: '*',
                    style: ApptextstyleConstants.boldText(
                      color: ColorConstants.errorcolor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildPlateScanField(
                    controller: controller,
                    context: context,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownSearch<String>(
                    items: (f, infiniteScrollProps) => PlateDummyDB.emirates,
                    selectedItem: controller.selectedEmirate,
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, size: 16),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    decoratorProps: DropDownDecoratorProps(
                      decoration: _plateDecoration("Emirate"),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        controller.setEmirate(value);
                      }
                    },
                    validator: (v) => v == null ? "Required" : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownSearch<String>(
                    items: (f, infiniteScrollProps) => controller.plateCodeList,
                    selectedItem: controller.selectedPlateCode,
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, size: 16),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    decoratorProps: DropDownDecoratorProps(
                      decoration: _plateDecoration("Code"),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        controller.setPlateCode(value);
                      }
                    },
                    validator: (v) => v == null ? "Required" : null,
                  ),
                ),
              ],
            ),
            if (controller.plateDisplayImage != null ||
                controller.plateImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: controller.plateDisplayImage != null
                          ? Image.file(
                              controller.plateDisplayImage!,
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              controller.plateImageUrl!,
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildPlateScanField({
    required VehicleDetailsController controller,
    required BuildContext context,
  }) {
    final bool isReadonlyImage = controller.plateImageUrl != null;
    return TextFormField(
      key: controller.regKey,
      controller: controller.plateController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Registration number is required";
        }
        if (!RegExp(r'^\d{2,5}$').hasMatch(value)) {
          return "Enter exactly 5 digits";
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: "Reg Number",
        hintStyle: const TextStyle(
          color: ColorConstants.greyColor,
          fontSize: 12,
        ),
        errorStyle: ApptextstyleConstants.lightText(
          fontSize: 9, // 👈 make it smaller (8–10 recommended)
          color: Colors.red,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorConstants.greyColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorConstants.greyColor, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: ColorConstants.errorcolor,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: ColorConstants.errorcolor,
            width: 1.2,
          ),
        ),
        suffixIcon: isReadonlyImage
            ? null
            : IconButton(
                icon:
                    (controller.plateDisplayImage == null &&
                        controller.plateImageUrl == null)
                    ? SvgPicture.asset(
                        'assets/svg/scanner_logo.svg',
                        width: 22,
                        height: 22,
                        color: ColorConstants.blackColor,
                      )
                    : SvgPicture.asset(
                        'assets/svg/repeat.svg',
                        width: 22,
                        height: 22,
                        color: ColorConstants.blackColor,
                      ),
                tooltip:
                    (controller.plateDisplayImage == null &&
                        controller.plateImageUrl == null)
                    ? "Scan"
                    : "Retake",
                onPressed: () async {
                  final dynamic result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CameraCaptureScreen(isVideo: false),
                    ),
                  );
                  if (result != null &&
                      result is Map &&
                      result['file'] != null) {
                    controller.processCapturedImage(
                      image: result['file'],
                      controller: controller.plateController,
                      filterType: 'plate',
                    );
                  }
                },
              ),
      ),
    );
  }

  InputDecoration _plateDecoration(String label) {
    return InputDecoration(
      floatingLabelStyle: TextStyle(color: ColorConstants.blackColor),
      contentPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      errorStyle: const TextStyle(height: 0.3, fontSize: 9),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ColorConstants.greyColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ColorConstants.greyColor, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: ColorConstants.errorcolor,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: ColorConstants.errorcolor,
          width: 1.2,
        ),
      ),
    );
  }

  Widget _buildMobileSearchRow(BuildContext context) {
    return Consumer<CustomerDetailsController>(
      builder: (context, customerController, child) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade400, width: 1),
          color: Colors.grey.shade100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: DropdownButtonFormField<String>(
                    value: customerController.selectedCountryCode,
                    isDense: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 10,
                      ),
                      errorStyle: const TextStyle(
                        height: 0.3,
                        fontSize: 9,
                        color: Colors.red,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: ColorConstants.greyColor,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: ColorConstants.greyColor,
                          width: 1.2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: ColorConstants.errorcolor,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: ColorConstants.errorcolor,
                          width: 1.2,
                        ),
                      ),
                    ),
                    items: customerController
                        .dummyDB
                        .countryMobileNumberCodeList
                        .map((item) {
                          return DropdownMenuItem<String>(
                            value: item['code'],
                            child: Row(
                              children: [
                                Text(
                                  item['flag']!,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item['code']!,
                                  style: ApptextstyleConstants.extraLightText(
                                    fontSize: 14,
                                    color: ColorConstants.blackColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (value) {
                      customerController.setCountryCode(value!);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: customerController.mobileNumController,
                    keyboardType: TextInputType.phone,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      label: RichText(
                        text: TextSpan(
                          text: 'Mobile Number',
                          style: ApptextstyleConstants.lightText(
                            fontSize: 12,
                            color: ColorConstants.blackColor,
                          ),
                          children: [
                            TextSpan(
                              text: '*',
                              style: ApptextstyleConstants.boldText(
                                color: ColorConstants.errorcolor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: ColorConstants.blackColor,
                      ),
                      errorStyle: const TextStyle(
                        height: 0.3,
                        fontSize: 9,
                        color: Colors.red,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 15,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: ColorConstants.greyColor,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: ColorConstants.greyColor,
                          width: 1.2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: ColorConstants.errorcolor,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: ColorConstants.errorcolor,
                          width: 1.2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Mobile number is required";
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final customerCtrl = context
                          .read<CustomerDetailsController>();
                      final vehicleCtrl = context
                          .read<VehicleDetailsController>();
                      if (customerCtrl.hasMobileChanged()) {
                        customerCtrl.customerStatusLabel = "New Customer";
                        customerCtrl.selectedVehicle = null;
                        customerCtrl.filteredVehicles.clear();
                        vehicleCtrl.clearAll(context);
                      }
                      customerController.searchByMobileDebounced(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (customerController.lastSearchSource == SearchSource.mobile)
              _statusLabel(customerController),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade400)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "OR",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade400)),
              ],
            ),
            const SizedBox(height: 10),
            RawAutocomplete<String>(
              textEditingController: customerController.vehiclePlateController,
              focusNode: plateSearchFocus,
              optionsBuilder: (TextEditingValue value) {
                if (value.text.trim().length < 2) {
                  return const Iterable<String>.empty();
                }
                return customerController.regNoSuggestions;
              },
              displayStringForOption: (option) => option,
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: _inputDecoration("Search Vehicle Plate Number"),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    customerController.searchByPlateDebounced(context);
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                final query = customerController.vehiclePlateController.text
                    .toLowerCase();
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 40,
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: Column(
                        children: [
                          if (customerController.isSearching)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: LinearProgressIndicator(),
                            ),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final plate = options.elementAt(index);
                                return ListTile(
                                  leading: const Icon(
                                    Icons.directions_car,
                                    color: ColorConstants.borderGreyColor,
                                  ),
                                  title: _highlightText(plate, query),
                                  onTap: () {
                                    onSelected(plate);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              onSelected: (plate) async {
                customerController.vehiclePlateController.text = plate;
                await customerController.postPhonePlateNumber(context);
              },
            ),
            if (customerController.lastSearchSource == SearchSource.plate)
              _statusLabel(customerController),
            Consumer<CustomerDetailsController>(
              builder: (context, ctrl, _) {
                if (ctrl.filteredVehicles.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    const Text(
                      "Select Vehicle",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: ctrl.selectedVehicle,
                          isExpanded: true,
                          items:
                              [
                                {"vId": "new", "isNew": true},
                                ...ctrl.filteredVehicles,
                              ].map((vehicle) {
                                final String regNo = vehicle['vRegNo'] ?? '';
                                final String? make = vehicle['vMake'];
                                final String? model = vehicle['vModel'];
                                final String label = vehicle['isNew'] == true
                                    ? 'Create New Vehicle'
                                    : (make != null &&
                                          model != null &&
                                          make.isNotEmpty &&
                                          model.isNotEmpty)
                                    ? '$regNo • $make $model'
                                    : regNo;
                                return DropdownMenuItem<String>(
                                  value: vehicle['vId'].toString(),
                                  child: Text(label),
                                );
                              }).toList(),
                          //
                          onChanged: (value) {
                            ctrl.setSelectedVehicle(value);
                            final vehicleCtrl =
                                Provider.of<VehicleDetailsController>(
                                  context,
                                  listen: false,
                                );
                            if (value == "new") {
                              vehicleCtrl.clearAll(context, keepName: true);
                            } else {
                              final data = ctrl.getSelectedVehicleData();
                              if (data != null) {
                                vehicleCtrl.vinController.text =
                                    data["vVinNo"] ?? "";
                                vehicleCtrl.restorePlateFromApiSmart(
                                  data["vRegNo"] ?? "",
                                );
                                vehicleCtrl.vinImageUrl = data["vVinImg"];
                                vehicleCtrl.plateImageUrl = data["vRegNoImg"];
                                ctrl.vehiclePlateController.text =
                                    data["vRegNo"] ?? "";
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);
    final lowerText = text.toLowerCase();
    final start = lowerText.indexOf(query);
    if (start == -1) return Text(text);
    final end = start + query.length;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, start),
            style: const TextStyle(color: Colors.black),
          ),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: text.substring(end),
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      prefixIcon: const Icon(Icons.search),
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black87, width: 1.2),
      ),
    );
  }

  Widget _statusLabel(CustomerDetailsController controller) {
    if (controller.customerStatusLabel.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        controller.customerStatusLabel,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: controller.customerStatusLabel == "New Customer"
              ? Colors.blue
              : Colors.green,
        ),
      ),
    );
  }

  Widget _buildScanField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onScan,
    required VoidCallback onClear,
    required Key formKey,
    File? imageFile,
    String? imageUrl,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool showClearIcon = true,
  }) {
    final bool isReadonlyImage = imageUrl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: ApptextstyleConstants.lightText(
              fontSize: 13,
              color: ColorConstants.blackColor,
            ),
            children: [
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: ColorConstants.errorcolor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          key: formKey,
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: inputFormatters,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 3,
              horizontal: 15,
            ),
            errorStyle: ApptextstyleConstants.lightText(
              fontSize: 9,
              color: Colors.red,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: ColorConstants.greyColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: ColorConstants.greyColor,
                width: 1.2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: ColorConstants.errorcolor,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: ColorConstants.errorcolor,
                width: 1.2,
              ),
            ),
            suffixIcon: isReadonlyImage
                ? null
                : IconButton(
                    onPressed: onScan,
                    tooltip: (imageFile == null && imageUrl == null)
                        ? "Scan"
                        : "Retake",
                    icon: (imageFile == null && imageUrl == null)
                        ? SvgPicture.asset(
                            'assets/svg/scanner_logo.svg',
                            width: 25,
                            height: 25,
                            color: ColorConstants.blackColor,
                          )
                        : SvgPicture.asset(
                            'assets/svg/repeat.svg',
                            width: 25,
                            height: 25,
                            color: ColorConstants.blackColor,
                          ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        if (imageFile != null || imageUrl != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageFile != null
                    ? Image.file(
                        imageFile,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        imageUrl!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ],
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}
