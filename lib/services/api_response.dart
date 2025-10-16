class ApiResponse<T> {
  T? data;
  String? error;

  ApiResponse({this.data, this.error});

  set message(String message) {
    error = message;
  }
}
