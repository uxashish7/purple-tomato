// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holding.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HoldingAdapter extends TypeAdapter<Holding> {
  @override
  final int typeId = 1;

  @override
  Holding read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Holding(
      id: fields[0] as String,
      stock: fields[1] as Stock,
      quantity: fields[2] as int,
      avgBuyPrice: fields[3] as double,
      purchaseDate: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Holding obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.stock)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.avgBuyPrice)
      ..writeByte(4)
      ..write(obj.purchaseDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HoldingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
