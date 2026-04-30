import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BankNotificationEvent {
  const BankNotificationEvent({
    required this.packageName,
    required this.title,
    required this.text,
    required this.subText,
    required this.postTime,
  });

  final String packageName;
  final String title;
  final String text;
  final String subText;
  final DateTime postTime;

  factory BankNotificationEvent.fromMap(Map<dynamic, dynamic> map) {
    final millis =
        map['postTime'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    return BankNotificationEvent(
      packageName: map['packageName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      subText: map['subText'] as String? ?? '',
      postTime: DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }
}

class BankNotificationsPlatformService {
  static const _methodChannel = MethodChannel(
    'finansmart/bank_notifications/methods',
  );
  static const _eventChannel = EventChannel(
    'finansmart/bank_notifications/events',
  );

  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Stream<BankNotificationEvent> get events {
    if (!isAndroid) {
      return const Stream.empty();
    }
    return _eventChannel.receiveBroadcastStream().map((event) {
      return BankNotificationEvent.fromMap(event as Map<dynamic, dynamic>);
    });
  }

  Future<bool> isNotificationListenerEnabled() async {
    if (!isAndroid) {
      return false;
    }
    return await _methodChannel.invokeMethod<bool>(
          'isNotificationListenerEnabled',
        ) ??
        false;
  }

  Future<void> openNotificationListenerSettings() async {
    if (!isAndroid) {
      return;
    }
    await _methodChannel.invokeMethod<void>('openNotificationListenerSettings');
  }
}
