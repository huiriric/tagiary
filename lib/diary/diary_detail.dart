// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:tagiary/diary/diary_editor.dart';
// import 'package:tagiary/tables/diary/diary_item.dart';
// import 'package:tagiary/tables/diary/tag_manager.dart';

// class DiaryDetailPage extends StatefulWidget {
//   final DiaryItem diary;
//   final TagManager tagManager;
//   final VoidCallback onEdit;
//   final VoidCallback onDelete;

//   const DiaryDetailPage({
//     super.key,
//     required this.diary,
//     required this.tagManager,
//     required this.onEdit,
//     required this.onDelete,
//   });

//   @override
//   State<DiaryDetailPage> createState() => _DiaryDetailPageState();
// }

// class _DiaryDetailPageState extends State<DiaryDetailPage> {
//   late DiaryItem _diary;

//   @override
//   void initState() {
//     super.initState();
//     _diary = widget.diary;
//   }

//   @override
//   Widget build(BuildContext context) {
//     // 카테고리 정보 가져오기
//     CategoryInfo? categoryInfo;
//     if (_diary.categoryId != null) {
//       final allCategories = widget.tagManager.getAllCategories();
//       categoryInfo = allCategories.firstWhere(
//         (group) => group.id == _diary.categoryId,
//         orElse: () => allCategories.first,
//       );
//     }

//     // 태그 정보 가져오기
//     final tagInfos = widget.tagManager.getTagInfoList(_diary.tagIds);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('다이어리'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit),
//             tooltip: '수정하기',
//             onPressed: () => _editDiary(context),
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete),
//             tooltip: '삭제하기',
//             onPressed: () => _confirmDelete(context),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 날짜 및 시간
//             Card(
//               elevation: 0,
//               color: Colors.grey[100],
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.calendar_today, size: 20),
//                     const SizedBox(width: 8),
//                     Text(
//                       '${_diary.date.year}년 ${_diary.date.month}월 ${_diary.date.day}일',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),

//             Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 // 카테고리 표시 (왼쪽)
//                 if (categoryInfo != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 2.0, right: 8.0),
//                     child: ChoiceChip(
//                       showCheckmark: false,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(50),
//                       ),
//                       label: Text(
//                         categoryInfo.name,
//                         // textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                         ),
//                       ),
//                       selected: true,
//                       selectedColor: categoryInfo.color,
//                       padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0),
//                       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                       visualDensity: VisualDensity.compact,
//                       onSelected: (_) {}, // 선택 변경 불가
//                     ),
//                   ),

//                 // 제목 (오른쪽)
//                 // Expanded(
//                 //   child: Text(
//                 //     _diary.title,
//                 //     style: const TextStyle(
//                 //       fontSize: 17,
//                 //       fontWeight: FontWeight.bold,
//                 //     ),
//                 //   ),
//                 // ),
//               ],
//             ),
//             // const Divider(height: 32),
//             // const SizedBox(height: 8),

//             // 태그 표시
//             if (tagInfos.isNotEmpty) ...[
//               const Text(
//                 '태그',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: tagInfos.map((tag) {
//                   return Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(color: Colors.grey[300]!),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           tag.name,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 24),
//             ],

//             // 내용
//             const Text(
//               '내용',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Text(
//                 _diary.content,
//                 style: const TextStyle(
//                   fontSize: 15,
//                   height: 1.5,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 32),
//           ],
//         ),
//       ),
//     );
//   }

//   void _editDiary(BuildContext context) async {
//     // 다이어리 에디터 페이지를 MaterialPageRoute로 직접 생성
//     final editRoute = MaterialPageRoute<DiaryItem>(
//       builder: (context) => DiaryEditorPage(
//         diary: _diary,
//         date: _diary.date,
//         tagManager: widget.tagManager,
//         isEdit: true,
//         onSave: (updatedDiary) async {
//           // 다이어리 저장 로직
//           final repo = DiaryRepository();
//           await repo.init();
//           await repo.updateDiary(updatedDiary);

//           // 변경 내용 반영 (상위 위젯에 알림)
//           widget.onEdit();
//         },
//       ),
//     );

//     // 에디터 페이지로 이동하고 결과를 기다림
//     final result = await Navigator.push<DiaryItem>(context, editRoute);

//     // 수정된 다이어리가 있으면 상태 업데이트
//     if (result != null && mounted) {
//       setState(() {
//         _diary = result;
//       });
//     }
//   }

//   void _confirmDelete(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('다이어리 삭제'),
//         content: const Text('이 다이어리를 삭제하시겠습니까?\n삭제한 데이터는 복구할 수 없습니다.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('취소'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context); // 다이얼로그 닫기
//               widget.onDelete(); // 삭제 콜백 호출
//               Navigator.pop(context); // 상세 화면 닫기
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('삭제'),
//           ),
//         ],
//       ),
//     );
//   }
// }
