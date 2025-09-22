class Question {
  final int id;
  final String question;
  final List<String> choices;
  final String answer;
  final String tag;
  final String? audio;

  Question({
    required this.id,
    required this.question,
    required this.choices,
    required this.answer,
    required this.tag,
    this.audio,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'],
      choices: List<String>.from(json['choices']),
      answer: json['answer'],
      tag: json['tag'],
      audio: json['audio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'choices': choices,
      'answer': answer,
      'tag': tag,
      'audio': audio,
    };
  }
}
