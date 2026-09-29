class ShopConstants {
  static const List<String> supportedCities = <String>[
    'Pune',
    'Kolhapur',
    'Satara',
    'Sangli',
    'Karad',
    'Navi Mumbai',
    'Mumbai',
    'Thane',
    'Patan',
    'Ishwarpur',
  ];

  static const List<String> shopTypes = <String>[
    'salon',
    'parlour',
    'unisexsalon',
  ];

  static String? canonicalCity(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final city in supportedCities) {
      if (city.toLowerCase() == normalized) return city;
    }
    return null;
  }
}
