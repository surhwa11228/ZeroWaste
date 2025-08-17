enum WasteCategory { cigaretteButt, generalWaste, foodWaste, others }

extension WasteCategoryCodec on WasteCategory {
  static WasteCategory fromApi(String s) {
    switch (s.toUpperCase()) {
      case 'CIGARETTE_BUTT': return WasteCategory.cigaretteButt;
      case 'GENERAL_WASTE':  return WasteCategory.generalWaste;
      case 'FOOD_WASTE':     return WasteCategory.foodWaste;
      case 'OTHERS':         return WasteCategory.others;
      default: throw StateError('Unknown wasteCategory: $s');
    }
  }
  String get api => switch (this) {
    WasteCategory.cigaretteButt => 'CIGARETTE_BUTT',
    WasteCategory.generalWaste  => 'GENERAL_WASTE',
    WasteCategory.foodWaste     => 'FOOD_WASTE',
    WasteCategory.others        => 'OTHERS',
  };
}