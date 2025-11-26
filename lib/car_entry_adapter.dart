import 'package:hive/hive.dart';
import 'package:max_baza/car_entryy_model.dart';

// Адаптер для Hive
class CarEntryAdapter extends TypeAdapter<CarEntry> {
  @override
  final int typeId = 0;

  @override
  CarEntry read(BinaryReader reader) {
    return CarEntry(
      carNumber: reader.readString(),
      name: reader.readString(),
      phoneNumber: reader.readString(),
      companyName: reader.readString(),
      carType: reader.readString(),
      departureDateTime: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      comment: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, CarEntry obj) {
    writer.writeString(obj.carNumber);
    writer.writeString(obj.name);
    writer.writeString(obj.phoneNumber);
    writer.writeString(obj.companyName);
    writer.writeString(obj.carType);
    writer.writeInt(obj.departureDateTime.millisecondsSinceEpoch);
    writer.writeString(obj.comment);
  }
}
