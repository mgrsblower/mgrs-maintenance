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
  factory Component.fromMap(Map<String, Object?> json) {
    return Component({
      'id': (json['id'] ?? '').toString(),
      'code': (json['code'] ?? json['nomor_stiker'] ?? '').toString(),
      'kind': (json['kind'] ?? json['jenis_komponen'] ?? '').toString(),
      'condition': (json['condition'] ?? json['kondisi'] ?? 'OK').toString(),
      'usable': (json['usable'] ?? json['boleh_dipakai'] ?? 'Ya').toString(),
      'impairedFunction':
          (json['impairedFunction'] ?? json['fungsi_terganggu'] ?? 'Tidak Ada')
              .toString(),
      'note': (json['note'] ?? json['keterangan'])?.toString(),
      'version': (json['version'] ?? json['id'] ?? '').toString(),
      'lastCheckingAt': (json['lastCheckingAt'] ?? json['updated_at'])
          ?.toString(),
      'lastServiceAt': json['lastServiceAt']?.toString(),
    });
  }

  static Future<Component> load(MaintenanceGateway gateway, String id) async =>
      Component.fromMap(
        jsonObject(
          await gateway.rpc('maintenance_get_component', {
            'p_component_id': id,
          }),
        ),
      );
}
