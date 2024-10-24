import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimestampAdapter extends TypeAdapter<Timestamp> {
  @override
  final typeId = 1;

  @override
  Timestamp read(BinaryReader reader) {
    int milliseconds = reader.readInt();
    return Timestamp.fromMillisecondsSinceEpoch(milliseconds);
  }

  @override
  void write(BinaryWriter writer, Timestamp obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}
