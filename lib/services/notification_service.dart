import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:tagiary/firebase_options.dart';
import 'dart:async';
import 'dart:io' show Platform;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 알림 권한 요청
  static Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('알림 권한 상태: ${settings.authorizationStatus}');
    }
  }

  // FCM 토큰 가져오기 (iOS의 경우 APNs 토큰 먼저 설정)
  static Future<String?> getToken() async {
    try {
      // iOS의 경우 APNs 토큰 먼저 설정
      if (Platform.isIOS) {
        await _getAPNsToken();
        // APNs 토큰 설정 후 잠시 대기
        await Future.delayed(const Duration(milliseconds: 500));
      }

      String? token = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('토큰 가져오기 실패: $e');
      }
      return null;
    }
  }

  // iOS APNs 토큰 가져오기
  static Future<void> _getAPNsToken() async {
    if (Platform.isIOS) {
      try {
        String? apnsToken = await _messaging.getAPNSToken();
        if (kDebugMode) {
          if (apnsToken != null) {
            print('APNs Token: $apnsToken');
          } else {
            print('APNs Token이 아직 설정되지 않았습니다. 잠시 후 다시 시도하세요.');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('APNs 토큰 가져오기 실패: $e');
        }
      }
    }
  }

  // 토큰 새로고침 리스너
  static void listenToTokenRefresh() {
    _messaging.onTokenRefresh.listen((String token) {
      if (kDebugMode) {
        print('FCM 토큰 새로고침: $token');
      }
      // 서버에 새 토큰 전송하는 로직 추가
    });

    // iOS APNs 토큰 변경 감지 (선택사항)
    if (Platform.isIOS) {
      // APNs 토큰이 변경되면 FCM 토큰도 새로 생성될 수 있음
      Timer.periodic(const Duration(minutes: 5), (timer) async {
        String? currentAPNs = await _messaging.getAPNSToken();
        if (currentAPNs != null && kDebugMode) {
          print('APNs Token 확인: $currentAPNs');
        }
      });
    }
  }

  static void setForegroundNotification() {
    _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // 포그라운드 메시지 처리
  static void handleForegroundMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('포그라운드 메시지 수신: ${message.messageId}');
        print('제목: ${message.notification?.title}');
        print('내용: ${message.notification?.body}');
      }

      // 포그라운드에서 알림 표시
      if (message.notification != null) {
        _showToast('${message.notification!.title}\n${message.notification!.body}');
      }
    });
  }

  // 알림 클릭 처리
  static void handleMessageClick() {
    // 앱이 백그라운드에서 알림 클릭으로 열릴 때
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('백그라운드에서 알림 클릭: ${message.messageId}');
      }

      // 특정 화면으로 네비게이션하는 로직 추가
      _handleNotificationNavigation(message);
    });
  }

  // 앱 종료 상태에서 알림 클릭으로 앱이 실행된 경우 확인
  static Future<void> checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      if (kDebugMode) {
        print('앱 종료 상태에서 알림 클릭으로 실행: ${initialMessage.messageId}');
      }

      // 특정 화면으로 네비게이션하는 로직 추가
      _handleNotificationNavigation(initialMessage);
    }
  }

  // 토스트 메시지 표시
  static void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFF323232),
      textColor: const Color(0xFFFFFFFF),
      fontSize: 14.0,
    );
  }

  // 알림 클릭 시 네비게이션 처리
  static void _handleNotificationNavigation(RemoteMessage message) {
    // 알림 데이터에 따라 특정 화면으로 이동
    Map<String, dynamic> data = message.data;

    if (data.containsKey('screen')) {
      String screen = data['screen'];
      if (kDebugMode) {
        print('네비게이션 대상 화면: $screen');
      }

      // TODO: 실제 네비게이션 로직 구현
      // 예: Navigator.pushNamed(context, '/todo') 등
    }
  }

  // 모든 알림 서비스 초기화
  static Future<void> initialize() async {
    // Firebase 초기화를 여기서 담당
    await _initializeFirebase();

    await requestPermission();

    // iOS의 경우 APNs 토큰 설정 대기
    if (Platform.isIOS) {
      await _waitForAPNsToken();
    }

    await getToken();
    listenToTokenRefresh();
    setForegroundNotification();
    handleForegroundMessage();
    handleMessageClick();
    await checkInitialMessage();
  }

  // Firebase 안전 초기화
  static Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        if (kDebugMode) {
          print('Firebase 초기화 완료');
        }

        // Firebase 초기화 후 백그라운드 핸들러 등록
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      } else {
        if (kDebugMode) {
          print('Firebase 이미 초기화됨');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase 초기화 오류: $e');
      }
    }
  }

  // iOS APNs 토큰이 설정될 때까지 대기
  static Future<void> _waitForAPNsToken() async {
    if (Platform.isIOS) {
      int attempts = 0;
      const maxAttempts = 10;

      while (attempts < maxAttempts) {
        String? apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) {
          if (kDebugMode) {
            print('APNs Token 설정 완료: $apnsToken');
          }
          break;
        }

        if (kDebugMode) {
          print('APNs Token 대기 중... (${attempts + 1}/$maxAttempts)');
        }

        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (attempts >= maxAttempts) {
        if (kDebugMode) {
          print('APNs Token 설정 타임아웃. FCM 토큰 생성에 문제가 있을 수 있습니다.');
        }
      }
    }
  }

  // iOS 전용: 토큰 상태 디버깅
  Future<void> debugTokenStatus() async {
    if (Platform.isIOS && kDebugMode) {
      print('=== iOS 토큰 상태 디버깅 ===');

      // APNs 토큰 확인
      String? apnsToken = await _messaging.getAPNSToken();
      print('APNs Token: ${apnsToken ?? "없음"}');

      // FCM 토큰 확인
      String? fcmToken = await _messaging.getToken();
      print('FCM Token: ${fcmToken ?? "없음"}');

      // 알림 권한 상태 확인
      NotificationSettings settings = await _messaging.getNotificationSettings();
      print('알림 권한: ${settings.authorizationStatus}');
      print('배지 권한: ${settings.badge}');
      print('소리 권한: ${settings.sound}');
      print('알림 권한: ${settings.alert}');

      print('=== 디버깅 완료 ===');
    }
  }

  // 수동으로 토큰 새로고침 시도
  Future<String?> refreshToken() async {
    try {
      if (Platform.isIOS) {
        // iOS에서는 APNs 토큰을 다시 확인
        await _getAPNsToken();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // FCM 토큰 삭제 후 재생성
      await _messaging.deleteToken();
      await Future.delayed(const Duration(milliseconds: 500));

      String? newToken = await _messaging.getToken();
      if (kDebugMode) {
        print('새로운 FCM 토큰: $newToken');
      }
      return newToken;
    } catch (e) {
      if (kDebugMode) {
        print('토큰 새로고침 실패: $e');
      }
      return null;
    }
  }
}

// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드에서 메시지를 받았을 때 처리
  print("백그라운드 메시지 처리 : ${message.messageId}");

  // 필요한 경우 로컬 데이터베이스에 저장하거나 다른 처리
}
