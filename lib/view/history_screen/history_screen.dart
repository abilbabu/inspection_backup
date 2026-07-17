import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/homeScreen_controller.dart';
import 'package:inspection/utils/app_theme/app_theme.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class HistoryScreenList extends StatefulWidget {
  final bool isFromSettings;
  const HistoryScreenList({super.key, this.isFromSettings = false});

  @override
  State<HistoryScreenList> createState() => _HistoryScreenListState();
}

class _HistoryScreenListState extends State<HistoryScreenList> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<dynamic> _allJobs = []; // full filtered list from API
  List<dynamic> _jobs = []; // currently displayed page slice
  bool _isLoading = true;
  bool _isMoreLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 20;

  int _userDepartment = 0;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _init();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadNextPage();
      }
    });

    _searchController.addListener(() {
      if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _searchText = _searchController.text.trim();
          });
          _applyFilterAndReset();
        }
      });
    });
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userDepartment =
        int.tryParse(prefs.getString('userDepartment') ?? '0') ?? 0;
    await _fetchAllFromApi();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  List<int> get _allowedStatuses {
    if (_userDepartment == 2 || _userDepartment == 4 || _userDepartment == 5) {
      return [6, 9, 12, 14];
    }
    return [6, 7, 8, 9, 12, 14, 15, 16, 17, 18, 19];
  }

  Future<void> _fetchAllFromApi() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('userToken');
      final userId = prefs.getString('userId');
      final userDepartment = prefs.getString('userDepartment');

      if (userId == null || userToken == null || userDepartment == null) return;

      _userDepartment = int.tryParse(userDepartment) ?? 0;

      final response = await http.post(
        Uri.parse(ApiServices.allInspectionList),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({
          'userId': int.parse(userId),
          'userDepartment': int.parse(userDepartment),
        }),
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        final List rawList = res['data'] ?? [];
        final allowed = _allowedStatuses;

        final mapped = rawList
            .map((item) {
              final vehicle = item['vehicle'] ?? {};
              return {
                'jobId': item['jobId']?.toString() ?? '',
                'jobNo': item['jobNo']?.toString() ?? '',
                'jobLaabsJobcardno':
                    (item['jobLaabsJobcardno'] ??
                            item['laabsjobCardNo'] ??
                            item['laabsJobCardNo'])
                        ?.toString() ??
                    '',
                'jobStatus': item['jobStatus']?.toString() ?? '',
                'jobRegNo': item['jobRegNo']?.toString() ?? '',
                'plateNo': vehicle['vRegNo']?.toString() ?? '',
                'vinNo': vehicle['vVinNo']?.toString() ?? '',
                'vehicle': vehicle,
              };
            })
            .where((item) {
              final status =
                  int.tryParse(item['jobStatus']?.toString() ?? '0') ?? 0;
              return allowed.contains(status);
            })
            .toList()
            .reversed
            .toList();

        _allJobs = mapped;
      }
    } catch (e) {
      debugPrint('History fetch error: $e');
    } finally {
      _applyFilterAndReset();
    }
  }

  void _applyFilterAndReset() {
    final filtered = _allJobs.where((item) {
      return _searchText.isEmpty ||
          (item['jobNo']?.toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ) ??
              false);
    }).toList();

    final firstPage = filtered.take(_pageSize).toList();
    setState(() {
      _jobs = firstPage;
      _currentPage = 1;
      _hasMore = filtered.length > _pageSize;
      _isLoading = false;
      _isMoreLoading = false;
    });
  }

  void _loadNextPage() {
    if (!_hasMore || _isMoreLoading) return;
    setState(() => _isMoreLoading = true);

    final filtered = _allJobs.where((item) {
      return _searchText.isEmpty ||
          (item['jobNo']?.toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ) ??
              false);
    }).toList();

    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);

    if (start >= filtered.length) {
      setState(() {
        _hasMore = false;
        _isMoreLoading = false;
      });
      return;
    }

    final nextItems = filtered.sublist(start, end);
    setState(() {
      _jobs.addAll(nextItems);
      _currentPage++;
      _hasMore = end < filtered.length;
      _isMoreLoading = false;
    });
  }

  Color _statusColor(int jobStatus) {
    if (jobStatus == 4) return Colors.amber;
    if (jobStatus == 5) return Colors.blue;
    if (jobStatus == 10 || jobStatus == 11 || jobStatus == 18) {
      return Colors.purple;
    }
    if (jobStatus == 6 || jobStatus == 12) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = AppTheme(
      child: Column(
        children: [
          const SizedBox(height: 50),
          _headerSection(),
          const SizedBox(height: 12),
          _searchSection(),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchAllFromApi,
              child: _isLoading
                  ? _shimmerLoading()
                  : _jobs.isEmpty
                  ? _emptyStateView()
                  : _listView(),
            ),
          ),
        ],
      ),
    );

    if (widget.isFromSettings) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/settings');
          }
        },
        child: Scaffold(body: bodyContent),
      );
    }

    return Scaffold(body: bodyContent);
  }

  Widget _headerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (widget.isFromSettings) ...[
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/settings');
                }
              },
            ),
            const SizedBox(width: 8),
          ],
          Text(
            'Job Card History',
            style: ApptextstyleConstants.regularText(
              fontSize: 20,
              color: ColorConstants.whiteColor,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
              onPressed: _fetchAllFromApi,
              tooltip: 'Refresh',
            ),
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
            hintText: 'Search Job-Card Number',
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
    final controller = Provider.of<HomescreenController>(
      context,
      listen: false,
    );
    final String? jobLaabsJobcardno =
        (item['jobLaabsJobcardno'] ??
                item['laabsjobCardNo'] ??
                item['laabsJobCardNo'])
            ?.toString();
    final bool showLaabs =
        jobLaabsJobcardno != null &&
        jobLaabsJobcardno.trim().isNotEmpty &&
        jobLaabsJobcardno.trim().toLowerCase() != 'null';
    final String jobStatusStr = item['jobStatus']?.toString().trim() ?? '';
    final int jobStatus = int.tryParse(jobStatusStr) ?? 0;
    final String statusText = controller.getJobStatusText(jobStatusStr);
    final vehicle = item['vehicle'] ?? {};
    final String vMake = vehicle['vMake']?.toString() ?? '';
    final String vModel = vehicle['vModel']?.toString() ?? '';
    final String vehicleName = '$vMake $vModel'.trim();
    final Color statusColor = _statusColor(jobStatus);

    return GestureDetector(
      onTap: () {
        final int jobId = int.tryParse(item['jobId']?.toString() ?? '0') ?? 0;
        context.go('/jobcarddetails', extra: jobId);
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
                child: Image.asset('assets/image/benz.png', fit: BoxFit.cover),
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
                            item['jobNo'] ?? '',
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
                    const SizedBox(height: 5),
                    if (showLaabs) ...[
                      RichText(
                        text: TextSpan(
                          text: "Laabs Job Card No: ",
                          style: ApptextstyleConstants.thinText(
                            fontSize: 10,
                            color: ColorConstants.blackColor,
                          ).copyWith(fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: jobLaabsJobcardno,
                              style: ApptextstyleConstants.thinText(
                                fontSize: 10,
                                color: ColorConstants.greenColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Plate No : ${item['plateNo'] ?? item['jobRegNo'] ?? 'N/A'}',
                      style: ApptextstyleConstants.lightText(
                        fontSize: 13,
                        color: ColorConstants.blackColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vin No : ${item['vinNo'] ?? vehicle['vVinNo'] ?? 'N/A'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ApptextstyleConstants.lightText(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (vehicleName.isNotEmpty) ...[
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
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Job Cards Found',
              style: ApptextstyleConstants.mediumText(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchText.isNotEmpty
                  ? 'We couldn\'t find any history matching "$_searchText"'
                  : 'There are no completed job cards at the moment.',
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
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 120,
          left: 12,
          right: 12,
        ),
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
