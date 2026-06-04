import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiServices {
  // <-----"POST Method"------>
  static final String baseUrl = dotenv.env['API_URL'] ?? "";
  static String loginUrl = "${baseUrl}user-auth/userLogin";
  static String openJobcard = "${baseUrl}jobcard/open";
  static String vechileMode = "${baseUrl}vehicle/variants";
  static String fetchCustomerDetails = "${baseUrl}customer/getCustomerByMobile";
  static String fetchCustomerVehicleDetails =
      "${baseUrl}customerVehicleSearch/customerVehicle";
  static String updateOpenJobcard = "${baseUrl}jobcard/updateOpenJobcard";
  static String getCustomerVehicleByJobId =
      "${baseUrl}jobcard/getCustomerVehicleByJobId";
  static String postInspectionFormById =
      "${baseUrl}inspectionform/getInspectionFormById";
  static String postInspectionCategoryDetailsField =
      "${baseUrl}inspectiontask/getInspectionComponentByCategoryId";
  static String inspectionSingleSave =
      "${baseUrl}vehicleinspection/saveSingleTask";
  static String inspectionSave = "${baseUrl}vehicleinspection/save";
  static String statusChange = "${baseUrl}jobcard/updateJobCardStatus";
  static String basicInspection =
      "${baseUrl}vehicleinspection/uploadInspectionMedia";
  static String submitVehicleEssential =
      "${baseUrl}vehicleinspection/saveVehicleEssentialDetails";
  static String getBasicInspection =
      "${baseUrl}vehicleinspection/getBasicInspectionByJobId";
  static String getInspectionSummary = "${baseUrl}jobcard/getJobCardById";
  static String getInspectionDetailsById =
      "${baseUrl}vehicleinspection/getInspectionStatusByJobId";
  static String allInspectionList = "${baseUrl}jobcard/getJobCardsByUserId";
  static String shareInspectionReport = "${baseUrl}inspectionReport/share";
  static String searchVehicleRegNo =
      "${baseUrl}vehicleinspection/searchVehicleRegNo";
  static String inspectionFormSearch =
      "${baseUrl}inspectionform/inspectionFormSearch";
  static String generateInspectionPdf =
      "${baseUrl}print/generate-inspectionreport-pdf";
  static String allTechnicianList = "${baseUrl}user/technicianList";
  static String assignTechnician = "${baseUrl}jobcard/assignTechnician";

  // <-----"GET Method"------>
  static String vehicleBrand = "${baseUrl}vehicle/brands";
  static String inspectionFormList =
      "${baseUrl}inspectionform/inspectionFormList";
  static String fuelList = "${baseUrl}settings/fuelTypeList";
  static String transmissionList = "${baseUrl}settings/transmissionTypeList";
  static String customerTypeList = "${baseUrl}settings/customerTypeList";
  static String serviceTypeList = "${baseUrl}settings/serviceTypeList";
  static String getvehicleEssentialList =
      "${baseUrl}settings/vehicleEssentialList";
  static String taskCategoryList = "${baseUrl}settings/taskCategoryList";
  static String basicimageSettingList = "${baseUrl}settings/imageSettingsList";
}
