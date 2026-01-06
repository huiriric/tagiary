import 'package:hive/hive.dart';
import 'package:mrplando/features/routine/models/check_routine_item.dart';

/// CheckRoutineItem에 daysOfWeek 필드가 추가되어 기존 데이터를 마이그레이션하기 위한 헬퍼 클래스
class RoutineMigrationHelper {
  static Future<void> migrateCheckRoutines() async {
    final box = await Hive.openBox<CheckRoutineItem>('checkRoutineBox');

    // 모든 루틴 아이템 가져오기
    final routines = box.values.toList();

    // 마이그레이션이 필요한지 확인
    bool needsMigration = false;
    for (var routine in routines) {
      // daysOfWeek 필드가 누락된 경우(Hive에서는 null로 읽힘)
      try {
        // 필드 접근 시도 - 이 코드는 예외를 던질 수 있음
        routine.daysOfWeek;
      } catch (e) {
        needsMigration = true;
        break;
      }
    }

    if (needsMigration) {
      print('마이그레이션 시작: 체크 루틴에 요일 정보 추가');

      // 유저에게 통지하는 코드를 추가할 수 있음

      // 모든 아이템 갱신
      for (var routine in routines) {
        try {
          // daysOfWeek 필드 접근 시도
          routine.daysOfWeek;
        } catch (e) {
          // 기존 아이템 ID 저장
          final id = routine.id;

          // 새 필드가 추가된 아이템 생성
          final newRoutine = CheckRoutineItem(
            id: id,
            content: routine.content,
            startDate: routine.startDate,
            colorValue: routine.colorValue,
            check: routine.check,
            updated: routine.updated,
            daysOfWeek: List.generate(7, (index) => true), // 기본으로 모든 요일 활성화
          );

          // 박스에 업데이트
          await box.put(id, newRoutine);
        }
      }

      print('마이그레이션 완료: ${routines.length}개 루틴 업데이트됨');
    } else {
      print('마이그레이션 필요 없음: 모든 체크 루틴에 이미 요일 정보가 있음');
    }
  }
}
