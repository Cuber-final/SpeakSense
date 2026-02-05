import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speaksense_app/services/api_service.dart';
import 'package:speaksense_app/utils/audio_duration_probe.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({
    required this.useMockApi,
    required this.onExit,
    required this.onSubmit,
    super.key,
  });

  final bool useMockApi;
  final VoidCallback onExit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool desktop = MediaQuery.of(context).size.width >= 1024;

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.8),
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  'Course: Cafe Interactions',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onExit,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('退出会话'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                const _ProgressHeader(),
                const SizedBox(height: 18),
                if (desktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Expanded(flex: 5, child: _PracticeLeftColumn()),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 7,
                        child: _PracticeInputArea(useMockApi: useMockApi),
                      ),
                    ],
                  )
                else
                  Column(
                    children: <Widget>[
                      const _PracticeLeftColumn(),
                      const SizedBox(height: 16),
                      _PracticeInputArea(useMockApi: useMockApi),
                    ],
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onSubmit,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Submit Answer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Question 1 / 10',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '10% Complete',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const LinearProgressIndicator(value: 0.1),
      ],
    );
  }
}

class _PracticeLeftColumn extends StatelessWidget {
  const _PracticeLeftColumn();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Prompts',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '"What would you like to drink today?"',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Respond politely to the barista's question.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 160,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF334155), Color(0xFF111827)],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Busy Downtown Cafe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    Text(
                      'Roleplay: You are a customer at 8:30 AM. Keep your answer concise but polite.',
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        Chip(label: Text('Speed: Fast')),
                        Chip(label: Text('Tone: Polite')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PracticeInputArea extends StatefulWidget {
  const _PracticeInputArea({required this.useMockApi});

  final bool useMockApi;

  @override
  State<_PracticeInputArea> createState() => _PracticeInputAreaState();
}

class _PracticeInputAreaState extends State<_PracticeInputArea> {
  static const int _maxAudioBytes = 10 * 1024 * 1024;
  static const Duration _maxAudioDuration = Duration(seconds: 90);
  static const List<String> _allowedExtensions = <String>[
    'mp3',
    'wav',
    'm4a',
    'aac',
    'webm',
    'ogg',
  ];

  late final TextEditingController _answerController;
  late final TextEditingController _asrController;
  bool _isUploading = false;
  bool _isMockRecording = false;
  bool _isMockRecognizing = false;
  double _uploadProgress = 0;
  double _mockRecordingSeconds = 0;
  String? _pickedFileName;
  Duration? _pickedDuration;
  String? _notice;
  String? _error;
  CancelToken? _cancelToken;
  Uint8List? _lastAudioBytes;
  String? _lastAudioFileName;
  Timer? _mockRecordingTimer;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController(
      text: 'I would like a small latte, please.',
    );
    _asrController = TextEditingController();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    _mockRecordingTimer?.cancel();
    _answerController.dispose();
    _asrController.dispose();
    super.dispose();
  }

  int get _wordCount {
    final String trimmed = _answerController.text.trim();
    if (trimmed.isEmpty) {
      return 0;
    }
    return trimmed.split(RegExp(r'\s+')).length;
  }

  bool get _isBusy => _isUploading || _isMockRecognizing;

  void _toggleMockRecording() {
    if (_isBusy) {
      return;
    }

    if (_isMockRecording) {
      _finishMockRecording();
      return;
    }

    setState(() {
      _isMockRecording = true;
      _mockRecordingSeconds = 0;
      _uploadProgress = 0;
      _error = null;
      _notice = '模拟录音中...再次点击可结束。';
    });

    _mockRecordingTimer?.cancel();
    _mockRecordingTimer = Timer.periodic(const Duration(milliseconds: 200), (
      Timer timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _mockRecordingSeconds += 0.2;
      });

      if (_mockRecordingSeconds >= 5.0) {
        _finishMockRecording();
      }
    });
  }

  Future<void> _finishMockRecording() async {
    _mockRecordingTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _isMockRecording = false;
      _isMockRecognizing = true;
      _error = null;
      _notice = '模拟识别中...';
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }

    final int spokenSeconds = _mockRecordingSeconds.ceil();
    final String transcript =
        '[Mock Voice] Good morning! I would like a small oat milk latte, please.'
        ' (${spokenSeconds}s speech)';

    setState(() {
      _isMockRecognizing = false;
      _asrController.text = transcript;
      _notice = '模拟语音识别完成，可编辑后应用到答案。';
    });
  }

  Future<void> _pickAndUploadAudio() async {
    if (_isMockRecording) {
      setState(() {
        _error = '请先结束模拟录音，再执行文件上传。';
      });
      return;
    }
    if (_isMockRecognizing) {
      return;
    }

    setState(() {
      _error = null;
      _notice = null;
      _uploadProgress = 0;
    });

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: true,
    );
    if (result == null) {
      return;
    }

    final PlatformFile file = result.files.single;
    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      setState(() {
        _error = '未读取到音频文件数据，请更换文件重试。';
      });
      return;
    }

    final String extension = _extractExtension(file.name);
    if (!_allowedExtensions.contains(extension)) {
      setState(() {
        _error = '不支持的音频格式：.$extension。';
      });
      return;
    }
    if (bytes.lengthInBytes > _maxAudioBytes) {
      final double sizeMb = bytes.lengthInBytes / (1024 * 1024);
      setState(() {
        _error = '音频过大（${sizeMb.toStringAsFixed(2)}MB），请控制在 10MB 内。';
      });
      return;
    }

    final Duration? duration = await probeAudioDuration(
      bytes,
      mimeType: _guessMimeType(extension),
    );
    if (duration != null && duration > _maxAudioDuration) {
      setState(() {
        _error = '音频时长 ${_formatDuration(duration)}，超过 90 秒限制。';
      });
      return;
    }

    setState(() {
      _pickedFileName = file.name;
      _pickedDuration = duration;
      _lastAudioBytes = bytes;
      _lastAudioFileName = file.name;
      _isUploading = true;
      _error = null;
      _notice = null;
      _uploadProgress = 0;
    });
    _cancelToken = CancelToken();

    await _uploadAudioBytes(
      fileName: file.name,
      bytes: bytes,
      duration: duration,
    );
  }

  Future<void> _retryUpload() async {
    if (_lastAudioBytes == null || _lastAudioFileName == null) {
      return;
    }
    await _uploadAudioBytes(
      fileName: _lastAudioFileName!,
      bytes: _lastAudioBytes!,
      duration: _pickedDuration,
    );
  }

  Future<void> _uploadAudioBytes({
    required String fileName,
    required Uint8List bytes,
    Duration? duration,
  }) async {
    final ApiService? apiService = widget.useMockApi
        ? null
        : context.read<ApiService>();

    setState(() {
      _isUploading = true;
      _isMockRecognizing = false;
      _error = null;
      _notice = null;
      _uploadProgress = 0;
    });
    _cancelToken?.cancel('replaced');
    _cancelToken = CancelToken();

    try {
      String transcript;
      if (widget.useMockApi) {
        for (int i = 1; i <= 5; i += 1) {
          await Future<void>.delayed(const Duration(milliseconds: 120));
          if (!mounted) {
            return;
          }
          setState(() {
            _uploadProgress = i * 20;
          });
        }
        transcript =
            '[Mock ASR] I would like a small oat milk latte, please. (source: $fileName)';
      } else {
        final VoiceAnswerResponse response = await apiService!
            .uploadVoiceAnswer(
              audioBytes: bytes,
              fileName: fileName,
              cancelToken: _cancelToken,
              onSendProgress: (int sent, int total) {
                if (!mounted || total <= 0) {
                  return;
                }
                setState(() {
                  _uploadProgress = (sent / total * 100).clamp(0, 100);
                });
              },
            );
        transcript = response.transcript;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _uploadProgress = 100;
        _asrController.text = transcript.isEmpty
            ? 'ASR 未返回可编辑文本，请手动输入。'
            : transcript;
        _notice = widget.useMockApi
            ? 'Mock ASR 已生成预览，可直接编辑。'
            : '语音上传成功，已生成 ASR 预览。'
                  '${duration == null ? '（未读取本地时长，已交由后端做 90 秒校验）' : ''}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (error is ApiRequestException) {
          final String extra = error.code == null ? '' : ' [${error.code}]';
          _error = '${error.message}$extra';
        } else {
          _error = '语音上传失败：$error';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _cancelToken = null;
        });
      }
    }
  }

  void _cancelUpload() {
    _cancelToken?.cancel('manual cancel');
  }

  void _applyTranscriptToAnswer() {
    final String transcript = _asrController.text.trim();
    if (transcript.isEmpty) {
      return;
    }
    setState(() {
      _answerController.text = transcript;
      _notice = '已将 ASR 预览应用到答案输入框。';
      _error = null;
    });
  }

  String _extractExtension(String fileName) {
    final List<String> parts = fileName.toLowerCase().split('.');
    if (parts.length < 2) {
      return '';
    }
    return parts.last.trim();
  }

  String _guessMimeType(String extension) {
    return switch (extension) {
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'webm' => 'audio/webm',
      'ogg' => 'audio/ogg',
      _ => 'audio/*',
    };
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int count = _wordCount;
    final bool overLimit = count > 40;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Voice Mode Active',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.useMockApi ? 'Mock ASR' : 'Live ASR',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _answerController,
              maxLines: 8,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Start speaking or type your answer...',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 120,
                  height: 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List<Widget>.generate(14, (int i) {
                      final double factor = (i % 5 + 1) / 5;
                      return Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 4,
                            height: 8 + (24 * factor),
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: i == 9
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: overLimit
                        ? Colors.red.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$count / 40 words',
                    style: TextStyle(
                      color: overLimit ? Colors.red : theme.hintColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ASR 预览编辑',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _pickedFileName == null
                        ? '请选择音频文件并上传，后端返回文本后可编辑。'
                        : '当前文件: $_pickedFileName'
                              '${_pickedDuration == null ? '' : ' · 时长 ${_formatDuration(_pickedDuration!)}'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _asrController,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'ASR transcript preview will appear here...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _isUploading || _isMockRecognizing
                            ? null
                            : _toggleMockRecording,
                        icon: Icon(
                          _isMockRecording
                              ? Icons.stop_circle_rounded
                              : Icons.mic_rounded,
                        ),
                        label: Text(_isMockRecording ? '结束模拟录音' : '点击说话（Mock）'),
                      ),
                      FilledButton.icon(
                        onPressed: _isBusy || _isMockRecording
                            ? null
                            : _pickAndUploadAudio,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file_rounded),
                        label: Text(_isUploading ? '上传中...' : '选择并上传音频'),
                      ),
                      if (_isUploading)
                        OutlinedButton.icon(
                          onPressed: _cancelUpload,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('取消上传'),
                        ),
                      if (!_isUploading &&
                          _error != null &&
                          _lastAudioBytes != null)
                        OutlinedButton.icon(
                          onPressed: _retryUpload,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('重试上传'),
                        ),
                      OutlinedButton.icon(
                        onPressed: _asrController.text.trim().isEmpty
                            ? null
                            : _applyTranscriptToAnswer,
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('应用到答案'),
                      ),
                    ],
                  ),
                  if (_isMockRecording) ...<Widget>[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value:
                          (_mockRecordingSeconds / _maxAudioDuration.inSeconds)
                              .clamp(0, 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '模拟录音中 ${_formatDuration(Duration(milliseconds: (_mockRecordingSeconds * 1000).round()))} / 1:30',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                  if (_isUploading ||
                      _uploadProgress > 0 ||
                      _isMockRecognizing) ...<Widget>[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _isMockRecognizing
                          ? null
                          : _uploadProgress <= 0
                          ? null
                          : _uploadProgress / 100,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isMockRecognizing
                          ? '模拟识别中...'
                          : _isUploading
                          ? '上传进度 ${_uploadProgress.toStringAsFixed(0)}%'
                          : '上传完成',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '说明：客户端校验格式/大小/时长（可解析时），后端会强校验 90 秒限制。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  if (_notice != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      _notice!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBusy || _isMockRecording
                        ? null
                        : _pickAndUploadAudio,
                    icon: const Icon(Icons.mic_external_on_rounded),
                    label: const Text('Upload Voice'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
