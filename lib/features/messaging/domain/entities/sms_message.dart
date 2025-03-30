class KwtSmsMessage {
  final String mobile;
  final String message;
  final String sender;
  final int languageCode;
  final bool isTest;

  /// Creates a new SMS message
  ///
  /// [mobile] Comma-separated list of phone numbers without '+' or '00'
  /// [message] The message content
  /// [sender] The sender ID (case sensitive)
  /// [languageCode] 1: English, 2: Arabic (CP1256), 3: Arabic (UTF-8), 4: Unicode
  /// [isTest] If true, message will not be sent to handsets but added to the queue
  KwtSmsMessage({
    required this.mobile,
    required this.message,
    required this.sender,
    this.languageCode = 1,
    this.isTest = false,
  });

  /// Converts the message to a map for API requests
  Map<String, dynamic> toMap() {
    return {
      'mobile': mobile,
      'message': message,
      'sender': sender,
      'lang': languageCode.toString(),
      'test': isTest ? '1' : '0',
    };
  }

  /// Formats mobile numbers by removing '+', '00', spaces and dots
  /// Returns comma-separated list of clean numbers
  static String formatMobileNumbers(List<String> numbers) {
    return numbers
        .map((number) {
          return number
              .replaceAll(RegExp(r'[\+\s\.\-]'), '')
              .replaceAll(RegExp(r'^00'), '');
        })
        .join(',');
  }
}
