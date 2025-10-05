import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/idfa_service.dart';
import 'services/tts_service.dart';
import 'services/purchase_service.dart';
import 'services/sound_service.dart';
import 'services/explanation_service.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Starting app initialization...');
    // Initialize only critical services synchronously
    await FirebaseService.initialize();
    print('Firebase initialized, starting app...');
    
    runApp(const EnglishBuddyApp());
    
    // Initialize non-critical services asynchronously after app starts
    _initializeNonCriticalServices();
  } catch (e) {
    print('App initialization failed: $e');
    // Firebase初期化に失敗してもアプリは起動する
    runApp(const EnglishBuddyApp());
    
    // 非同期でFirebase初期化を再試行
    _retryFirebaseInitialization();
  }
}

void _retryFirebaseInitialization() async {
  try {
    await Future.delayed(const Duration(seconds: 2));
    await FirebaseService.initialize();
    print('Firebase initialization retry successful');
  } catch (e) {
    print('Firebase initialization retry failed: $e');
  }
}

void _initializeNonCriticalServices() async {
  // Run these in parallel for faster initialization
  await Future.wait([
    AdService.initialize(),
    NotificationService.initialize(),
    IDFAService.initialize(),
    TTSService.initialize(),
    PurchaseService.initialize(),
    SoundService.loadSoundSettings(),
    ExplanationService.loadExplanations(),
  ]);
}

class EnglishBuddyApp extends StatelessWidget {
  const EnglishBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider()..initAuth(),
      child: MaterialApp(
        title: '英検2級クイズ',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        home: const HomeScreen(),
        onGenerateRoute: (settings) {
          // メールリンクからのディープリンク処理
          if (settings.name != null && settings.name!.contains('login')) {
            return MaterialPageRoute(
              builder: (context) => const EmailLinkHandler(),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
  }
}

// メールリンクハンドラー
class EmailLinkHandler extends StatefulWidget {
  const EmailLinkHandler({super.key});

  @override
  State<EmailLinkHandler> createState() => _EmailLinkHandlerState();
}

class _EmailLinkHandlerState extends State<EmailLinkHandler> {
  @override
  void initState() {
    super.initState();
    _handleEmailLink();
  }

  void _handleEmailLink() async {
    try {
      // 現在のURLを取得
      final Uri? uri = Uri.tryParse(ModalRoute.of(context)?.settings.name ?? '');
      if (uri == null) {
        _navigateToHome();
        return;
      }

      // メールリンクかチェック
      final auth = FirebaseAuth.instance;
      if (!auth.isSignInWithEmailLink(uri.toString())) {
        _navigateToHome();
        return;
      }

      // メールアドレスを取得（SharedPreferencesから）
      // 実際の実装では、メールアドレスを安全に保存・取得する必要があります
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // メールアドレス入力ダイアログを表示
      _showEmailInputDialog(uri.toString());
    } catch (e) {
      print('Email link handling error: $e');
      _navigateToHome();
    }
  }

  void _showEmailInputDialog(String link) {
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mail, color: Colors.green),
              SizedBox(width: 8),
              Text('ログインを完了'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'メールリンクを確認しました。\nメールアドレスを入力してログインを完了してください。',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  hintText: 'example@email.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _navigateToHome();
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('メールアドレスを入力してください'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                
                // ローディング表示
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('ログイン中...'),
                      ],
                    ),
                  ),
                );
                
                try {
                  final userProvider = Provider.of<UserProvider>(context, listen: false);
                  final success = await userProvider.signInWithEmailLink(email, link);
                  
                  // ローディングダイアログを閉じる
                  Navigator.of(context).pop();
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ログインが完了しました！'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _navigateToHome();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(userProvider.error ?? 'ログインに失敗しました'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    _navigateToHome();
                  }
                } catch (e) {
                  // ローディングダイアログを閉じる
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('エラー: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  _navigateToHome();
                }
              },
              child: const Text('ログイン'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('アプリの初期化に失敗しました', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  void _checkInitialization() async {
    // Wait for services to initialize
    while (!FirebaseService.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      
      // Navigate to home screen after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[600],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon or logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school,
                size: 60,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '英検2級クイズ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '英語力を向上させましょう',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            if (!_isInitialized)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
