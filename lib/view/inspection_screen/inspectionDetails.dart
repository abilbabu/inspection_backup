import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/inspectionDetails_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/vehicleSummaryWidget.dart';
import 'package:provider/provider.dart';

class InspectionDetails extends StatefulWidget {
  final int? jobId;
  const InspectionDetails({super.key, this.jobId});

  @override
  State<InspectionDetails> createState() => _InspectionDetailsState();
}

class _InspectionDetailsState extends State<InspectionDetails> {
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<InspectionDetailsController>().getInspectionTypes();
    });
    super.initState();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      _triggerSearch(value);
    });
  }

  void _triggerSearch(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      context.read<InspectionDetailsController>().getInspectionTypes();
    } else {
      context.read<InspectionDetailsController>().searchInspectionForms(name);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text("Discard changes?"),
              content: const Text("Are you sure you want to go back?"),
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        final shouldExit = await _showExitConfirmation();
        if (shouldExit) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go("/jobcarddetails");
          }
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Inspection Types',
          onBackPress: () async {
            final shouldExit = await _showExitConfirmation();
            if (shouldExit) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go("/jobcarddetails");
              }
            }
          },
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                VehicleSummaryWidget(jobId: widget.jobId),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    boxShadow: ColorConstants.dashboardboxShadow,
                    color: ColorConstants.whiteColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "Select Inspection Type.",
                          style: ApptextstyleConstants.semiBoldText(
                            fontSize: 16,
                            color: ColorConstants.blackColor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: searchController,
                                onChanged: (value) {
                                  setState(() {});
                                  _onSearchChanged(value);
                                },
                                onSubmitted: _triggerSearch,
                                decoration: InputDecoration(
                                  hintText: "Search Inspection Type",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: ColorConstants.activecolor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: ColorConstants.activecolor,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (searchController.text.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.close),
                                          onPressed: () {
                                            searchController.clear();
                                            setState(() {});
                                            context
                                                .read<
                                                  InspectionDetailsController
                                                >()
                                                .getInspectionTypes();
                                          },
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.search),
                                        onPressed: () => _triggerSearch(
                                          searchController.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () {
                                searchController.clear();
                                setState(() {});
                                context
                                    .read<InspectionDetailsController>()
                                    .getInspectionTypes();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SvgPicture.asset(
                                  'assets/svg/repeat.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    ColorConstants.blackColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Consumer<InspectionDetailsController>(
                        builder: (context, inspectionController, child) {
                          if (inspectionController.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (inspectionController
                              .inspectiontypesList
                              .isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  "No Inspection Type Found",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                inspectionController.inspectiontypesList.length,
                            itemBuilder: (context, index) {
                              final item = inspectionController
                                  .inspectiontypesList[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CustomButtonWidget(
                                  text:
                                      (item["inspectionFormName"] ?? "No Name")
                                          .toUpperCase(),
                                  textSize: 16,
                                  onPressed: () {
                                    context.push(
                                      "/inspectiontypedetailspage",
                                      extra: {
                                        "inspectionFormId":
                                            item["inspectionFormId"],
                                        "jobId": widget.jobId,
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
