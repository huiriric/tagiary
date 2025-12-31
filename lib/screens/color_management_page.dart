import 'package:flutter/material.dart';
import 'package:mrplando/constants/colors.dart';
import 'package:mrplando/tables/color/color_item.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ColorManagementPage extends StatefulWidget {
  const ColorManagementPage({super.key});

  @override
  State<ColorManagementPage> createState() => _ColorManagementPageState();
}

class _ColorManagementPageState extends State<ColorManagementPage> {
  final ColorRepository _colorRepo = ColorRepository();
  ColorItem? _selectedColorItem;
  Color? _editingColor;
  double _hue = 0.0;
  double _saturation = 1.0;
  double _value = 1.0;
  bool _isEditing = false;
  double colorPadding = 20;
  double colorSize = 35;

  @override
  void initState() {
    super.initState();
    _initRepository();
  }

  Future<void> _initRepository() async {
    await _colorRepo.init();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () async {
            await refreshScheduleColors();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '색상 관리',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _addNewColor,
            tooltip: '색상 추가',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 사용 중인 색상
            const Text(
              '현재 색상',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 현재 색상 그리드 (Wrap으로 동적 처리)
            Expanded(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withAlpha(0),
                      Colors.white,
                      Colors.white,
                      Colors.white.withAlpha(0),
                    ],
                    stops: const [0.0, 0.01, 0.99, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: colorPadding, vertical: 5),
                    child: Wrap(
                      spacing: (MediaQuery.of(context).size.width - (colorPadding * 4 + colorSize * 6)) / 5,
                      runSpacing: 12,
                      children: _colorRepo.getAllItems().map((colorItem) {
                        final color = Color(colorItem.colorValue);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColorItem = colorItem;
                              _editingColor = color;
                              // HSV로 변환
                              final hsv = HSVColor.fromColor(color);
                              _hue = hsv.hue;
                              _saturation = hsv.saturation;
                              _value = hsv.value;
                              _isEditing = false;
                            });
                          },
                          onLongPress: () {
                            _showDeleteDialog(colorItem);
                          },
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: _selectedColorItem?.id == colorItem.id ? Border.all(color: Colors.black, width: 2.5) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 색상 편집 섹션
            if (_selectedColorItem != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '색상 편집',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _showDeleteDialog(_selectedColorItem!);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    label: const Text(
                      '삭제',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 선택된 색상 미리보기
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _editingColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 색상 피커
              Expanded(child: _buildColorPicker()),
            ] else
              const Expanded(
                child: Center(
                  child: Text(
                    '수정할 색상을 선택하거나\n우측 상단 + 버튼으로 색상을 추가해주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            // 저장 버튼
            if (_selectedColorItem != null && _isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveColor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF40608A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 색상환 (Hue)
          _buildSlider(
            label: '색조',
            value: _hue,
            min: 0,
            max: 360,
            activeColor: HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor(),
            onChanged: (value) {
              setState(() {
                _hue = value;
                _updateEditingColor();
              });
            },
          ),
          const SizedBox(height: 8),

          // 채도 (Saturation)
          _buildSlider(
            label: '채도',
            value: _saturation,
            min: 0,
            max: 1,
            activeColor: HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor(),
            onChanged: (value) {
              setState(() {
                _saturation = value;
                _updateEditingColor();
              });
            },
          ),
          const SizedBox(height: 8),

          // 명도 (Value)
          _buildSlider(
            label: '명도',
            value: _value,
            min: 0,
            max: 1,
            activeColor: HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor(),
            onChanged: (value) {
              setState(() {
                _value = value;
                _updateEditingColor();
              });
            },
          ),

          const SizedBox(height: 16),

          // RGB 값 표시
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRGBValue('R', _editingColor!.red),
                _buildRGBValue('G', _editingColor!.green),
                _buildRGBValue('B', _editingColor!.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 8,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: activeColor,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRGBValue(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _updateEditingColor() {
    setState(() {
      _editingColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();
      _isEditing = true;
    });
  }

  Future<void> _addNewColor() async {
    final newColor = ColorItem(
      id: 0,
      colorValue: const Color(0xFF9E9E9E).value, // 기본 회색
    );
    final newId = await _colorRepo.addItem(newColor);
    await refreshScheduleColors();

    // 새로 추가된 색상을 찾아서 선택
    final addedColorItem = _colorRepo.getItem(newId);
    if (addedColorItem != null) {
      final color = Color(addedColorItem.colorValue);
      final hsv = HSVColor.fromColor(color);

      setState(() {
        _selectedColorItem = addedColorItem;
        _editingColor = color;
        _hue = hsv.hue;
        _saturation = hsv.saturation;
        _value = hsv.value;
        _isEditing = false; // 아직 수정하지 않은 상태
      });
    }

    _showToast('색상이 추가되었습니다');
  }

  Future<void> _saveColor() async {
    if (_selectedColorItem == null || _editingColor == null) return;

    final updatedItem = ColorItem(
      id: _selectedColorItem!.id,
      colorValue: _editingColor!.value,
    );

    await _colorRepo.updateItem(updatedItem);
    await refreshScheduleColors();

    setState(() {
      _isEditing = false;
    });

    _showToast('색상이 저장되었습니다');
  }

  Future<void> _showDeleteDialog(ColorItem colorItem) async {
    // 색상이 1개만 남았을 때는 삭제 불가
    if (_colorRepo.getAllItems().length <= 1) {
      _showToast('최소 1개의 색상은 필요합니다');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('색상 삭제'),
        content: const Text('이 색상을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _colorRepo.deleteItem(colorItem.id);
      await refreshScheduleColors();
      setState(() {
        if (_selectedColorItem?.id == colorItem.id) {
          _selectedColorItem = null;
          _editingColor = null;
          _isEditing = false;
        }
      });
      _showToast('색상이 삭제되었습니다');
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }
}
