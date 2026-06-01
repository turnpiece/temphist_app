enum SelectionMethod {
  ownLocation,
  carousel,
  recent,
  popular,
  search;

  String get apiValue => switch (this) {
        SelectionMethod.ownLocation => 'own_location',
        SelectionMethod.carousel => 'carousel',
        SelectionMethod.recent => 'recent',
        SelectionMethod.popular => 'popular',
        SelectionMethod.search => 'search',
      };
}
