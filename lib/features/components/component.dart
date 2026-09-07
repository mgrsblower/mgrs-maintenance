import '../../app/gateway.dart';

class Component {
  Component(Map<String, Object?> json)
    : id = json['id'] as String,
      code = json['code'] as String,
      kind = json['kind'] as String,
      condition = json['condition'] as String,
      usable = json['usable'] as String,
      impairedFunction = json['impairedFunction'] as String,
      note = json['note'] as String?,
      version = json['version'] as String,
      lastCheckingAt = json['lastCheckingAt'] as String?,
      lastServiceAt = json['lastServiceAt'] as String?;
  final String id, code, kind, condition, usable, impairedFunction, version;
  final String? note, lastCheckingAt, lastServiceAt;
  static Future<Component> load(MaintenanceGateway gateway, String id) async =>
      Component(
        jsonObject(
          await gateway.rpc('maintenance_get_component', {
            'p_component_id': id,
          }),
        ),
      );
}
