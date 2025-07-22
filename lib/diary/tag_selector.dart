// import 'package:flutter/material.dart';
// import 'package:tagiary/constants/colors.dart';
// import 'package:tagiary/tables/diary/tag.dart';
// import 'package:tagiary/tables/diary/tag_group.dart';
// import 'package:tagiary/tables/diary/tag_manager.dart';

// class TagSelectorPage extends StatefulWidget {
//   final TagManager tagManager;
//   final List<int> selectedTagIds;

//   const TagSelectorPage({
//     Key? key,
//     required this.tagManager,
//     required this.selectedTagIds,
//   }) : super(key: key);

//   @override
//   State<TagSelectorPage> createState() => _TagSelectorPageState();
// }

// class _TagSelectorPageState extends State<TagSelectorPage> with TickerProviderStateMixin {
//   late TabController _tabController;
//   Map<TagGroupInfo, List<Tag>> _groupedTags = {};
//   List<int> _selectedTagIds = [];
//   List<TagGroupInfo> _groups = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _selectedTagIds = List<int>.from(widget.selectedTagIds);
    
//     // 초기 TabController 생성은 비동기 로딩 후에 처리
//     _tabController = TabController(
//       length: 1, // 초기값 설정 (나중에 _loadTags에서 업데이트)
//       vsync: this,
//     );
    
//     _loadTags();
//   }

//   Future<void> _loadTags() async {
//     setState(() {
//       _isLoading = true;
//     });

//     _groupedTags = widget.tagManager.getTagsByGroup();
//     _groups = _groupedTags.keys.toList();
    
//     // 안전하게 TabController 초기화
//     try {
//       // 이미 초기화된 컨트롤러가 있다면 우선 해제
//       if (this.mounted) {
//         // 안전하게 dispose 시도
//         try {
//           _tabController.dispose();
//         } catch (e) {
//           print('TabController dispose 오류: $e');
//         }
//       }
      
//       // 새 TabController 생성
//       _tabController = TabController(
//         length: _groups.isNotEmpty ? _groups.length : 1,
//         vsync: this,
//       );
//     } catch (e) {
//       print('TabController 초기화 오류: $e');
//       // 오류 발생 시 기본값으로 설정
//       _tabController = TabController(
//         length: 1,
//         vsync: this,
//       );
//     }

//     if (mounted) {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     // TabController dispose 시도
//     try {
//       _tabController.dispose();
//     } catch (e) {
//       print('TabController dispose 오류: $e');
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('태그 선택'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context, _selectedTagIds);
//             },
//             child: const Text(
//               '완료',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//         bottom: _isLoading
//             ? null
//             : TabBar(
//                 controller: _tabController,
//                 isScrollable: true,
//                 tabs: _groups.map((group) {
//                   return Tab(
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           width: 12,
//                           height: 12,
//                           decoration: BoxDecoration(
//                             color: group.color,
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Text(group.name),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               ),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : TabBarView(
//               controller: _tabController,
//               children: _groups.map((group) {
//                 return _buildTagListForGroup(group);
//               }).toList(),
//             ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddTagDialog(context),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   Widget _buildTagListForGroup(TagGroupInfo group) {
//     final tags = _groupedTags[group] ?? [];

//     if (tags.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               '이 그룹에 태그가 없습니다',
//               style: TextStyle(color: Colors.grey[600]),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: () => _showAddTagDialog(context, initialGroupId: group.id),
//               icon: const Icon(Icons.add),
//               label: const Text('태그 추가하기'),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         Wrap(
//           spacing: 8,
//           runSpacing: 12,
//           children: tags.map((tag) {
//             final isSelected = _selectedTagIds.contains(tag.id);
//             final tagInfo = widget.tagManager.getTagInfo(tag.id);
//             final color = tagInfo?.color ?? group.color;

//             return FilterChip(
//               label: Text(
//                 tag.name,
//                 style: TextStyle(
//                   color: isSelected ? Colors.white : Colors.black,
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 ),
//               ),
//               selected: isSelected,
//               selectedColor: color,
//               backgroundColor: color.withOpacity(0.1),
//               onSelected: (selected) {
//                 setState(() {
//                   if (selected) {
//                     _selectedTagIds.add(tag.id);
//                   } else {
//                     _selectedTagIds.remove(tag.id);
//                   }
//                 });
//               },
//               checkmarkColor: Colors.white,
//             );
//           }).toList(),
//         ),
//         const SizedBox(height: 16),
//         OutlinedButton.icon(
//           onPressed: () => _showAddTagDialog(context, initialGroupId: group.id),
//           icon: const Icon(Icons.add),
//           label: const Text('새 태그 추가'),
//         ),
//       ],
//     );
//   }

//   void _showAddTagDialog(BuildContext context, {int? initialGroupId}) {
//     final TextEditingController tagNameController = TextEditingController();
//     int selectedGroupId = initialGroupId ?? (_groups.isNotEmpty ? _groups.first.id : 0);

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: const Text('새 태그 추가'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   TextField(
//                     controller: tagNameController,
//                     decoration: const InputDecoration(
//                       labelText: '태그 이름',
//                       hintText: '태그 이름을 입력하세요',
//                     ),
//                     autofocus: true,
//                   ),
//                   const SizedBox(height: 16),
//                   const Text('그룹 선택:'),
//                   const SizedBox(height: 8),
//                   DropdownButtonFormField<int>(
//                     value: selectedGroupId,
//                     decoration: const InputDecoration(
//                       border: OutlineInputBorder(),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     ),
//                     items: _groups.map((group) {
//                       return DropdownMenuItem<int>(
//                         value: group.id,
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 12,
//                               height: 12,
//                               decoration: BoxDecoration(
//                                 color: group.color,
//                                 shape: BoxShape.circle,
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Text(group.name),
//                           ],
//                         ),
//                       );
//                     }).toList(),
//                     onChanged: (value) {
//                       if (value != null) {
//                         setState(() {
//                           selectedGroupId = value;
//                         });
//                       }
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('취소'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     final tagName = tagNameController.text.trim();
//                     if (tagName.isNotEmpty) {
//                       // 다이얼로그 닫기
//                       Navigator.pop(context);
                      
//                       // 새 태그 추가
//                       final tagId = await widget.tagManager.addTag(tagName, selectedGroupId);
                      
//                       if (mounted) {
//                         // 현재 선택된 태그 목록에 추가
//                         setState(() {
//                           _selectedTagIds.add(tagId);
//                         });
                        
//                         // 태그 목록 새로고침
//                         await _loadTags();
//                       }
//                     }
//                   },
//                   child: const Text('추가'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
// }
