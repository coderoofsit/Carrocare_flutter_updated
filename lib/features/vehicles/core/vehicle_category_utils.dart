String normalizeVehicleCategory(String value) => value.trim().toLowerCase();

bool vehicleCategoryMatches(String vehicleCategory, String expected) {
  final normalizedExpected = normalizeVehicleCategory(expected);
  if (normalizedExpected.isEmpty) return true;
  return normalizeVehicleCategory(vehicleCategory) == normalizedExpected;
}
