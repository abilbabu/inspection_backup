import 'dart:async';
// import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/inspectionDetails_controller.dart';
import 'package:inspection/controller/inspectionSummaryPage_controller.dart';
import 'package:inspection/controller/jobCardDetails_controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:inspection/view/global_widgets/vehicleSummaryWidget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InspectionDetails extends StatefulWidget {
  final int? jobId;

  const InspectionDetails({super.key, this.jobId});

  @override
  State<InspectionDetails> createState() => _InspectionDetailsState();
}

class _InspectionDetailsState extends State<InspectionDetails> {
  final TextEditingController searchController = TextEditingController();

  Timer? _debounce;
  int? userDepartment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      context.read<InspectionDetailsController>().getInspectionTypes();
      context.read<JobcarddetailsController>().postJobCardDetails(
        widget.jobId!,
      );
      context.read<InspectionsummarypageController>().getInspectionSummary(
        widget.jobId!,
      );
    });
    loadUserDepartment();
  }

  Future<void> loadUserDepartment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final value = prefs.get("userDepartment");
    if (!mounted) return;
    setState(() {
      userDepartment = int.tryParse(value.toString());
    });
    // log("Department : $userDepartment");
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
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
                  onPressed: () =>   context.push("/jobcarddetails", extra: widget.jobId),
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
    final jobCtrl = context.watch<JobcarddetailsController>();
    final inspTypeCtrl = context.read<InspectionsummarypageController>();
    final jobcard = jobCtrl.jobCardData?["jobcard"];
    final status = int.tryParse(jobcard?["jobStatus"]?.toString() ?? "") ?? -1;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        final shouldExit = await _showExitConfirmation();
        if (shouldExit) {
          if (context.canPop()) {
            context.pop(true);
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
                context.pop(true);
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

                if (jobCtrl.isTechnicianAssigned == true &&  ![10, 11, 12, 13, 14].contains(status))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorConstants.greenColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ColorConstants.greenColor),
                    ),
                    child: Center(
                      child: Text(
                        "Assigned Technician : ${jobCtrl.assignedTechnicianName?.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ')}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.greenColor,
                        ),
                      ),
                    ),
                  ),
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

                      // CUSTOM INSPECTION ASSIGNED
                      if (inspTypeCtrl.isCustomInspectionAssigned &&
                          inspTypeCtrl.isInspectionAssigned) ...[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CustomButtonTwo(
                            text: " + CUSTOM INSPECTION",
                            onPressed: () {
                              context.push(
                                "/inspectiontypedetailspage",
                                extra: {
                                  "jobId": widget.jobId,
                                  "inspectionTypeId": 2,
                                  "inspectionFormId": 0,
                                },
                              );
                            },
                          ),
                        ),
                      ]
                      // PREDEFINED INSPECTION ASSIGNED
                      else if (inspTypeCtrl.isPredefinedInspectionAssigned &&
                          inspTypeCtrl.isInspectionAssigned) ...[
                        _buildPredefinedSection(navigateDirectly: true),
                      ]
                      // NOTHING ASSIGNED
                      else ...[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CustomButtonTwo(
                            text: " + CUSTOM INSPECTION",
                            onPressed: () async {
                              if (userDepartment == 0 ||
                                  userDepartment == 1 ||
                                  userDepartment == 2 ||
                                  userDepartment == 5) {
                                await showTechnicianBottomSheet();
                              }
                            },
                          ),
                        ),

                        _buildPredefinedSection(navigateDirectly: false),
                      ],

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

  Widget _buildPredefinedSection({required bool navigateDirectly}) {
    final inspTypeCtrl = context.read<InspectionsummarypageController>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "Predefined Inspection List",
            style: ApptextstyleConstants.semiBoldText(
              fontSize: 16,
              color: ColorConstants.blackColor,
            ),
          ),
        ),

        // Your existing Search Widget here
        // (Copy your current search Row exactly as-is)
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

                      borderSide: BorderSide(color: ColorConstants.activecolor),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),

                      borderSide: BorderSide(color: ColorConstants.activecolor),
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
                                  .read<InspectionDetailsController>()
                                  .getInspectionTypes();
                            },
                          ),

                        IconButton(
                          icon: const Icon(Icons.search),

                          onPressed: () =>
                              _triggerSearch(searchController.text),
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

            if (inspectionController.inspectiontypesList.isEmpty) {
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

            final list = inspTypeCtrl.isPredefinedInspectionAssigned
                ? inspectionController.inspectiontypesList
                      .where(
                        (e) =>
                            e["inspectionFormId"] == inspTypeCtrl.vimIfMasterId,
                      )
                      .toList()
                : inspectionController.inspectiontypesList;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomButtonWidget(
                    text: (item["inspectionFormName"] ?? "No Name")
                        .toUpperCase(),
                    textSize: 16,
                    onPressed: () async {
                      // PREDEFINED ALREADY ASSIGNED
                      if (navigateDirectly) {
                        context.push(
                          "/inspectiontypedetailspage",
                          extra: {
                            "jobId": widget.jobId,
                            "inspectionFormId": item["inspectionFormId"],
                          },
                        );
                        return;
                      }

                      // FIRST TIME ASSIGNMENT
                      if (userDepartment == 0 ||
                          userDepartment == 1 ||
                          userDepartment == 2 ||
                          userDepartment == 5) {
                        await showTechnicianBottomSheet(
                          inspectionFormId: item["inspectionFormId"],
                        );
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> showTechnicianBottomSheet({
    int? inspectionFormId,
    int? inspectionTypeId,
  }) async {
    final parentContext = context;
    final controller = context.read<InspectionDetailsController>();

    await controller.getTechnicianList();

    TextEditingController searchController = TextEditingController();

    List<Map<String, dynamic>> filteredList = List.from(
      controller.technicianList,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Technician List",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search Technician",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          filteredList = controller.technicianList
                              .where(
                                (e) => e["userName"]
                                    .toString()
                                    .toLowerCase()
                                    .contains(value.toLowerCase()),
                              )
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final technician = filteredList[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,

                              child: const Icon(
                                Icons.person,
                                color: Colors.green,
                              ),
                            ),
                            title: Text(
                              technician["userName"]
                                  .toString()
                                  .split(' ')
                                  .map(
                                    (word) => word.isNotEmpty
                                        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                                        : '',
                                  )
                                  .join(' '),
                            ),
                            subtitle: const Text("Technician"),
                            trailing: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.green,
                            ),
                            onTap: () async {
                              Navigator.pop(context);

                              final controller = context
                                  .read<InspectionDetailsController>();

                              final success = await controller.assignTechnician(
                                jobId: widget.jobId ?? 0,

                                assigneeId:
                                    int.tryParse(
                                      technician["userId"].toString(),
                                    ) ??
                                    0,

                                supervisorId: controller.loginTechnicianId ?? 0,

                                technicianName: technician["userName"]
                                    .toString(),

                                formMasterId: inspectionFormId,
                                status: 4,
                              );
                              // log("Assign Technician Response: $success");

                              if (success) {
                                // log(success.toString());

                                ScaffoldMessenger.of(
                                  parentContext,
                                ).showSnackBar(
                                  SnackBar(
                                    backgroundColor: ColorConstants.greenColor,
                                    content: Text(
                                      "Technician Assigned Successfully",
                                    ),
                                  ),
                                );
                                if (userDepartment == 0 ||
                                    userDepartment == 1) {
                                  await parentContext
                                      .read<InspectionsummarypageController>()
                                      .getInspectionSummary(widget.jobId!);

                                  await parentContext
                                      .read<JobcarddetailsController>()
                                      .postJobCardDetails(widget.jobId!);

                                  await parentContext
                                      .read<InspectionDetailsController>()
                                      .getInspectionTypes();

                                  if (!mounted) return;

                                  setState(() {});

                                  return;
                                } else {
                                  parentContext.go("/home");
                                }
                              } else {
                                // log("Technician Assignment Failed");

                                // log("======================================");
                                ScaffoldMessenger.of(
                                  parentContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: ColorConstants.errorcolor,
                                    content: Text(
                                      "Technician Assignment Failed",
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
