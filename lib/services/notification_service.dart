import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n/app_strings.dart';
import 'update_service.dart';

class NotificationService {
  static const MethodChannel _channel =
      MethodChannel('com.loancalc.loan_calc/notifications');
  static const String prefLastNotifiedVersionKey = 'last_notified_update_tag';

  static void Function(String route)? _onNotificationSelected;

  /// Initialize notification listener and check if app was opened via notification tap
  static Future<void> init({required void Function(String route) onRouteSelected}) async {
    _onNotificationSelected = onRouteSelected;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationClicked') {
        final route = call.arguments as String?;
        if (route != null && _onNotificationSelected != null) {
          _onNotificationSelected!(route);
        }
      }
    });

    try {
      final initialRoute = await _channel.invokeMethod<String>('getInitialRoute');
      if (initialRoute != null && initialRoute.isNotEmpty) {
        // Small delay to allow widget tree to settle before navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_onNotificationSelected != null) {
            _onNotificationSelected!(initialRoute);
          }
        });
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Request notification permission on Android 13+ (POST_NOTIFICATIONS)
  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  /// Trigger an Android system push notification
  static Future<void> showUpdateNotification({
    required String title,
    required String body,
    String route = 'updater',
  }) async {
    try {
      await _channel.invokeMethod('showUpdateNotification', {
        'title': title,
        'body': body,
        'route': route,
      });
    } catch (e) {
      debugPrint('Error showing update notification: $e');
    }
  }

  /// Check GitHub releases for update and send a push notification if found.
  /// If [forceNotify] is false, only notify once per version tag to avoid spam.
  static Future<UpdateReleaseInfo?> checkForUpdateAndNotify({
    required String lang,
    bool forceNotify = false,
  }) async {
    try {
      final info = await UpdateService.checkForUpdate();
      if (info == null) return null;

      final prefs = await SharedPreferences.getInstance();
      final lastNotified = prefs.getString(prefLastNotifiedVersionKey);

      if (forceNotify || lastNotified != info.versionTag) {
        final title = '${AppStrings.tr('updateNotificationTitle', lang)} (${info.versionTag})';
        final body = AppStrings.tr('updateNotificationBody', lang);

        await showUpdateNotification(
          title: title,
          body: body,
          route: 'updater',
        );

        await prefs.setString(prefLastNotifiedVersionKey, info.versionTag);
      }

      return info;
    } catch (e) {
      debugPrint('Error checking update and notifying: $e');
      return null;
    }
  }

  /// Checks whether notifications are enabled in Android system settings
  static Future<bool> areNotificationsEnabled() async {
    try {
      final bool? enabled = await _channel.invokeMethod<bool>('areNotificationsEnabled');
      return enabled ?? true;
    } catch (e) {
      debugPrint('Error checking if notifications are enabled: $e');
      return true;
    }
  }

  /// Opens the Android system notification settings page for this app
  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('Error opening notification settings: $e');
    }
  }

  /// Dispatches an immediate test notification with sound and vibration
  static Future<void> sendTestNotification({required String lang}) async {
    try {
      final title = lang == 'bm' ? '🔔 Notifikasi Ujian LoanCalc' : '🔔 LoanCalc Test Notification';
      final body = lang == 'bm'
          ? 'Hebat! Notifikasi kemas kini sedia berfungsi dengan baik di peranti anda.'
          : 'Great! Update notifications are functioning properly on your device.';
      await _channel.invokeMethod('sendTestNotification', {
        'title': title,
        'body': body,
      });
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  /// Schedules periodic background update check with Android WorkManager
  static Future<void> scheduleBackgroundWorker({int intervalHours = 4}) async {
    try {
      await _channel.invokeMethod('scheduleBackgroundWorker', {
        'intervalHours': intervalHours,
      });
    } catch (e) {
      debugPrint('Error scheduling background worker: $e');
    }
  }

  /// Cancels background worker
  static Future<void> cancelBackgroundWorker() async {
    try {
      await _channel.invokeMethod('cancelBackgroundWorker');
    } catch (e) {
      debugPrint('Error canceling background worker: $e');
    }
  }
}
