import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:speaksense_app/app/app_shell.dart';
import 'package:speaksense_app/app/app_state.dart';
import 'package:speaksense_app/services/api_service.dart';
import 'package:speaksense_app/services/content_repository.dart';
import 'package:speaksense_app/services/websocket_service.dart';
import 'package:speaksense_app/theme/app_theme.dart';

class SpeakSenseApp extends StatelessWidget {
  const SpeakSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<WebSocketService>(
          create: (_) => WebSocketService(),
          dispose: (_, WebSocketService service) => service.dispose(),
        ),
        ProxyProvider<ApiService, ContentRepository>(
          update: (_, ApiService apiService, _) =>
              ContentRepository(apiService: apiService),
        ),
      ],
      child: MaterialApp(
        title: 'SpeakSense AI English Coach',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const AppShell(),
      ),
    );
  }
}
