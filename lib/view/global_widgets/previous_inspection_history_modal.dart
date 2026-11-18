import 'package:flutter/material.dart';
import 'package:inspection/controller/basicInspectionReport_controller.dart';
import 'package:inspection/controller/customer_inspection_history_controller.dart';
import 'package:inspection/controller/homeScreen_controller.dart';
import 'package:inspection/controller/inspectionSummaryPage_controller.dart';
import 'package:inspection/controller/jobCardDetails_controller.dart';
import 'package:inspection/model/customer_inspection_history_model.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/home_screen/widget/JobCardDetails.dart';
import 'package:provider/provider.dart';

void showPreviousInspectionHistoryModal(
  BuildContext context, {
  int? customerId,
  int? jobId,
  String? customerMobile,
  String? customerName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => PreviousInspectionHistoryModal(
      customerId: customerId,
      jobId: jobId,
      customerMobile: customerMobile,
      customerName: customerName,
    ),
  );
}

class PreviousInspectionHistoryModal extends StatefulWidget {
  final int? customerId;
  final int? jobId;
  final String? customerMobile;
  final String? customerName;

  const PreviousInspectionHistoryModal({
    super.key,
    this.customerId,
    this.jobId,
    this.customerMobile,
    this.customerName,
  });

  @override
  State<PreviousInspectionHistoryModal> createState() =>
      _PreviousInspectionHistoryModalState();
}

class _PreviousInspectionHistoryModalState
    extends State<PreviousInspectionHistoryModal> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<CustomerInspectionHistoryController>(
        context,
        listen: false,
      );
      controller.fetchHistory(
        customerId: widget.customerId,
        jobId: widget.jobId,
        customerMobile: widget.customerMobile,
        isRefresh: true,
      );
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        Provider.of<CustomerInspectionHistoryController>(
          context,
          listen: false,
        ).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return "-";
    try {
      final parsed = DateTime.parse(raw);
      final months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      final month = months[parsed.month - 1];
      final hour = parsed.hour > 12
          ? parsed.hour - 12
          : (parsed.hour == 0 ? 12 : parsed.hour);
      final ampm = parsed.hour >= 12 ? "PM" : "AM";
      final minute = parsed.minute.toString().padLeft(2, '0');
      return "${parsed.day} $month ${parsed.year}, $hour:$minute $ampm";
    } catch (_) {
      return raw;
    }
  }

  Future<void> _openJobDetails(CustomerInspectionHistoryModel item) async {
    final int? targetJobId = item.jobId;
    if (targetJobId == null) return;

    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => JobcarddetailsController()
                ..postJobCardDetails(targetJobId),
            ),
            ChangeNotifierProvider(
              create: (_) => InspectionsummarypageController(),
            ),
            ChangeNotifierProvider(
              create: (_) => BasicInspectionReportController(),
            ),
          ],
          child: JobCardDetails(
            jobId: targetJobId,
            isHistorical: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final homeController = Provider.of<HomescreenController>(
      context,
      listen: false,
    );

    return Container(
      height: size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<CustomerInspectionHistoryController>(
              builder: (context, controller, child) {
                final cName = controller.customerName ?? widget.customerName;
                final cMobile = controller.customerMobile ?? widget.customerMobile;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Previous Inspection History",
                                style: ApptextstyleConstants.boldText(
                                  fontSize: 16,
                                  color: ColorConstants.textBlueColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (controller.totalElements > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorConstants.syanColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${controller.totalElements}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: ColorConstants.syanColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (cName != null || cMobile != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              "${cName ?? ''}${cMobile != null ? ' ($cMobile)' : ''}".trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: Consumer<CustomerInspectionHistoryController>(
              builder: (context, controller, child) {
                if (controller.isLoading && controller.historyList.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (controller.errorMsg != null &&
                    controller.historyList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            controller.errorMsg!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => controller.fetchHistory(
                              customerId: widget.customerId,
                              jobId: widget.jobId,
                              customerMobile: widget.customerMobile,
                              isRefresh: true,
                            ),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (controller.historyList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history,
                            size: 56,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "No previous inspection history found",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "This customer does not have any prior completed inspections.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await controller.fetchHistory(
                      customerId: widget.customerId,
                      jobId: widget.jobId,
                      customerMobile: widget.customerMobile,
                      isRefresh: true,
                    );
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                    itemCount: controller.historyList.length +
                        (controller.isMoreLoading ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == controller.historyList.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final item = controller.historyList[index];
                      final statusColor = homeController.getJobStatusColor(
                        item.jobStatus?.toString(),
                      );
                      final statusText = item.statusName ??
                          homeController.getJobStatusText(
                            item.jobStatus?.toString(),
                          );
                      final isQuick = (item.inspectionType ?? "")
                          .toUpperCase()
                          .contains("QUICK");

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ColorConstants.dividergreycolor,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openJobDetails(item),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              // Top Row: Jobcard No, Type & Status Badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.jobNo ?? "Jobcard #${item.jobId ?? ''}",
                                          style: ApptextstyleConstants.boldText(
                                            fontSize: 14,
                                            color: ColorConstants.textBlueColor,
                                          ),
                                        ),
                                        if (item.jobLaabsJobcardno != null &&
                                            item.jobLaabsJobcardno!.isNotEmpty)
                                          Text(
                                            "LAABS: ${item.jobLaabsJobcardno}",
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Inspection Type
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isQuick
                                          ? ColorConstants.orangecolor
                                              .withOpacity(0.12)
                                          : ColorConstants.syanColor
                                              .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isQuick ? "QUICK" : "GENERAL",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isQuick
                                          ? ColorConstants.orangecolor
                                          : ColorConstants.syanColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.6),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Date
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(item.jobCreatedOn),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Vehicle details
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorConstants.boxColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.directions_car_outlined,
                                      size: 18,
                                      color: ColorConstants.lightblueColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.vehiclePlateNo != null &&
                                                    item.vehiclePlateNo!.isNotEmpty
                                                ? item.vehiclePlateNo!
                                                : "Vehicle #${item.vehicleId ?? ''}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (item.vehicleMake != null ||
                                              item.vehicleModel != null)
                                            Text(
                                              "${item.vehicleMake ?? ''} ${item.vehicleModel ?? ''} ${item.vehicleModelYear ?? ''}".trim(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black54,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (item.vehicleOdometer != null)
                                      Text(
                                        "${item.vehicleOdometer} km",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Tech & Advisor
                              if (item.technicianName != null ||
                                  item.advisorName != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (item.technicianName != null)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.engineering_outlined,
                                              size: 13,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                "Tech: ${item.technicianName}",
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (item.advisorName != null)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.person_outline,
                                              size: 13,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                "Adv: ${item.advisorName}",
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],

                              // Complaint
                              if (item.customerComplaint != null &&
                                  item.customerComplaint!.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  "Complaint: ${item.customerComplaint!.trim()}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              const SizedBox(height: 10),
                              // View Details Action
                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () => _openJobDetails(item),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          "View Details",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: ColorConstants.textBlueColor,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 10,
                                          color: ColorConstants.textBlueColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
