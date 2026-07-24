import 'package:hive/hive.dart';
import 'package:team_workspace/features/authentication/data/models/user_model.dart';

/// Manual Hive adapter for persisted auth sessions.
class AppUserAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer.writeMap({
      'uid': obj.uid,
      'email': obj.email,
      'displayName': obj.displayName,
    });
  }
}
