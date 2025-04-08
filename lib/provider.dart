import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataProvider extends ChangeNotifier {
  // 타임라인 시작 및 종료 시간 기본값
  static const int defaultStartHour = 7;
  static const int defaultEndHour = 22;
  
  // 저장용 키
  static const String startHourKey = 'timeline_start_hour';
  static const String endHourKey = 'timeline_end_hour';
  
  // 현재 값
  int _startHour = defaultStartHour;
  int _endHour = defaultEndHour;
  
  // Getter
  int get startHour => _startHour;
  int get endHour => _endHour;
  
  // 초기화 메서드
  Future<void> loadTimelineSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 저장된 값 로드 (없으면 기본값 사용)
    _startHour = prefs.getInt(startHourKey) ?? defaultStartHour;
    _endHour = prefs.getInt(endHourKey) ?? defaultEndHour;
    
    notifyListeners();
  }
  
  // 시작 시간 설정
  Future<void> setStartHour(int hour) async {
    if (hour < 0 || hour > 23 || hour >= _endHour) {
      return; // 유효하지 않은 입력 무시
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(startHourKey, hour);
    
    _startHour = hour;
    notifyListeners();
  }
  
  // 종료 시간 설정
  Future<void> setEndHour(int hour) async {
    if (hour < 0 || hour > 23 || hour <= _startHour) {
      return; // 유효하지 않은 입력 무시
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(endHourKey, hour);
    
    _endHour = hour;
    notifyListeners();
  }
}
