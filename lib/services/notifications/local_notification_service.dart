import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/svg_paths.dart';
import '../../core/router/app_router.dart';
import '../../data/models/notification_model.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'krivana_high_priority',
    'Krivana Alerts',
    description: 'Project, deployment, and assistant notifications.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Uint8List? _cachedLogoBytes;
  String? _pendingRoute;
  bool _initialized = false;
  static const _notificationRoute = '/notifications';

  Future<void> initialize() async {
    if (_initialized) return;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _pendingRoute =
          launchDetails?.notificationResponse?.payload ?? _notificationRoute;
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification_logo'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showNotification(AppNotification notification) async {
    await initialize();

    final logoBytes = await _loadLogoBytes();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        color: const ui.Color(0xFF7C3AED),
        icon: '@drawable/ic_notification_logo',
        largeIcon: logoBytes == null ? null : ByteArrayAndroidBitmap(logoBytes),
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        ticker: notification.title,
        styleInformation: BigTextStyleInformation(
          notification.body,
          contentTitle: notification.title,
          summaryText: AppConstants.appName,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      ),
    );

    await _plugin.show(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: _notificationRoute,
    );
  }

  void flushPendingNavigation() {
    final route = _pendingRoute;
    final context = rootNavigatorKey.currentContext;
    if (route == null || context == null) return;

    _pendingRoute = null;
    GoRouter.of(context).push(route);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    _pendingRoute = response.payload ?? _notificationRoute;
    flushPendingNavigation();
  }

  Future<Uint8List?> _loadLogoBytes() async {
    if (_cachedLogoBytes != null) return _cachedLogoBytes;

    try {
      final pictureInfo = await svg.vg.loadPicture(
        const svg.SvgAssetLoader(SvgPaths.krivanaIcon),
        null,
      );
      final image = await pictureInfo.picture.toImage(192, 192);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      pictureInfo.picture.dispose();
      _cachedLogoBytes = byteData?.buffer.asUint8List();
      return _cachedLogoBytes;
    } on FlutterError {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
