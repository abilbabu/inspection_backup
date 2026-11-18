class CustomerInspectionHistoryModel {
  final int? jobId;
  final String? jobNo;
  final String? jobLaabsJobcardno;
  final String? jobCreatedOn;
  final int? vehicleId;
  final String? vehiclePlateNo;
  final String? vehiclePlateCode;
  final String? vehiclePlateCity;
  final String? vehicleVinNo;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleModelYear;
  final int? vehicleOdometer;
  final String? inspectionType;
  final int? jobStatus;
  final String? statusName;
  final int? technicianId;
  final String? technicianName;
  final int? advisorId;
  final String? advisorName;
  final String? customerComplaint;
  final int? iirId;
  final int? vimId;
  final bool? hasInspectionReport;

  CustomerInspectionHistoryModel({
    this.jobId,
    this.jobNo,
    this.jobLaabsJobcardno,
    this.jobCreatedOn,
    this.vehicleId,
    this.vehiclePlateNo,
    this.vehiclePlateCode,
    this.vehiclePlateCity,
    this.vehicleVinNo,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleModelYear,
    this.vehicleOdometer,
    this.inspectionType,
    this.jobStatus,
    this.statusName,
    this.technicianId,
    this.technicianName,
    this.advisorId,
    this.advisorName,
    this.customerComplaint,
    this.iirId,
    this.vimId,
    this.hasInspectionReport,
  });

  factory CustomerInspectionHistoryModel.fromJson(Map<String, dynamic> json) {
    return CustomerInspectionHistoryModel(
      jobId: _parseInt(json['jobId']),
      jobNo: json['jobNo']?.toString(),
      jobLaabsJobcardno: json['jobLaabsJobcardno']?.toString(),
      jobCreatedOn: json['jobCreatedOn']?.toString(),
      vehicleId: _parseInt(json['vehicleId']),
      vehiclePlateNo: json['vehiclePlateNo']?.toString(),
      vehiclePlateCode: json['vehiclePlateCode']?.toString(),
      vehiclePlateCity: json['vehiclePlateCity']?.toString(),
      vehicleVinNo: json['vehicleVinNo']?.toString(),
      vehicleMake: json['vehicleMake']?.toString(),
      vehicleModel: json['vehicleModel']?.toString(),
      vehicleModelYear: json['vehicleModelYear']?.toString(),
      vehicleOdometer: _parseInt(json['vehicleOdometer']),
      inspectionType: json['inspectionType']?.toString(),
      jobStatus: _parseInt(json['jobStatus']),
      statusName: json['statusName']?.toString(),
      technicianId: _parseInt(json['technicianId']),
      technicianName: json['technicianName']?.toString(),
      advisorId: _parseInt(json['advisorId']),
      advisorName: json['advisorName']?.toString(),
      customerComplaint: json['customerComplaint']?.toString(),
      iirId: _parseInt(json['iirId']),
      vimId: _parseInt(json['vimId']),
      hasInspectionReport: json['hasInspectionReport'] == true,
    );
  }

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    return int.tryParse(val.toString());
  }
}

class CustomerInspectionHistoryResponse {
  final List<CustomerInspectionHistoryModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;
  final bool hasMore;
  final bool isExistingCustomer;
  final int? customerId;
  final String? customerName;
  final String? customerMobile;

  CustomerInspectionHistoryResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.hasMore,
    required this.isExistingCustomer,
    this.customerId,
    this.customerName,
    this.customerMobile,
  });

  factory CustomerInspectionHistoryResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['content'] as List? ?? [];
    List<CustomerInspectionHistoryModel> list = rawList
        .map((e) => CustomerInspectionHistoryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return CustomerInspectionHistoryResponse(
      content: list,
      page: _parseInt(json['page']) ?? 0,
      size: _parseInt(json['size']) ?? 20,
      totalElements: _parseInt(json['totalElements']) ?? list.length,
      totalPages: _parseInt(json['totalPages']) ?? 1,
      last: json['last'] == true,
      hasMore: json['hasMore'] == true,
      isExistingCustomer: json['isExistingCustomer'] == true,
      customerId: _parseInt(json['customerId']),
      customerName: json['customerName']?.toString(),
      customerMobile: json['customerMobile']?.toString(),
    );
  }

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    return int.tryParse(val.toString());
  }
}
