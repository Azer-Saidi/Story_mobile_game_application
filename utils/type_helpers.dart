import 'package:cloud_firestore/cloud_firestore.dart';

class TypeHelpers {
  /// Converts various timestamp formats to DateTime
  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is Timestamp) return value.toDate();

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing DateTime from string: $value');
        return null;
      }
    }

    print('Unknown DateTime type: ${value.runtimeType}');
    return null;
  }

  /// Converts various timestamp formats to Firestore Timestamp
  static Timestamp? toTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value;

    if (value is DateTime) return Timestamp.fromDate(value);

    if (value is int) {
      return Timestamp.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      try {
        final dateTime = DateTime.parse(value);
        return Timestamp.fromDate(dateTime);
      } catch (e) {
        print('Error parsing Timestamp from string: $value');
        return null;
      }
    }

    print('Unknown Timestamp type: ${value.runtimeType}');
    return null;
  }

  /// Safely converts to int
  static int? toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is double) return value.toInt();

    if (value is num) return value.toInt();

    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        try {
          return double.parse(value).toInt();
        } catch (e2) {
          print('Error parsing int from string: $value');
          return null;
        }
      }
    }

    print('Unknown int type: ${value.runtimeType}');
    return null;
  }

  /// Safely converts to double
  static double? toDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    if (value is num) return value.toDouble();

    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing double from string: $value');
        return null;
      }
    }

    print('Unknown double type: ${value.runtimeType}');
    return null;
  }

  /// Safely converts to string
  static String asString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;

    if (value is String) return value;

    return value.toString();
  }

  /// Safely converts to bool
  static bool toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;

    if (value is bool) return value;

    if (value is int) return value != 0;

    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }

    return defaultValue;
  }

  /// Safely converts to List<String>
  static List<String> toStringList(dynamic value) {
    if (value == null) return [];

    if (value is List<String>) return value;

    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    if (value is String) {
      try {
        // Try to parse as JSON array
        return [value]; // For now, just wrap single string
      } catch (e) {
        return [value];
      }
    }

    return [];
  }

  /// Safely converts to Map<String, dynamic>
  static Map<String, dynamic> toMap(dynamic value) {
    if (value == null) return {};

    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  /// Safely converts to Map<String, int>
  static Map<String, int> toIntMap(dynamic value) {
    if (value == null) return {};

    if (value is Map<String, int>) return value;

    if (value is Map) {
      final result = <String, int>{};
      value.forEach((key, val) {
        final intVal = toInt(val);
        if (intVal != null) {
          result[key.toString()] = intVal;
        }
      });
      return result;
    }

    return {};
  }

  /// Safely converts to Map<String, String>
  static Map<String, String> toStringMap(dynamic value) {
    if (value == null) return {};

    if (value is Map<String, String>) return value;

    if (value is Map) {
      final result = <String, String>{};
      value.forEach((key, val) {
        result[key.toString()] = val.toString();
      });
      return result;
    }

    return {};
  }
}
