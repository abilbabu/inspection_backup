import 'package:flutter/material.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:intl/intl.dart';

class HomescreenController with ChangeNotifier {
  String getJobStatusText(String? status) {
    switch (status) {
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
        return "Unknown Status";
    }
  }

  Color getJobStatusColor(String? status) {
    switch (status) {
      case "0":
        return ColorConstants.blackColor;
      case "1":
        return ColorConstants.blackColor;
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
        return ColorConstants.orangecolor;
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
