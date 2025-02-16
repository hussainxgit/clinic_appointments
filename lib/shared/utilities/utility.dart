import 'package:flutter/material.dart';

extension BoAliDateTimePackage on DateTime {
  String dateOnly() {
    return ('$year-$month-$day');
  }

  String dateOnly2() {
    return ('${year}_${month}_$day');
  }

  String dateOnly3() {
    return ('$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}');
  }

  int calculateAge() {
    DateTime today = DateTime.now();
    int age = today.year - year;
    // If the birthday has not occurred yet this year, subtract one from the age
    if (today.month < month || (today.month == month && today.day < day)) {
      age--;
    }
    return age;
  }

  // Get the date of 3 months ago
  DateTime get lastThreeMonths {
    int newMonth = month - 3;
    int newYear = year;

    if (newMonth <= 0) {
      newMonth += 12;
      newYear -= 1;
    }

    return DateTime(newYear, newMonth, day);
  }

  // Get the date of 6 months ago
  DateTime get lastSixMonths {
    int newMonth = month - 6;
    int newYear = year;

    if (newMonth <= 0) {
      newMonth += 12;
      newYear -= 1;
    }

    return DateTime(newYear, newMonth, day);
  }

  bool isWithinNextWeek(DateTime today) {
    final nextWeek = today.add(Duration(days: 7));
    return isAfter(today) && isBefore(nextWeek);
  }

  bool isSameDay(DateTime date1) {
    return date1.year == year && date1.month == month && date1.day == day;
  }
}

extension BoAliStringParsing on String {
  String get firstName {
    List<String> nameParts = split(' ');
    return nameParts.isNotEmpty ? nameParts.first : '';
  }

  String get lastName {
    List<String> nameParts = split(' ');
    return nameParts.length > 1 ? nameParts.last : '';
  }

  String get capitalizeEachWord {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  DateTime? getBirthDateFromCivilID() {
    if (length != 12 || !isAllDigits()) {
      return null;
    }

    int centuryIndicator = int.parse(this[0]);
    int year = int.parse(substring(1, 3));
    int month = int.parse(substring(3, 5));
    int day = int.parse(substring(5, 7));

    if (centuryIndicator == 2) {
      year += 1900;
    } else if (centuryIndicator == 3) {
      year += 2000;
    } else {
      return null;
    }

    try {
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  bool isValidCivilID() {
    if (length != 12 || !isAllDigits()) {
      return false;
    }

    List<int> coefficients = [2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
    int checksum = int.parse(this[11]);
    int sum = 0;

    for (int i = 0; i < 11; i++) {
      sum += int.parse(this[i]) * coefficients[i];
    }

    int calculatedChecksum = 11 - (sum % 11);
    if (calculatedChecksum == 11) {
      calculatedChecksum = 0;
    }

    return calculatedChecksum == checksum;
  }

  bool isAllDigits() {
    for (int i = 0; i < length; i++) {
      if (!RegExp(r'^[0-9]+$').hasMatch(this[i])) {
        return false;
      }
    }
    return true;
  }
}

void showMessageDialog(BuildContext context, String title, String body) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
