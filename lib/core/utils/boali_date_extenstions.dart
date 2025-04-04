extension BoaliDateExtensions on DateTime {
  String get formattedDate {
    return "${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year";
  }

  String get formattedTime {
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }

  isPastDate() {
    return isBefore(DateTime.now());
  }

  isSameDate(DateTime date) {
    return year == date.year && month == date.month && day == date.day;
  }
}
