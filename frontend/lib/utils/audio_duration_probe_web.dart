// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Duration?> probeAudioDuration(
  Uint8List bytes, {
  String? mimeType,
}) async {
  final html.Blob blob = html.Blob(<Object>[bytes], mimeType ?? 'audio/*');
  final String objectUrl = html.Url.createObjectUrlFromBlob(blob);
  final html.AudioElement audio = html.AudioElement()..src = objectUrl;

  final Completer<Duration?> completer = Completer<Duration?>();
  StreamSubscription<html.Event>? loadedSub;
  StreamSubscription<html.Event>? errorSub;

  void finish(Duration? duration) {
    if (!completer.isCompleted) {
      completer.complete(duration);
    }
  }

  loadedSub = audio.onLoadedMetadata.listen((_) {
    final num seconds = audio.duration;
    if (seconds.isNaN || seconds.isInfinite || seconds <= 0) {
      finish(null);
      return;
    }
    finish(Duration(milliseconds: (seconds.toDouble() * 1000).round()));
  });

  errorSub = audio.onError.listen((_) => finish(null));

  final Duration? duration = await completer.future.timeout(
    const Duration(seconds: 4),
    onTimeout: () => null,
  );

  await loadedSub.cancel();
  await errorSub.cancel();
  audio.removeAttribute('src');
  audio.load();
  html.Url.revokeObjectUrl(objectUrl);
  return duration;
}
