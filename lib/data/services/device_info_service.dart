import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Resolves a short human-readable description of the current device, used to
/// populate the "User Device" column in the export.
class DeviceInfoService {
  final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  Future<String> describe() async {
    try {
      if (Platform.isAndroid) {
        final a = await _plugin.androidInfo;
        return '${a.manufacturer} ${a.model} • Android ${a.version.release} '
            '(SDK ${a.version.sdkInt})';
      }
      if (Platform.isIOS) {
        final i = await _plugin.iosInfo;
        return '${i.name} ${i.model} • iOS ${i.systemVersion}';
      }
    } catch (_) {
      // fall through
    }
    return 'Unknown device';
  }
}
