import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 타임라인 뷰 모드 열거형
enum TimelineViewMode {
  day,
  week,
  month,
}

class DataProvider extends ChangeNotifier {
  // 타임라인 시작 및 종료 시간 기본값
  static const int defaultStartHour = 7;
  static const int defaultEndHour = 22;
  
  // 저장용 키
  static const String startHourKey = 'timeline_start_hour';
  static const String endHourKey = 'timeline_end_hour';
  static const String viewModeKey = 'timeline_view_mode';
  static const String selectedDateKey = 'timeline_selected_date';
  
  // 현재 값
  int _startHour = defaultStartHour;
  int _endHour = defaultEndHour;
  
  // 현재 선택된 날짜
  DateTime _selectedDate = DateTime.now();
  
  // 현재 선택된 뷰 모드
  TimelineViewMode _viewMode = TimelineViewMode.day;
  
  // Getter
  int get startHour => _startHour;
  int get endHour => _endHour;
  DateTime get selectedDate => _selectedDate;
  TimelineViewMode get viewMode => _viewMode;
  
  // 초기화 메서드
  Future<void> loadTimelineSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 저장된 값 로드 (없으면 기본값 사용)
    _startHour = prefs.getInt(startHourKey) ?? defaultStartHour;
    _endHour = prefs.getInt(endHourKey) ?? defaultEndHour;
    
    // 뷰 모드 로드
    final viewModeIndex = prefs.getInt(viewModeKey);
    if (viewModeIndex != null && viewModeIndex >= 0 && viewModeIndex < TimelineViewMode.values.length) {
      _viewMode = TimelineViewMode.values[viewModeIndex];
    }
    
    // 저장된 날짜 로드
    final savedDateMillis = prefs.getInt(selectedDateKey);
    if (savedDateMillis != null) {
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(savedDateMillis);
    }
    
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
  
  // 날짜 업데이트 (월간 및 주간 뷰에서 스와이프 시 호출)
  Future<void> updateDate(DateTime newDate) async {
    _selectedDate = newDate;
    
    // 날짜 저장 (밀리초 단위 정수로 변환하여 저장)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(selectedDateKey, newDate.millisecondsSinceEpoch);
    
    notifyListeners();
  }
  
  // 뷰 모드 설정
  Future<void> setViewMode(TimelineViewMode mode) async {
    if (_viewMode == mode) {
      return; // 이미 같은 모드이면 무시
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(viewModeKey, mode.index);
    
    _viewMode = mode;
    notifyListeners();
  }
}
