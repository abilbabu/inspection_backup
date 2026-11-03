import 'package:flutter/material.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:intl/intl.dart';

class HomescreenController with ChangeNotifier {
  String normalizeStatus(String? status) {
    if (status == null) return "";
    final trimmed = status.trim();
    final asInt = int.tryParse(trimmed);
    if (asInt != null) return asInt.toString();

    final upper = trimmed.toUpperCase().replaceAll('_', ' ').replaceAll('-', ' ');
    if (upper.contains("BOOKING SHEET INITIALIS") || upper.contains("BOOKING SHEET INITIALIZ")) {
      return "0";
    }
    if (upper.contains("BOOKING SHEET CREATED") || upper == "BOOKING SHEET") {
      return "1";
    }
    if (upper.contains("BASIC INSPECTION IN PROGRESS") || upper.contains("BASIC INSPECTION")) {
      return "2";
    }
    if (upper.contains("JOBCARD OPEN") || upper == "OPEN") {
      return "3";
    }
    if (upper.contains("INSPECTION ASSIGNED")) {
      return "4";
    }
    if (upper.contains("INSPECTION IN PROGRESS")) {
      return "5";
    }
    if (upper.contains("INSPECTION COMPLETED")) {
      return "6";
    }
    if (upper.contains("REPORT VERIFICATION IN PROGRESS") || upper.contains("REPORT VERIFICATION IN-PROGRESS")) {
      return "7";
    }
    if (upper.contains("REPORT WAITING FOR APPROVAL")) {
      return "8";
    }
    if (upper.contains("QUOTATION REQUESTED")) {
      return "9";
    }
    if (upper.contains("RE INSPECTION APPROVED") || upper.contains("RE-INSPECTION APPROVED")) {
      return "10";
    }
    if (upper.contains("RE INSPECTION IN PROGRESS") || upper.contains("RE-INSPECTION IN PROGRESS")) {
      return "11";
    }
    if (upper.contains("RE INSPECTION COMPLETED") || upper.contains("RE-INSPECTION COMPLETED")) {
      return "12";
    }
    if (upper.contains("RE INSPECTION REQUESTED") || upper.contains("RE-INSPECTION REQUESTED")) {
      return "14";
    }
    if (upper.contains("RE INSPECTION VERIFICATION") || upper.contains("RE-INSPECTION VERIFICATION")) {
      return "15";
    }
    if (upper.contains("RE INSPECTION WAITING FOR APPROVAL") || upper.contains("RE-INSPECTION WAITING FOR APPROVAL")) {
      return "16";
    }
    if (upper.contains("RE INSPECTION REJECTED") || upper.contains("RE-INSPECTION REJECTED")) {
      return "17";
    }
    if (upper.contains("RE INSPECTION ASSIGNED") || upper.contains("RE-INSPECTION ASSIGNED")) {
      return "18";
    }
    if (upper.contains("QUOTATION VERIFICATION IN PROGRESS")) {
      return "19";
    }
    return trimmed;
  }

  String getJobStatusText(String? status) {
    final normalized = normalizeStatus(status);
    switch (normalized) {
      case "0":
        return "Booking Sheet Initialised";
      case "1":
        return "Booking Sheet Created";
      case "2":
        return "Basic Inspection In Progress";
      case "3":
        return "Jobcard Open";
      case "4":
        return "Inspection Assigned";
      case "5":
        return "Inspection In Progress";
      case "6":
        return "Inspection Completed";
      case "7":
        return "Inspection Report Verification In-Progress";
      case "8":
        return "Inspection Report Waiting For Approval";
      case "9":
        return "Quotation Requested";
      case "10":
        return "Re-Inspection Approved";
      case "11":
        return "Re-Inspection In Progress";
      case "12":
        return "Re-Inspection Completed";
      case "14":
        return "Re-Inspection Requested";
      case "15":
        return "Re-Inspection Verification";
      case "16":
        return "Re-Inspection Waiting for Approval";
      case "17":
        return "Re-Inspection Rejected";
      case "18":
        return "Re-Inspection Assigned";
      case "19":
        return "Quotation Verification In Progress";
      default:
        if (status != null && status.trim().isNotEmpty && status.trim() != "null") {
          return status.trim();
        }
        return "Unknown Status";
    }
  }

  Color getJobStatusColor(String? status) {
    final normalized = normalizeStatus(status);
    switch (normalized) {
      case "0":
        return ColorConstants.holdorangeColor;
      case "1":
        return Colors.purple;
      case "2":
        return ColorConstants.textBlueColor;
      case "3":
        return ColorConstants.textBlueColor;
      case "4":
        return Colors.purple;
      case "5":
        return Colors.purple;
      case "6":
        return Colors.indigo;
      case "7":
        return Colors.indigo;
      case "8":
        return ColorConstants.greenColor;
      case "9":
        return ColorConstants.greenColor;
      case "10":
        return ColorConstants.warningcolor;
      case "11":
        return ColorConstants.bottamNavBarButton;
      case "12":
        return Colors.teal;
      case "14":
        return ColorConstants.warningcolor;
      case "15":
        return ColorConstants.textBlueColor;
      case "16":
        return ColorConstants.holdorangeColor;
      case "17":
        return Colors.red;
      case "18":
        return Colors.purple;
      case "19":
        return ColorConstants.orangecolor;
      default:
        return ColorConstants.holdorangeColor;
    }
  }

  String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      DateTime dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
    } catch (e) {
      return dateStr;
    }
  }
}
