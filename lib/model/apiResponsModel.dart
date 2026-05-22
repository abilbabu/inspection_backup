class ApiResponse<T> {
  final int? statusCode;
  final String? timeStamp;
  final T? data;
  final String? status;
  final bool? success;

  ApiResponse({
    this.statusCode,
    this.timeStamp,
    this.data,
    this.status,
    this.success
  });}

  