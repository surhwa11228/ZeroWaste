enum WasteCategory { cigaretteButt, generalWaste, foodWaste, others }

extension WasteCategoryCodec on WasteCategory {
  /// 서버/Firestore에서 내려온 값 → enum (관대 파싱)
  static WasteCategory fromApi(Object? value) {
    final s = (value ?? '').toString().trim().toUpperCase();
    switch (s) {
      case 'CIGARETTE_BUTT':
        return WasteCategory.cigaretteButt;
      case 'GENERAL_WASTE':
        return WasteCategory.generalWaste;
      case 'FOOD_WASTE':
        return WasteCategory.foodWaste;
      case 'OTHERS':
        return WasteCategory.others;
      default:
        // 알 수 없는 값/빈 값은 기타로 폴백 (예외 금지)
        return WasteCategory.others;
    }
  }

  /// enum → 서버/Firestore 문자열
  String get api => switch (this) {
    WasteCategory.cigaretteButt => 'CIGARETTE_BUTT',
    WasteCategory.generalWaste => 'GENERAL_WASTE',
    WasteCategory.foodWaste => 'FOOD_WASTE',
    WasteCategory.others => 'OTHERS',
  };

  /// UI 한글 라벨
  String get labelKo => switch (this) {
    WasteCategory.cigaretteButt => '담배꽁초',
    WasteCategory.generalWaste => '일반 쓰레기',
    WasteCategory.foodWaste => '음식물 쓰레기',
    WasteCategory.others => '기타',
  };
}
