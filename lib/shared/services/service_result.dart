class ServiceResult<T> {
  final T? data;
  final String? errorMessage;
  final bool isSuccess;

  ServiceResult.success(this.data) : errorMessage = null, isSuccess = true;
  ServiceResult.failure(this.errorMessage) : data = null, isSuccess = false;
}