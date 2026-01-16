import 'package:hive/hive.dart';
part 'color_item.g.dart';

@HiveType(typeId: 11)
class ColorItem extends HiveObject {
  @HiveField(0)
  late int id;

  @HiveField(1)
  final int colorValue;

  ColorItem({
    required this.id,
    required this.colorValue,
  });
}

class ColorRepository {
  static const String itemCounterKey = 'colorItemCounter';

  late Box<ColorItem> _item;
  late Box<int> _counter;

  Future<void> init() async {
    _item = await Hive.openBox<ColorItem>('colorBox');
    _counter = await Hive.openBox<int>('colorCounterBox');
  }

  Future<int> addItem(ColorItem item) async {
    int counter = _counter.get(itemCounterKey, defaultValue: 0)!;
    counter++;
    item.id = counter;
    await _item.put(counter, item);
    await _counter.put(itemCounterKey, counter);
    return counter;
  }

  Future<void> updateItem(ColorItem item) async {
    await _item.put(item.id, item);
  }

  Future<void> deleteItem(int id) async {
    await _item.delete(id);
  }

  ColorItem? getItem(int id) {
    return _item.get(id);
  }

  List<ColorItem> getAllItems() {
    return _item.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  Future<void> clearAll() async {
    await _item.clear();
    await _counter.put(itemCounterKey, 0);
  }

  // 기본 12개 색상 초기화
  Future<void> initializeDefaultColors() async {
    final existingColors = getAllItems();
    if (existingColors.isEmpty) {
      final defaultColors = [
        0xFFE53935, // 선명한 빨강
        0xFFF44336, // 밝은 빨강
        0xFFFF5722, // 주황
        0xFFFF9800, // 오렌지
        0xFFFFC107, // 노랑
        0xFFFFEB3B, // 밝은 노랑
        0xFF4CAF50, // 초록색
        0xFF009688, // 청록색
        0xFF2196F3, // 파랑색
        0xFF3F51B5, // 남색
        0xFF673AB7, // 보라색
        0xFF9C27B0, // 자주색
      ];

      for (final colorValue in defaultColors) {
        await addItem(ColorItem(id: 0, colorValue: colorValue));
      }
    }
  }
}
