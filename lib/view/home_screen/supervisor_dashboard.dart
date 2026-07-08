import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/homeScreen_controller.dart';
import 'package:inspection/utils/app_theme/app_theme.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<dynamic> _allJobs = [];
  List<dynamic> _filteredJobs = [];
  bool _isLoading = true;

  String _searchText = "";
  String _activeFilter = "all"; // 'all', 'pending', 'assigned', 'reassigned'

  Map<String, dynamic> _counts = {
    "all": 0,
    "pending": 0,
    "assigned": 0,
    "reassigned": 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchJobs();

    _searchController.addListener(() {
      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _searchText = _searchController.text.trim();
          });
          _applyFilterAndSearch();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {"name": prefs.getString("userName") ?? "System User"};
  }

  Future<void> _fetchJobs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      final userId = prefs.getString('userId');
      if (userId == null || userToken == null) return;

      final response = await http.post(
        Uri.parse(ApiServices.allInspectionList),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode({
          "userId": int.parse(userId),
          "userDepartment": 2, // Department 2 for Supervisor
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List rawJobs = decoded["data"] ?? [];
        
        final filteredList = rawJobs.where((item) {
          final status = int.tryParse(item["jobStatus"]?.toString() ?? "") ?? -1;
          return ![0, 1, 2, -1].contains(status);
        }).toList();

        // Reverse to show latest first
        final reversedJobs = filteredList.reversed.toList();

        _allJobs = reversedJobs.map((item) {
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
            "userDepartment": item["userDepartment"],
            "inspections": item["inspections"] ?? [],
          };
        }).toList();

        _applyFilterAndSearch();
      }
    } catch (e) {
      debugPrint("❗ Error fetching supervisor jobs: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilterAndSearch() {
    List<dynamic> temp = List.from(_allJobs);

    // Search filter
    if (_searchText.isNotEmpty) {
      temp = temp.where((item) {
        final jobNo = item["jobNo"]?.toString().toLowerCase() ?? "";
        final plateNo = item["plateNo"]?.toString().toLowerCase() ?? "";
        final vinNo = item["vinNo"]?.toString().toLowerCase() ?? "";
        return jobNo.contains(_searchText.toLowerCase()) ||
            plateNo.contains(_searchText.toLowerCase()) ||
            vinNo.contains(_searchText.toLowerCase());
      }).toList();
    }

    // Dynamic counts based on search results
    int allCount = 0;
    int pendingCount = 0;
    int assignedCount = 0;
    int reassignedCount = 0;

    for (var item in _allJobs) {
      if (_searchText.isNotEmpty) {
        final jobNo = item["jobNo"]?.toString().toLowerCase() ?? "";
        final plateNo = item["plateNo"]?.toString().toLowerCase() ?? "";
        final vinNo = item["vinNo"]?.toString().toLowerCase() ?? "";
        final matches = jobNo.contains(_searchText.toLowerCase()) ||
            plateNo.contains(_searchText.toLowerCase()) ||
            vinNo.contains(_searchText.toLowerCase());
        if (!matches) continue;
      }

      final status = int.tryParse(item["jobStatus"]?.toString() ?? "0") ?? 0;
      if (status == 3 || status == 4 || status == 10) {
        allCount++;
        if (status == 3) {
          pendingCount++;
        } else if (status == 4) {
          assignedCount++;
        } else if (status == 10) {
          reassignedCount++;
        }
      }
    }

    // Apply active tab filter
    if (_activeFilter == "all") {
      temp = temp.where((item) {
        final status = int.tryParse(item["jobStatus"]?.toString() ?? "0") ?? 0;
        return status == 3 || status == 4 || status == 10;
      }).toList();
    } else if (_activeFilter == "pending") {
      temp = temp.where((item) {
        final status = int.tryParse(item["jobStatus"]?.toString() ?? "0") ?? 0;
        return status == 3;
      }).toList();
    } else if (_activeFilter == "assigned") {
      temp = temp.where((item) {
        final status = int.tryParse(item["jobStatus"]?.toString() ?? "0") ?? 0;
        return status == 4;
      }).toList();
    } else if (_activeFilter == "reassigned") {
      temp = temp.where((item) {
        final status = int.tryParse(item["jobStatus"]?.toString() ?? "0") ?? 0;
        return status == 10;
      }).toList();
    }

    setState(() {
      _filteredJobs = temp;
      _counts = {
        "all": allCount,
        "pending": pendingCount,
        "assigned": assignedCount,
        "reassigned": reassignedCount,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppTheme(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            _headerSection(),
            const SizedBox(height: 12),
            _searchSection(),
            const SizedBox(height: 12),
            _filterChipsSection(),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchJobs,
                child: _isLoading
                    ? _shimmerLoading()
                    : _filteredJobs.isEmpty
                        ? _emptyStateView()
                        : _listView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            "Welcome, ",
            style: ApptextstyleConstants.extraLightText(
              fontSize: 18,
              color: ColorConstants.whiteColor,
            ),
          ),
          FutureBuilder(
            future: _getSavedUser(),
            builder: (context, snapshot) {
              final name = snapshot.hasData
                  ? snapshot.data!["name"] ?? "System User"
                  : "System User";
              return Text(
                name,
                style: ApptextstyleConstants.regularText(
                  fontSize: 20,
                  color: ColorConstants.whiteColor,
                ),
              );
            },
          ),
          const Spacer(),
          HugeIcon(
            icon: HugeIcons.strokeRoundedNotification01,
            color: ColorConstants.whiteColor.withOpacity(0.2),
            size: 25,
          ),
        ],
      ),
    );
  }

  Widget _searchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search Job-Card Number",
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChipsSection() {
    final filters = [
      {"key": "all", "label": "All"},
      {"key": "pending", "label": "Pending"},
      {"key": "assigned", "label": "Assigned"},
      {"key": "reassigned", "label": "Reassigned"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 56,
        child: Row(
          children: filters.map((f) {
            final key = f["key"]!;
            final label = f["label"]!;
            final count = _counts[key] ?? 0;
            final isSelected = _activeFilter == key;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (isSelected) return;
                  setState(() {
                    _activeFilter = key;
                  });
                  _applyFilterAndSearch();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF0066A6), Color(0xFF00BFA6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 9,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "($count)",
                        style: TextStyle(
                          color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _listView() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 120, left: 12, right: 12),
      itemCount: _filteredJobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _jobCardItem(_filteredJobs[index]);
      },
    );
  }

  Widget _jobCardItem(Map<String, dynamic> item) {
    final controller = Provider.of<HomescreenController>(context, listen: false);
    final String jobStatusStr = item['jobStatus']?.toString().trim() ?? "";
    final int jobStatus = int.tryParse(jobStatusStr) ?? 0;
    final String statusText = controller.getJobStatusText(jobStatusStr);
    final String vehicleName = "${item['make'] ?? ''} ${item['model'] ?? ''}";

    Color statusColor = controller.getJobStatusColor(jobStatusStr);

    return GestureDetector(
      onTap: () {
        final dynamic rawJobId = item['jobId'];
        final int jobId = rawJobId is int
            ? rawJobId
            : int.tryParse(rawJobId?.toString() ?? '0') ?? 0;
        if (jobStatus == 3) {
          context.go("/jobcarddetails", extra: jobId);
        } else if (jobStatus == 4) {
          context.go("/jobcarddetails", extra: jobId);
        } else if (jobStatus == 5) {
          context.go("/jobcarddetails", extra: jobId);
        } else if (jobStatus == 10) {
          context.go("/reassigneddetails", extra: jobId);
        }else if (jobStatus == 11) {
          context.go("/reassigneddetails", extra: jobId);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: ColorConstants.whiteColor,
          boxShadow: ColorConstants.dashboardboxShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: ColorConstants.containergreycolor,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  "assets/image/benz.png",
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['jobNo'] ?? "",
                            style: ApptextstyleConstants.regularText(
                              fontSize: 15,
                              color: ColorConstants.blackColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: ApptextstyleConstants.thinText(
                                  fontSize: 10,
                                  color: statusColor,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Plate No : ${item['plateNo'] ?? 'N/A'}",
                      style: ApptextstyleConstants.lightText(
                        fontSize: 13,
                        color: ColorConstants.blackColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Vin No: ${item['vinNo'] ?? 'N/A'}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ApptextstyleConstants.lightText(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (vehicleName.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        vehicleName,
                        style: ApptextstyleConstants.thinText(
                          fontSize: 12,
                          color: ColorConstants.blackColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyStateView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          height: 400,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "No Job Cards Found",
                style: ApptextstyleConstants.mediumText(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchText.isNotEmpty
                    ? "We couldn't find any job cards matching \"$_searchText\""
                    : "There are no job cards available at the moment.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shimmerLoading() {
    return Shimmer(
      duration: const Duration(seconds: 2),
      color: Colors.white,
      colorOpacity: 0.3,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 120, left: 12, right: 12),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
          ),
        ),
      ),
    );
  }
}
