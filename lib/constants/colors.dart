import 'package:flutter/material.dart';

// 앱 전체에서 사용할 색상 리스트 (잘 사용되는 그라데이션 색상)
List<Color> scheduleColors = [
  // 첫 번째 줄 (빨간색 계열부터 보라색 계열까지)
  const Color(0xFFE53935), // 선명한 빨강 (Google Calendar)
  const Color(0xFFF44336), // 밝은 빨강 (Material Red)
  const Color(0xFFFF5722), // 주황 (Material Deep Orange)
  const Color(0xFFFF9800), // 오렌지 (Material Orange)
  const Color(0xFFFFC107), // 노랑 (Material Amber)
  const Color(0xFFFFEB3B), // 밝은 노랑 (Material Yellow)

  // 두 번째 줄 (초록색 계열부터 파란색, 보라색 계열까지)
  const Color(0xFF4CAF50), // 초록색 (Material Green)
  const Color(0xFF009688), // 청록색 (Material Teal)
  const Color(0xFF2196F3), // 파랑색 (Material Blue)
  const Color(0xFF3F51B5), // 남색 (Material Indigo)
  const Color(0xFF673AB7), // 보라색 (Material Deep Purple)
  const Color(0xFF9C27B0), // 자주색 (Material Purple)
];

// 파스텔 톤 색상 리스트 (가시성 개선)
// List<Color> scheduleColors = [
//   // 첫 번째 줄 (빨간색 계열부터 보라색 계열까지)
//   const Color(0xFFEF9A9A), // 파스텔 빨강 (300)
//   const Color(0xFFF48FB1), // 파스텔 핑크 (300)
//   const Color(0xFFFFAB91), // 파스텔 주황 (300)
//   const Color(0xFFFFCC80), // 파스텔 오렌지 (300)
//   const Color(0xFFFFF176), // 파스텔 노랑 (300)
//   const Color(0xFFFFF59D), // 파스텔 밝은 노랑 (200)

//   // 두 번째 줄 (초록색 계열부터 파란색, 보라색 계열까지)
//   const Color(0xFFA5D6A7), // 파스텔 초록 (300)
//   const Color(0xFF80CBC4), // 파스텔 청록 (300)
//   const Color(0xFF90CAF9), // 파스텔 파랑 (300)
//   const Color(0xFF9FA8DA), // 파스텔 남색 (300)
//   const Color(0xFFB39DDB), // 파스텔 보라 (300)
//   const Color(0xFFCE93D8), // 파스텔 자주 (300)
// ];
