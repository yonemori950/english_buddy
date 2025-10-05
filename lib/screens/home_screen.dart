import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'quiz_screen.dart';
import 'weakness_quiz_screen.dart';
import 'ranking_screen.dart';
import 'profile_screen.dart';
import 'notification_settings_screen.dart';
import 'idfa_settings_screen.dart';
import 'subscription_screen.dart';
import '../widgets/banner_ad_widget.dart';
import '../providers/user_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // ローディング中
        if (userProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // エラーがある場合
        if (userProvider.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      userProvider.clearError();
                      userProvider.signInAnonymously();
                    },
                    child: const Text('再試行'),
                  ),
                ],
              ),
            ),
          );
        }

        // ユーザーがログインしていない場合
        if (userProvider.currentUser == null) {
          return _buildLoginScreen(context, userProvider);
        }

        // メイン画面
        return _buildMainScreen(context, userProvider);
      },
    );
  }

  Widget _buildLoginScreen(BuildContext context, UserProvider userProvider) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // アプリロゴ
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // アプリタイトル
                Text(
                  '英検2級クイズ',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  '英検2級レベルの問題で\n英語力を向上させましょう！',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 48),
                
                // ログインボタン
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await userProvider.signInAnonymously();
                    },
                    icon: const Icon(Icons.person),
                    label: const Text(
                      'ゲストとして開始',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Googleログインボタン
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await userProvider.signInWithGoogle();
                    },
                    icon: Image.asset(
                      'assets/icons/google_logo.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.login, size: 24);
                      },
                    ),
                    label: const Text(
                      'Googleでログイン',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // メールリンクログインボタン
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showEmailLoginDialog(context, userProvider);
                    },
                    icon: const Icon(Icons.mail, size: 24),
                    label: const Text(
                      'メールでログイン',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'ゲストで開始するか、Googleアカウントまたはメールでログインできます。\nデータは安全に保存されます。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen(BuildContext context, UserProvider userProvider) {
    final user = userProvider.currentUser!;
    
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showNameChangeDialog(context, userProvider, user.name),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '英検2級クイズ',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'こんにちは、${user.name}さん',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          // Googleで保存ボタン（ゲストユーザーのみ表示）
          if (userProvider.isCurrentUserGuest)
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'Googleで保存',
              onPressed: () => _showLinkToGoogleDialog(context, userProvider),
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.track_changes),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IDFASettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await userProvider.signOut();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ユーザー情報カード
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue[600],
                              child: const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'レベル ${user.level}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: (user.exp % 100) / 100.0, // 経験値の進捗
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue[600]!,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'EXP: ${user.exp % 100} / 100',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // メニューボタン
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildMenuCard(
                        context,
                        'クイズスタート',
                        Icons.quiz,
                        Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QuizScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        context,
                        '苦手克服',
                        Icons.trending_up,
                        Colors.orange,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WeaknessQuizScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        context,
                        'ランキング',
                        Icons.emoji_events,
                        Colors.purple,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RankingScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        context,
                        '学習分析',
                        Icons.analytics,
                        Colors.teal,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // バナー広告
                const SizedBox(height: 16),
                const BannerAdWidget(
                  height: 60,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNameChangeDialog(BuildContext context, UserProvider userProvider, String currentName) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('名前を変更'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('新しい名前を入力してください'),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名前',
                  border: OutlineInputBorder(),
                  hintText: '例: 田中太郎',
                ),
                maxLength: 20,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('名前を入力してください')),
                  );
                  return;
                }
                
                if (newName == currentName) {
                  Navigator.of(context).pop();
                  return;
                }
                
                Navigator.of(context).pop();
                
                // 名前を更新
                final success = await userProvider.updateUserName(newName);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('名前を変更しました')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(userProvider.error ?? '名前の変更に失敗しました')),
                  );
                }
              },
              child: const Text('変更'),
            ),
          ],
        );
      },
    );
  }

  // Googleで保存ダイアログ
  void _showLinkToGoogleDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Googleで保存'),
          content: const Text(
            '現在のゲストアカウントをGoogleアカウントにリンクします。\n'
            'これにより、進捗データが永続的に保存され、他のデバイスでも利用できるようになります。\n\n'
            'この操作は取り消すことができません。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
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
                        Text('Googleアカウントにリンク中...'),
                      ],
                    ),
                  ),
                );
                
                try {
                  final success = await userProvider.linkGuestToGoogle();
                  
                  // ローディングダイアログを閉じる
                  Navigator.of(context).pop();
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Googleアカウントにリンクしました！'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(userProvider.error ?? 'リンクに失敗しました'),
                        backgroundColor: Colors.red,
                      ),
                    );
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
                }
              },
              child: const Text('リンクする'),
            ),
          ],
        );
      },
    );
  }

  // メールログインダイアログを表示
  void _showEmailLoginDialog(BuildContext context, UserProvider userProvider) {
    final TextEditingController emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.mail, color: Colors.green),
              SizedBox(width: 8),
              Text('メールでログイン'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'メールアドレスを入力してください。\nログイン用のリンクをお送りします。',
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
                Navigator.of(context).pop();
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
                
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('有効なメールアドレスを入力してください'),
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
                        Text('メールリンクを送信中...'),
                      ],
                    ),
                  ),
                );
                
                try {
                  final success = await userProvider.sendSignInLinkToEmail(email);
                  
                  // ローディングダイアログを閉じる
                  Navigator.of(context).pop();
                  
                  if (success) {
                    _showEmailSentDialog(context, email);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(userProvider.error ?? 'メールリンクの送信に失敗しました'),
                        backgroundColor: Colors.red,
                      ),
                    );
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
                }
              },
              child: const Text('送信'),
            ),
          ],
        );
      },
    );
  }

  // メール送信完了ダイアログを表示
  void _showEmailSentDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('メールを送信しました'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$email にログイン用のリンクを送信しました。'),
              const SizedBox(height: 16),
              const Text(
                'メール内のリンクをタップしてログインを完了してください。',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
