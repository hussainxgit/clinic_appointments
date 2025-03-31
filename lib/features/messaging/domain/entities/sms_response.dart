class KwtSmsResponse {
  final bool isSuccess;
  final String? messageId;
  final int? numbersProcessed;
  final int? pointsCharged;
  final int? balanceAfter;
  final int? timestamp;
  final String? errorMessage;

  KwtSmsResponse({
    required this.isSuccess,
    this.messageId,
    this.numbersProcessed,
    this.pointsCharged,
    this.balanceAfter,
    this.timestamp,
    this.errorMessage,
  });

  // In the KwtSmsResponse class
  factory KwtSmsResponse.fromMap(Map<String, dynamic> map) {
    final isSuccess = map['result'] == 'OK';

    return KwtSmsResponse(
      isSuccess: isSuccess,
      messageId: map['msg-id'],
      numbersProcessed: map['numbers'],
      pointsCharged: map['pointscharged'],
      balanceAfter: map['balance-after'],
      timestamp: map['unix-timestamp'],
      errorMessage: isSuccess ? null : map['error'],
    );
  }

  factory KwtSmsResponse.error(String message) {
    return KwtSmsResponse(isSuccess: false, errorMessage: message);
  }
}
