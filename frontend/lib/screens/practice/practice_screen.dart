import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
                FButton(
                  onPress: onExit,
                  style: FButtonStyle.ghost(),
                  prefix: const Icon(Icons.logout_rounded),
                  child: const Text('退出会话'),
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
                  child: FButton(
                    onPress: onSubmit,
                    prefix: const Icon(Icons.send_rounded),
                    child: const Text('Submit Answer'),
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
  static const int _softWordLimit = 35;
  static const int _hardWordLimit = 40;
  static const String _draftKey = 'practice_answer_draft';
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
  String? _draftStatus;
  CancelToken? _cancelToken;
  Uint8List? _lastAudioBytes;
  String? _lastAudioFileName;
  Timer? _mockRecordingTimer;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController(
      text: 'I would like a small latte, please.',
    );
    _asrController = TextEditingController();
    _loadDraft();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('dispose');
    _mockRecordingTimer?.cancel();
    _draftTimer?.cancel();
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

  void _showNotice(
    String title, {
    String? description,
    IconData icon = Icons.check_circle_rounded,
  }) {
    if (!mounted) {
      return;
    }
    showFToast(
      context: context,
      title: Text(title),
      description: description == null ? null : Text(description),
      icon: Icon(icon),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) {
      return;
    }
    final bool canRetry = _lastAudioBytes != null;
    await showFDialog<void>(
      context: context,
      builder: (
        BuildContext context,
        FDialogStyle dialogStyle,
        Animation<double> animation,
      ) {
        return FDialog(
          title: const Text('语音处理失败'),
          body: Text(message),
          actions: <Widget>[
            if (canRetry)
              FButton(
                onPress: () {
                  Navigator.of(context).pop();
                  _retryUpload();
                },
                child: const Text('重试上传'),
              ),
            FButton(
              style: FButtonStyle.outline(),
              onPress: () => Navigator.of(context).pop(),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

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
    });
    _showNotice('模拟录音中', description: '再次点击可结束。', icon: Icons.mic_rounded);

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

  Future<void> _loadDraft() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? draft = prefs.getString(_draftKey);
    if (!mounted || draft == null || draft.trim().isEmpty) {
      return;
    }
    setState(() {
      _answerController.text = draft;
      _draftStatus = '已恢复上次草稿';
    });
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 600), _saveDraftNow);
  }

  Future<void> _saveDraftNow() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, _answerController.text);
    if (!mounted) {
      return;
    }
    setState(() {
      _draftStatus = '草稿已保存';
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
    });
    _showNotice('模拟识别中', icon: Icons.graphic_eq_rounded);

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
    });
    _showNotice('模拟语音识别完成', description: '可编辑后应用到答案。');
  }

  Future<void> _pickAndUploadAudio() async {
    if (_isMockRecording) {
      _showErrorDialog('请先结束模拟录音，再执行文件上传。');
      return;
    }
    if (_isMockRecognizing) {
      return;
    }

    setState(() {
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
      _showErrorDialog('未读取到音频文件数据，请更换文件重试。');
      return;
    }

    final String extension = _extractExtension(file.name);
    if (!_allowedExtensions.contains(extension)) {
      _showErrorDialog('不支持的音频格式：.$extension。');
      return;
    }
    if (bytes.lengthInBytes > _maxAudioBytes) {
      final double sizeMb = bytes.lengthInBytes / (1024 * 1024);
      _showErrorDialog(
        '音频过大（${sizeMb.toStringAsFixed(2)}MB），请控制在 10MB 内。',
      );
      return;
    }

    final Duration? duration = await probeAudioDuration(
      bytes,
      mimeType: _guessMimeType(extension),
    );
    if (duration != null && duration > _maxAudioDuration) {
      _showErrorDialog(
        '音频时长 ${_formatDuration(duration)}，超过 90 秒限制。',
      );
      return;
    }

    setState(() {
      _pickedFileName = file.name;
      _pickedDuration = duration;
      _lastAudioBytes = bytes;
      _lastAudioFileName = file.name;
      _isUploading = true;
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
      });
      _showNotice(
        widget.useMockApi ? 'Mock ASR 已生成预览' : '语音上传成功',
        description: widget.useMockApi
            ? '可直接编辑。'
            : '已生成 ASR 预览。'
                  '${duration == null ? '（未读取本地时长，已交由后端做 90 秒校验）' : ''}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (error is ApiRequestException) {
        final String extra = error.code == null ? '' : ' [${error.code}]';
        await _showErrorDialog('${error.message}$extra');
      } else {
        await _showErrorDialog('语音上传失败：$error');
      }
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
    });
    _showNotice('已应用 ASR 预览', description: '文本已更新到答案输入框。');
    _scheduleDraftSave();
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
    final bool overLimit = count > _hardWordLimit;
    final bool nearLimit = count >= _softWordLimit && count <= _hardWordLimit;
    final Color countColor = overLimit
        ? Colors.red
        : nearLimit
        ? Colors.orange.shade700
        : theme.hintColor;

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
            FTextField(
              control: FTextFieldControl.managed(
                controller: _answerController,
                onChange: (_) {
                  setState(() {});
                  _scheduleDraftSave();
                },
              ),
              maxLines: 8,
              hint: 'Start speaking or type your answer...',
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
                        : nearLimit
                        ? Colors.orange.withValues(alpha: 0.12)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$count / 40 words',
                    style: TextStyle(
                      color: countColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (nearLimit && !overLimit) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '已接近 35 词软上限，建议精简回答。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (overLimit) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '已超过 40 词上限，请缩短回答。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_draftStatus != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                _draftStatus!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
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
                  FTextField(
                    control: FTextFieldControl.managed(
                      controller: _asrController,
                      onChange: (_) => setState(() {}),
                    ),
                    maxLines: 4,
                    hint: 'ASR transcript preview will appear here...',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FButton(
                        onPress: _isUploading || _isMockRecognizing
                            ? null
                            : _toggleMockRecording,
                        prefix: Icon(
                          _isMockRecording
                              ? Icons.stop_circle_rounded
                              : Icons.mic_rounded,
                        ),
                        child: Text(_isMockRecording ? '结束模拟录音' : '点击说话（Mock）'),
                      ),
                      FButton(
                        onPress: _isBusy || _isMockRecording
                            ? null
                            : _pickAndUploadAudio,
                        style: FButtonStyle.outline(),
                        prefix: _isUploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file_rounded),
                        child: Text(_isUploading ? '上传中...' : '选择并上传音频'),
                      ),
                      if (_isUploading)
                        FButton(
                          onPress: _cancelUpload,
                          style: FButtonStyle.destructive(),
                          prefix: const Icon(Icons.stop_circle_outlined),
                          child: const Text('取消上传'),
                        ),
                      FButton(
                        onPress: _asrController.text.trim().isEmpty
                            ? null
                            : _applyTranscriptToAnswer,
                        style: FButtonStyle.secondary(),
                        prefix: const Icon(Icons.edit_note_rounded),
                        child: const Text('应用到答案'),
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FButton(
                    onPress: _isBusy || _isMockRecording
                        ? null
                        : _pickAndUploadAudio,
                    style: FButtonStyle.outline(),
                    prefix: const Icon(Icons.mic_external_on_rounded),
                    child: const Text('Upload Voice'),
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
