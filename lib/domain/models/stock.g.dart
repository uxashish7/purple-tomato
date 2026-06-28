// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockAdapter extends TypeAdapter<Stock> {
  @override
  final int typeId = 0;

  @override
  Stock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stock(
      instrumentKey: fields[0] as String,
      symbol: fields[1] as String,
      name: fields[2] as String,
      exchange: fields[3] as String,
      instrumentType: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Stock obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.instrumentKey)
      ..writeByte(1)
      ..write(obj.symbol)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.exchange)
      ..writeByte(4)
      ..write(obj.instrumentType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
