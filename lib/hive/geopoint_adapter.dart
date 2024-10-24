import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class GeoPointAdapter extends TypeAdapter<GeoPoint> {
  @override
  final typeId = 2;

  @override
  GeoPoint read(BinaryReader reader) {
    double latitude = reader.readDouble();
    double longitude = reader.readDouble();
    return GeoPoint(latitude, longitude);
  }

  @override
  void write(BinaryWriter writer, GeoPoint obj) {
    writer.writeDouble(obj.latitude);
    writer.writeDouble(obj.longitude);
  }
}
