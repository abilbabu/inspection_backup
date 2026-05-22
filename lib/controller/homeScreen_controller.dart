import 'package:flutter/material.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:intl/intl.dart';

class HomescreenController with ChangeNotifier {
  String getJobStatusText(String? status) {
    switch (status) {
      case "0":
        return "Bookingsheet Initialized";
      case "1":
        return "Bookingsheet Created";
      case "2":
        return "Basic Inspection In Progress";
      case "3":
        return "Jobcard Open";
      case "4":
        return "Inspection Started";
      case "5":
        return "Inspection In Progress";
      case "6":
        return "Inspection Completed";
      case "7":
        return "Technician Report In Progress";
      case "8":
        return "Technician Report Waiting For Approval";
      case "9":
        return "Quotation Requested";
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
