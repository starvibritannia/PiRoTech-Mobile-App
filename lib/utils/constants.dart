// lib/utils/constants.dart

class AppConstants {
  // Thresholds (Batas Aman)
  static const double tempSafeMin = 20.0;
  static const double tempSafeMax = 450.0;
  static const double pressSafeMax = 300.0;
  
  // Kontrol Otomatis (Heater & Fan)
  static const double heaterAutoOff = 420.0;
  static const double heaterAutoOn = 380.0;
  static const double fanAutoOn = 400.0;

  // Konstanta Perhitungan Ekonomi & Lingkungan
  static const double fuelPricePerLiter = 6800.0;
  static const double combustionEmissionFactor = 2.9; // kg CO2 per kg plastic
  
  // Data Jenis Plastik (Kode, Nama, Min Yield, Max Yield)
  static const List<Map<String, dynamic>> plasticTypes = [
    {'id': '1', 'name': 'PET (Botol Minum)', 'minYield': 0.30, 'maxYield': 0.40},
    {'id': '2', 'name': 'HDPE (Botol Susu, Galon)', 'minYield': 0.55, 'maxYield': 0.65},
    {'id': '4', 'name': 'LDPE (Kantong Plastik)', 'minYield': 0.50, 'maxYield': 0.60},
    {'id': '5', 'name': 'PP (Tutup Botol)', 'minYield': 0.50, 'maxYield': 0.60},
    {'id': '6', 'name': 'PS (Styrofoam)', 'minYield': 0.60, 'maxYield': 0.70},
    {'id': 'mix', 'name': 'Campuran', 'minYield': 0.40, 'maxYield': 0.55},
  ];
}