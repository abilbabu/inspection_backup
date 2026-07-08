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

class TechnicianDashboard extends StatefulWidget {
  const TechnicianDashboard({super.key});

  @override
  State<TechnicianDashboard> createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<dynamic> _jobs = [];
  bool _isLoading = true;
  bool _isMoreLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 20;

  String _searchText = "";
  String _activeFilter = "all"; // 'all', 'pending', 'ongoing', 'reinspection'

  Map<String, dynamic> _counts = {
    "all": 0,
    "pending": 0,
    "ongoing": 0,
    "reinspection": 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchJobs(refresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _fetchJobs();
      }
    });

    _searchController.addListener(() {
      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _searchText = _searchController.text.trim();
          });
          _fetchJobs(refresh: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {"name": prefs.getString("userName") ?? "System User"};
  }

  Future<void> _fetchJobs({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _hasMore = true;
        _jobs = [];
        _isLoading = true;
      });
    } else {
      if (!_hasMore || _isMoreLoading) return;
      setState(() {
        _isMoreLoading = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      final userId = prefs.getString('userId');
      if (userId == null || userToken == null) return;

      int? statusParam;
      if (_activeFilter == "pending") {
        statusParam = 4;
      } else if (_activeFilter == "ongoing") {
        statusParam = 5;
      } else if (_activeFilter == "reinspection") {
        statusParam = 10;
      }

      final body = {
        "technicianId": int.parse(userId),
        "page": _currentPage,
        "size": _pageSize,
        if (statusParam != null) "statusId": statusParam,
        if (_searchText.isNotEmpty) "searchText": _searchText,
      };

      final response = await http.post(
        Uri.parse(ApiServices.technicianJobsPaginated),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded["statusCode"] == 200 && decoded["data"] != null) {
          final data = decoded["data"];
          final jobsPage = data["jobs"] ?? {};
          final List newJobs = jobsPage["content"] ?? [];
          final bool last = jobsPage["last"] ?? true;
          final countsData = data["counts"] ?? {};

          setState(() {
            _jobs.addAll(newJobs);
            _hasMore = !last;
            _currentPage++;
            _counts = {
              "all": countsData["all"] ?? 0,
              "pending": countsData["pending"] ?? 0,
              "ongoing": countsData["ongoing"] ?? 0,
              "reinspection": countsData["reinspection"] ?? 0,
            };
          });
        }
      }
    } catch (e) {
      debugPrint("❗ Error fetching technician jobs: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _isMoreLoading = false;
      });
    }
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
                onRefresh: () => _fetchJobs(refresh: true),
                child: _isLoading
                    ? _shimmerLoading()
                    : _jobs.isEmpty
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
      {"key": "pending", "label": "Inspection\nPending"},
      {"key": "ongoing", "label": "Ongoing"},
      {"key": "reinspection", "label": "Re-Inspection"},
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
                  _fetchJobs(refresh: true);
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
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 120, left: 12, right: 12),
      itemCount: _jobs.length + (_isMoreLoading ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == _jobs.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _jobCardItem(_jobs[index]);
      },
    );
  }

  Widget _jobCardItem(Map<String, dynamic> item) {
    final controller = Provider.of<HomescreenController>(context, listen: false);
    final String jobStatusStr = item['jobStatus']?.toString().trim() ?? "";
    final int jobStatus = int.tryParse(jobStatusStr) ?? 0;
    final String statusText = controller.getJobStatusText(jobStatusStr);
    final vehicle = item["vehicle"] ?? {};
    final String vehicleName = "${vehicle['vMake'] ?? ''} ${vehicle['vModel'] ?? ''}";

    // Color code mappings
    Color statusColor = Colors.grey;
    if (jobStatus == 4) {
      statusColor = Colors.amber; // Pending
    } else if (jobStatus == 5) {
      statusColor = Colors.blue; // Ongoing
    } else if (jobStatus == 10 || jobStatus == 11 || jobStatus == 18) {
      statusColor = Colors.purple; // Re-Inspection
    } else if (jobStatus == 6 || jobStatus == 12) {
      statusColor = Colors.green; // Completed
    }

    return GestureDetector(
      onTap: () {
        final int jobId = int.tryParse(item["jobId"]?.toString() ?? "0") ?? 0;
        if (jobStatus == 10 || jobStatus == 11 || jobStatus == 18) {
          context.go("/reassigneddetails", extra: jobId);
          return;
        } else if (jobStatus == 5) {
          context.go("/jobcarddetails", extra: jobId);
          return;
        }
        final List inspections = item["inspections"] ?? [];
        int inspectionTypeId = 2;
        int inspectionMasterId = 0;
        if (inspections.isNotEmpty) {
          final master = inspections.first["master"];
          inspectionTypeId =
              int.tryParse(master?["vimInspectionType"]?.toString() ?? "2") ??
              2;
          inspectionMasterId =
              int.tryParse(master?["vimIfMasterId"]?.toString() ?? "0") ?? 0;
        }
        context.go(
          "/inspectiontypedetailspage",
          extra: {
            "inspectionFormId": inspectionMasterId,
            "jobId": jobId,
            "inspectionTypeId": inspectionTypeId,
          },
        );
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
                      "Plate No : ${item['jobRegNo'] ?? vehicle['vRegNo'] ?? 'N/A'}",
                      style: ApptextstyleConstants.lightText(
                        fontSize: 13,
                        color: ColorConstants.blackColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Vin No: ${vehicle['vVinNo'] ?? 'N/A'}",
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
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
                  : "There are no jobs assigned to you at the moment.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
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
