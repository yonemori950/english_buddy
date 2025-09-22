import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // サンプルデータ（実際の実装ではFirestoreから取得）
    final userStats = {
      'grammar': 0.8,
      'vocabulary': 0.4,
      'reading': 0.7,
      'listening': 0.3,
    };

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
                        const Text(
                          '匿名ユーザー',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'レベル 1',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: 0.2,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[600]!),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'EXP: 20 / 100',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // レーダーチャート
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '分野別正答率',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: RadarChart(
                            RadarChartData(
                              dataSets: [
                                RadarDataSet(
                                  fillColor: Colors.teal.withOpacity(0.3),
                                  borderColor: Colors.teal,
                                  entryRadius: 2,
                                  dataEntries: [
                                    RadarEntry(value: userStats['grammar']! * 100),
                                    RadarEntry(value: userStats['vocabulary']! * 100),
                                    RadarEntry(value: userStats['reading']! * 100),
                                    RadarEntry(value: userStats['listening']! * 100),
                                  ],
                                ),
                              ],
                              radarBorderData: BorderSide(color: Colors.grey[300]!),
                              titlePositionPercentageOffset: 0.2,
                              titleTextStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                              getTitle: (index, angle) {
                                const titles = ['文法', '語彙', '長文', 'リスニング'];
                                return RadarChartTitle(
                                  text: titles[index],
                                  angle: angle,
                                  positionPercentageOffset: 0.1,
                                );
                              },
                              gridBorderData: BorderSide(color: Colors.grey[300]!),
                              tickBorderData: BorderSide(color: Colors.grey[300]!),
                              ticksTextStyle: const TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 詳細統計
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '詳細統計',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...userStats.entries.map((entry) {
                          final tagName = _getTagName(entry.key);
                          final percentage = (entry.value * 100).round();
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      tagName,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      '$percentage%',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _getAccuracyColor(entry.value),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: entry.value,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getAccuracyColor(entry.value),
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
                const SizedBox(height: 24),
                
                // 苦手分野の推奨
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '学習推奨',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRecommendation('語彙', 0.4, '語彙問題の復習をおすすめします。'),
                        _buildRecommendation('リスニング', 0.3, 'リスニング問題の復習をおすすめします。'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendation(String tag, double accuracy, String message) {
    if (accuracy >= 0.6) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getTagName(String tag) {
    switch (tag) {
      case 'grammar':
        return '文法';
      case 'vocabulary':
        return '語彙';
      case 'reading':
        return '長文';
      case 'listening':
        return 'リスニング';
      default:
        return tag;
    }
  }
}
