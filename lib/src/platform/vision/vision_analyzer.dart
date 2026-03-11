abstract class VisionAnalyzer {
  String get id;
}

class BarcodeVisionAnalyzer implements VisionAnalyzer {
  const BarcodeVisionAnalyzer();

  @override
  String get id => 'barcode_qr';
}
