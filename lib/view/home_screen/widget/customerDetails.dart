// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/customerDetails_controller.dart';
import 'package:inspection/controller/vehicleDetails_controller.dart';
import 'package:inspection/model/apiResponsModel.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/customShimmerLoader.dart';
import 'package:provider/provider.dart';

class Customerdetails extends StatefulWidget {
  final Map<String, dynamic>? data;
  final String? initialCountryCode;
  final String? initialMobileNumber;
  final String make;
  final String model;
  final String year;
  final String engineNo;
  final String fuelType;
  final String transmissionType;
  final String serviceType;
  final String customerType;

  const Customerdetails({
    super.key,
    this.data,
    this.initialCountryCode,
    this.initialMobileNumber,
    this.make = "",
    this.model = "",
    this.year = "",
    this.engineNo = "",
    this.fuelType = "",
    this.transmissionType = "",
    this.serviceType = "",
    this.customerType = "",
  });

  @override
  State<Customerdetails> createState() => _CustomerdetailsState();
}

class _CustomerdetailsState extends State<Customerdetails> {
  final _formKey = GlobalKey<FormState>();
  final modelKey = GlobalKey<FormFieldState<String>>();
  Timer? _debounce;
  String? mobile;
  String? plate;

  bool isLoading = false;
  bool isSuccess = false;
  bool isDataLoading = false;

