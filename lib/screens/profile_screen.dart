import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/user_provider.dart';
import '../services/weakness_analysis_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('ユーザー情報がありません'),
            ),
          );
        }

        final analysis = WeaknessAnalysisService.analyzeWeakness(user);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('学習分析'),
            backgroundColor: Colors.teal[600],
            foregroundColor: Colors.white,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.teal[50]!, Colors.white],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ユーザー情報
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.teal[600],
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showNameChangeDialog(context, userProvider, user.name),
                                  tooltip: '名前を変更',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'レベル ${user.level}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '総経験値: ${user.exp}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 全体スコア
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '全体スコア',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${(analysis['overallScore'] * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: _getScoreColor(analysis['overallScore']),
                                        ),
                                      ),
                                      Text(
                                        WeaknessAnalysisService.getLevelDisplayName(analysis['weaknessLevel']),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CircularProgressIndicator(
                                    value: analysis['overallScore'],
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getScoreColor(analysis['overallScore']),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 分野別分析
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '分野別分析',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...analysis['tagAnalysis'].entries.map<Widget>((entry) {
                              final tag = entry.key;
                              final data = entry.value as Map<String, dynamic>;
                              return _buildTagAnalysisItem(tag, data);
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // レーダーチャート
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'スキル分布',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildRadarChart(analysis['tagAnalysis']),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 推奨事項
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '学習のアドバイス',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...(analysis['recommendations'] as List<String>).map<Widget>((recommendation) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.amber[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        recommendation,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagAnalysisItem(String tag, Map<String, dynamic> data) {
    final accuracy = data['accuracy'] as double;
    final correct = data['correct'] as int;
    final wrong = data['wrong'] as int;
    final total = data['total'] as int;
    final level = data['level'] as String;
    final recommendation = data['recommendation'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                WeaknessAnalysisService.getTagDisplayName(tag),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getLevelColor(level),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  WeaknessAnalysisService.getLevelDisplayName(level),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: accuracy,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getScoreColor(accuracy),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(accuracy * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$correct問正解 / $total問中',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart(Map<String, dynamic> tagAnalysis) {
    if (tagAnalysis.isEmpty) {
      return const Center(
        child: Text('データがありません'),
      );
    }

    final spots = <FlSpot>[];
    final labels = <String>[];
    int index = 0;

    tagAnalysis.forEach((tag, data) {
      final accuracy = data['accuracy'] as double;
      spots.add(FlSpot(index.toDouble(), accuracy * 100));
      labels.add(WeaknessAnalysisService.getTagDisplayName(tag));
      index++;
    });

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: Colors.teal.withOpacity(0.3),
            borderColor: Colors.teal,
            entryRadius: 2,
            dataEntries: spots.map((spot) => RadarEntry(value: spot.y)).toList(),
          ),
        ],
        radarBorderData: BorderSide(color: Colors.grey[400]!, width: 1),
        titlePositionPercentageOffset: 0.2,
        titleTextStyle: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
        ),
        getTitle: (index, angle) {
          if (index < labels.length) {
            return RadarChartTitle(
              text: labels[index],
              angle: angle,
              positionPercentageOffset: 0.1,
            );
          }
          return const RadarChartTitle(text: '');
        },
        tickBorderData: BorderSide(color: Colors.grey[300]!, width: 1),
        ticksTextStyle: const TextStyle(
          fontSize: 10,
          color: Colors.black54,
        ),
        gridBorderData: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'excellent': return Colors.green;
      case 'good': return Colors.blue;
      case 'fair': return Colors.orange;
      case 'weak': return Colors.red;
      default: return Colors.grey;
    }
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
}