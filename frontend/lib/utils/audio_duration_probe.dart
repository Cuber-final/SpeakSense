import 'dart:typed_data';

import 'package:speaksense_app/utils/audio_duration_probe_stub.dart'
    if (dart.library.html) 'package:speaksense_app/utils/audio_duration_probe_web.dart'
    as probe_impl;

Future<Duration?> probeAudioDuration(Uint8List bytes, {String? mimeType}) {
  return probe_impl.probeAudioDuration(bytes, mimeType: mimeType);
}