  @override
  void initState() {
    super.initState();
    final customerController = context.read<CustomerDetailsController>();
    final String resolvedCountryCode =
        widget.initialCountryCode ?? widget.data?['countryCode'] ?? "";
    final String resolvedMobileNumber =
        widget.initialMobileNumber ?? widget.data?['mobileNumber'] ?? "";
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => isDataLoading = true);
      try {
        customerController.mobileNumController.text = resolvedMobileNumber;
        if (resolvedCountryCode.isNotEmpty) {
          customerController.setCountryCode(resolvedCountryCode);
        }
        await customerController.getBrandList();
        if (!mounted) return;
        if (customerController.brandList.isNotEmpty) {
          final String brandToSelect = (widget.make.isNotEmpty &&
                  customerController.brandList.contains(widget.make))
              ? widget.make
              : customerController.brandList.first;
          customerController.setBrand(brandToSelect);
          await customerController.postModelList(brandToSelect);
          if (!mounted) return;
          if (widget.model.isNotEmpty &&
              customerController.modelList.contains(widget.model)) {
            customerController.setModel(widget.model);
          } else {
            customerController.setModel(null);
          }
        }
        if (widget.engineNo.isNotEmpty) {
          customerController.engineController.text = widget.engineNo;
        }
        if (widget.year.isNotEmpty) {
          final yearList = customerController.dummyDB.modelYear
              .map((e) => e.toString())
              .toSet()
              .toList();
          if (yearList.contains(widget.year)) {
            customerController.setModelYear(widget.year);
          }
        }
        await customerController.getFuelTypeList();
        if (!mounted) return;
        if (widget.fuelType.isNotEmpty &&
            customerController.fuelTypeList.any(
              (e) => e['id'] == widget.fuelType,
            )) {
          customerController.setFuelType(widget.fuelType);
        }
        await customerController.getTransmissionList();
        if (!mounted) return;
        if (widget.transmissionType.isNotEmpty &&
            customerController.transmissionTypeList.any(
              (e) => e['id'] == widget.transmissionType,
            )) {
          customerController.setTransmission(widget.transmissionType);
        }
        await customerController.getServiceTypeList();
        if (!mounted) return;
        if (widget.serviceType.isNotEmpty &&
            customerController.serviceTypeList.any(
              (e) => e['id'] == widget.serviceType,
            )) {
          customerController.setServiceType(widget.serviceType);
        }
      } finally {
        if (mounted) {
          setState(() => isDataLoading = false);
        }
      }
    });
  }

  void _resetVehicleTempState(BuildContext context) {
    final vehicleCtrl = context.read<VehicleDetailsController>();
    vehicleCtrl.vinImage = null;
    vehicleCtrl.plateImage = null;
    vehicleCtrl.odometerImage = null;
    vehicleCtrl.notify();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        _resetVehicleTempState(context);
        context.go('/vehicledetails');
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Vehicle Details",
          onBackPress: () {
            _resetVehicleTempState(context);
            context.go('/vehicledetails');
          },
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Form(
              key: _formKey,
              child: Consumer<CustomerDetailsController>(
                builder: (context, customerController, child) {
                  return Stack(
                    children: [
                      Column(
                        children: [
                          SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 20),
                                _vechicleDetailsSection(customerController),
                                _serviceTypeSection(customerController),
                                SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: CustomButtonWidget(
                                    text: isLoading
                                        ? "Please wait..."
                                        : isSuccess
                                        ? "COMPLETED"
                                        : "OPEN JOBCARD",
                                    textSize: 16,
                                    isDisabled: isLoading || isSuccess,
                                    showLoader: isLoading,
                                    onPressed: isLoading || isSuccess
                                        ? null
                                        : () async {
                                            final isValid = _formKey.currentState!
                                                .validate();
                                            if (isValid == false) {
                                              ScaffoldMessenger.of(context)
                                                ..removeCurrentSnackBar()
                                                ..showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Please fix the errors in the form",
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              return;
                                            }
                                            setState(() => isLoading = true);
                                            try {
                                              final controller = context
                                                  .read<
                                                    CustomerDetailsController
                                                  >();
                                              ApiResponse response =
                                                  await controller
                                                      .postCustomerVehicleDetails(
                                                        widget.data!,
                                                      );
                                              if (!mounted) return;
                                              if (response.success == true &&
                                                  response.data != null) {
                                                setState(() {
                                                  isLoading = false;
                                                  isSuccess = true;
                                                });
                                                customerController.clearAllData(
                                                  context,
                                                );
                                                final jobId =
                                                    response.data["jobcardId"];
                                                final vId =
                                                    response.data["vehicleId"];
                                                context.go(
                                                  "/vehiclecontents",
                                                  extra: {
                                                    "jobId": jobId,
                                                    "vId": vId,
                                                  },
                                                );
                                              } else {
                                                setState(() => isLoading = false);
                                                ScaffoldMessenger.of(context)
                                                  ..removeCurrentSnackBar()
                                                  ..showSnackBar(
                                                    SnackBar(
                                                      content: const Text(
                                                        "Failed to upload vehicle details",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          ColorConstants.errorcolor,
                                                    ),
                                                  );
                                              }
                                            } catch (e) {
                                              setState(() => isLoading = false);
                                              ScaffoldMessenger.of(context)
                                                ..removeCurrentSnackBar()
                                                ..showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Something went wrong: $e",
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                            }
                                          },
                                  ),
                                ),
                                SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isDataLoading || customerController.isLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white,
                            child: CustomShimmerLoader(
                              isLoading: isDataLoading ||
                                  customerController.isLoading,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _serviceTypeSection(CustomerDetailsController customerController) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              label: RichText(
                text: TextSpan(
                  text: 'Service Type',
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
              floatingLabelStyle: TextStyle(color: ColorConstants.blackColor),
              errorStyle: const TextStyle(height: 0.8, fontSize: 11),
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
            value:
                // ignore: unnecessary_null_comparison
                customerController.selectedServiceTypeId != null &&
                    customerController.serviceTypeList.any(
                      (e) =>
                          e['id'] == customerController.selectedServiceTypeId,
                    )
                ? customerController.selectedServiceTypeId
                : null,
            items: customerController.serviceTypeList.map((service) {
              return DropdownMenuItem<String>(
                value: service['id'],
                child: Text(service['label']!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                customerController.setServiceType(value);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a service type';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _vechicleDetailsSection(CustomerDetailsController customerController) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: 'Brand Name',
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
            floatingLabelStyle: TextStyle(color: ColorConstants.blackColor),
            errorStyle: const TextStyle(height: 0.8, fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 3,
              horizontal: 15,
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
          ),
          value:
              customerController.selectedBrand != null &&
                  customerController.brandList.contains(
                    customerController.selectedBrand,
                  )
              ? customerController.selectedBrand
              : null,
          items: customerController.brandList.toSet().map((brand) {
            return DropdownMenuItem<String>(value: brand, child: Text(brand));
          }).toList(),
          onChanged: customerController.isAlreadyPresent
              ? null
              : (value) {
                  if (value != null) {
                    customerController.setBrand(value);
                    modelKey.currentState?.didChange(null);
                    customerController.postModelList(value);
                  }
                },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select brand type';
            }
            return null;
          },
        ),
        SizedBox(height: 15),
        IgnorePointer(
          ignoring: customerController.isModelLoading ||
              customerController.isAlreadyPresent,
          child: DropdownSearch<String>(
            key: modelKey,
            items: (filter, infiniteScrollProps) => customerController.modelList,
            selectedItem: customerController.selectedModel,
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: "Search Model",
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
              decoration: InputDecoration(
                label: RichText(
                  text: TextSpan(
                    text: customerController.isModelLoading ? 'Model (Loading...)' : 'Model',
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
                floatingLabelStyle: TextStyle(color: ColorConstants.blackColor),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 15,
                ),
                errorStyle: const TextStyle(height: 0.8, fontSize: 11),
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
            ),
            onChanged: (value) {
              if (value != null) {
                customerController.setModel(value);
                modelKey.currentState?.didChange(value);
                modelKey.currentState?.validate();
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Model is required';
              }
              return null;
            },
          ),
        ),
        SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                isExpanded: true,
                decoration: InputDecoration(
                  label: RichText(
                    text: TextSpan(
                      text: 'Manufacture Year',
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

                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 15,
                  ),
                  errorStyle: const TextStyle(height: 0.8, fontSize: 11),
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
                value: customerController.selectedModelYear,
                items: customerController.dummyDB.modelYear
                    .toSet()
                    .map(
                      (year) =>
                          DropdownMenuItem(value: year, child: Text(year)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    customerController.setModelYear(value);
                  }
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Manufacture year is required'
                    : null,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: customerController.engineController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  label: RichText(
                    text: TextSpan(
                      text: 'Engine Number',
                      style: ApptextstyleConstants.lightText(
                        fontSize: 12,
                        color: ColorConstants.blackColor,
                      ),
                    ),
                  ),
                  floatingLabelStyle: TextStyle(
                    color: ColorConstants.blackColor,
                  ),
                  errorStyle: const TextStyle(height: 0.8, fontSize: 11),
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
                      color: ColorConstants.greyColor,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: ColorConstants.greyColor,
                      width: 1.2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  if (!RegExp(r'^\d{2,6}$').hasMatch(value.trim())) {
                    return 'Engine number must be 2 to 6 digits';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                isExpanded: true,
                decoration: InputDecoration(
                  label: RichText(
                    text: TextSpan(
                      text: 'Transmission Type',
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
                  errorStyle: const TextStyle(height: 0.8, fontSize: 11),
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
                value:
                    customerController.selectedTransmissionId != null &&
                        customerController.transmissionTypeList.any(
                          (e) =>
                              e['id'] ==
                              customerController.selectedTransmissionId,
                        )
                    ? customerController.selectedTransmissionId
                    : null,
                items: customerController.transmissionTypeList.map((trans) {
                  return DropdownMenuItem<String>(
                    value: trans['id'],
                    child: Text(trans['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    customerController.setTransmission(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Transmission type is required';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                isExpanded: true,
                decoration: InputDecoration(
                  label: RichText(
                    text: TextSpan(
                      text: 'Fuel Type',
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
                  errorStyle: const TextStyle(height: 0.8, fontSize: 11),
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
                value:
                    customerController.selectedFuelId != null &&
                        customerController.fuelTypeList.any(
                          (e) => e['id'] == customerController.selectedFuelId,
                        )
                    ? customerController.selectedFuelId
                    : null,
                items: customerController.fuelTypeList.map((fuel) {
                  return DropdownMenuItem<String>(
                    value: fuel['id'],
                    child: Text(fuel['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    customerController.setFuelType(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Fuel type is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        // SizedBox(height: 15),
        // Container(
        //   decoration: BoxDecoration(
        //     border: Border.all(color: ColorConstants.greyColor),
        //   ),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Row(
        //         children: [
        //           Padding(
        //             padding: const EdgeInsets.all(8.0),
        //             child: Text(
        //               "Fuel Mark",
        //               style: ApptextstyleConstants.lightText(
        //                 fontSize: 14,
        //                 color: ColorConstants.blackColor,
        //               ),
        //             ),
        //           ),
        //           Text(
        //             '*',
        //             style: ApptextstyleConstants.boldText(
        //               color: ColorConstants.errorcolor,
        //               fontSize: 16,
        //             ),
        //           ),
        //         ],
        //       ),
        //       SliderTheme(
        //         data: SliderTheme.of(context).copyWith(
        //           activeTrackColor: Colors.green,
        //           inactiveTrackColor: Colors.grey.shade300,
        //           thumbColor: Colors.green,
        //           overlayColor: Colors.green.withOpacity(0.2),
        //           trackHeight: 6,
        //           activeTickMarkColor: Colors.green,
        //           inactiveTickMarkColor: Colors.grey,
        //           tickMarkShape: const RoundSliderTickMarkShape(
        //             tickMarkRadius: 4,
        //           ),
        //         ),
        //         child: Slider(
        //           value: customerController.fuelValue,
        //           min: 0,
        //           max: 4,
        //           divisions: 4,
        //           label: customerController
        //               .fuelMarks[customerController.fuelValue.round()],
        //           onChanged: (value) {
        //             customerController.fuelValue = value;
        //             // ignore: invalid_use_of_protected_member
        //             customerController.notifyListeners();
        //           },
        //         ),
        //       ),
        //       Padding(
        //         padding: const EdgeInsets.symmetric(horizontal: 12),
        //         child: Row(
        //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //           children: customerController.fuelMarks.map((e) {
        //             int index = customerController.fuelMarks.indexOf(e);
        //             return Text(
        //               e,
        //               style: TextStyle(
        //                 color: index == customerController.fuelValue.round()
        //                     ? Colors.green
        //                     : Colors.grey,
        //                 fontWeight: FontWeight.bold,
        //               ),
        //             );
        //           }).toList(),
        //         ),
        //       ),
        //       SizedBox(height: 15),
        //     ],
        //   ),
        // ),
        SizedBox(height: 15),
      ],
    );
  }
}
