// class VehicleModel {
//   final String id;
//   final String regNo;
//   final String make;
//   final String model;
//   final String modelYear;
//   final String engineNo;
//   final String vinNo;
//   final String fuelType;
//   final String transmissionType;
//   final String serviceType;

//   VehicleModel({
//     required this.id,
//     required this.regNo,
//     required this.make,
//     required this.model,
//     required this.modelYear,
//     required this.engineNo,
//     required this.vinNo,
//     required this.fuelType,
//     required this.transmissionType,
//     required this.serviceType,
//   });

//   factory VehicleModel.fromJson(Map<String, dynamic> json) {
//     return VehicleModel(
//       id: json["vehicleId"].toString(),
//       regNo: json["regNo"] ?? "",
//       make: json["make"] ?? "",
//       model: json["model"] ?? "",
//       modelYear: json["modelYear"] ?? "",
//       engineNo: json["engineNo"] ?? "",
//       vinNo: json["vVinNo"] ?? "",
//       fuelType: json["vFuelTypeId"] ?? "",
//       transmissionType: json["vTransmissionTypeId"] ?? "",
//       serviceType: json["vTypeId"] ?? "",
//     );
//   }
// }
