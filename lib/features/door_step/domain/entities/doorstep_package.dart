class DoorstepAddOn {
  const DoorstepAddOn({
    required this.serviceType,
    required this.title,
    required this.price,
  });

  final String serviceType;
  final String title;
  final int price;

  factory DoorstepAddOn.fromJson(Map<String, dynamic> json) {
    return DoorstepAddOn(
      serviceType: (json['service_type'] ?? '').toString(),
      title: (json['service'] ?? '').toString(),
      price: int.tryParse((json['prices'] ?? '0').toString()) ?? 0,
    );
  }
}

enum DoorstepCatalogCategory {
  all,
  carWash,
  bikeWash,
  waxing,
  acVent,
}

String doorstepCategoryLabel(DoorstepCatalogCategory category) {
  switch (category) {
    case DoorstepCatalogCategory.carWash:
      return 'Car Washing';
    case DoorstepCatalogCategory.bikeWash:
      return 'Bike Wash';
    case DoorstepCatalogCategory.waxing:
      return 'Car Waxing';
    case DoorstepCatalogCategory.acVent:
      return 'AC Vent Cleaning';
    case DoorstepCatalogCategory.all:
      return 'Doorstep Service';
  }
}

DoorstepCatalogCategory doorstepCategoryFromApiKey(String value) {
  switch (value.trim().toLowerCase()) {
    case 'car_wash':
      return DoorstepCatalogCategory.carWash;
    case 'bike_wash':
      return DoorstepCatalogCategory.bikeWash;
    case 'waxing':
      return DoorstepCatalogCategory.waxing;
    case 'ac_vent':
      return DoorstepCatalogCategory.acVent;
    default:
      return DoorstepCatalogCategory.all;
  }
}

class DoorstepCategoryTab {
  const DoorstepCategoryTab({
    required this.label,
    required this.category,
    required this.imageUrl,
    required this.fallbackAsset,
  });

  final String label;
  final DoorstepCatalogCategory category;
  final String? imageUrl;
  final String fallbackAsset;
}

class DoorstepPackage {
  const DoorstepPackage({
    required this.serviceType,
    required this.name,
    required this.category,
    required this.categoryLabel,
    required this.price,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.shortDescription,
    required this.bullets,
    this.note,
    this.badge,
    this.addOns = const <DoorstepAddOn>[],
  });

  final String serviceType;
  final String name;
  final DoorstepCatalogCategory category;
  final String categoryLabel;
  final int price;
  final String? imageUrl;
  final String fallbackAsset;
  final String shortDescription;
  final List<String> bullets;
  final String? note;
  final String? badge;
  final List<DoorstepAddOn> addOns;

  factory DoorstepPackage.fromJson(Map<String, dynamic> json) {
    final categoryKey = (json['category'] ?? '').toString();
    final addOnsRaw = json['add_ons'];
    return DoorstepPackage(
      serviceType: (json['service_type'] ?? '').toString(),
      name: (json['service'] ?? '').toString(),
      category: doorstepCategoryFromApiKey(categoryKey),
      categoryLabel: (json['category_label'] ?? '').toString(),
      price: int.tryParse((json['prices'] ?? '0').toString()) ?? 0,
      imageUrl: _nullableString(json['image']),
      fallbackAsset: _fallbackAssetForServiceType(
        (json['service_type'] ?? '').toString(),
      ),
      shortDescription: (json['short_description'] ?? '').toString(),
      bullets: _parseBullets(json['bullets']),
      note: _nullableString(json['note']),
      badge: _nullableString(json['badge']),
      addOns: addOnsRaw is List
          ? addOnsRaw
              .whereType<Map<String, dynamic>>()
              .map(DoorstepAddOn.fromJson)
              .toList()
          : const <DoorstepAddOn>[],
    );
  }
}

class DoorstepPackagesResponse {
  const DoorstepPackagesResponse({
    required this.packages,
    required this.tabs,
  });

  final List<DoorstepPackage> packages;
  final List<DoorstepCategoryTab> tabs;

  factory DoorstepPackagesResponse.fromJson(Map<String, dynamic> json) {
    final packagesRaw = json['packages'];
    final categoriesRaw = json['categories'];
    final packages = packagesRaw is List
        ? packagesRaw
            .whereType<Map<String, dynamic>>()
            .map(DoorstepPackage.fromJson)
            .toList()
        : const <DoorstepPackage>[];
    final apiTabs = categoriesRaw is List
        ? categoriesRaw.whereType<Map<String, dynamic>>().map((category) {
            final key = (category['key'] ?? '').toString();
            return DoorstepCategoryTab(
              label: (category['label'] ?? '').toString(),
              category: doorstepCategoryFromApiKey(key),
              imageUrl: _nullableString(category['image']),
              fallbackAsset: _fallbackAssetForCategory(key),
            );
          }).toList()
        : const <DoorstepCategoryTab>[];
    final tabs = <DoorstepCategoryTab>[
      const DoorstepCategoryTab(
        label: 'All',
        category: DoorstepCatalogCategory.all,
        imageUrl: null,
        fallbackAsset: 'assets/images/app_icon_512.png',
      ),
      ...apiTabs,
    ];
    return DoorstepPackagesResponse(packages: packages, tabs: tabs);
  }
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

List<String> _parseBullets(dynamic value) {
  if (value is! List) return const <String>[];
  return value.map((item) => item.toString()).toList();
}

String _fallbackAssetForServiceType(String serviceType) {
  switch (serviceType) {
    case 'doorstep_bike_wash':
      return 'assets/images/bike_wash.jpg';
    case 'doorstep_car_waxing':
      return 'assets/images/wax_polish.jpg';
    case 'doorstep_ac_vent_cleaning':
      return 'assets/images/extra_interior.png';
    default:
      return 'assets/images/car_wash.jpg';
  }
}

String _fallbackAssetForCategory(String categoryKey) {
  switch (categoryKey.trim().toLowerCase()) {
    case 'bike_wash':
      return 'assets/images/bike_wash.jpg';
    case 'waxing':
      return 'assets/images/wax_polish.jpg';
    case 'ac_vent':
      return 'assets/images/extra_interior.png';
    default:
      return 'assets/images/car_wash.jpg';
  }
}
