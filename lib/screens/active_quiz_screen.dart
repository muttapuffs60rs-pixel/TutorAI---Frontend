import 'package:flutter/material.dart';

class ActiveQuizScreen extends StatefulWidget {
  final List<dynamic> questions;

  const ActiveQuizScreen({super.key, required this.questions});

  @override
  State<ActiveQuizScreen> createState() => _ActiveQuizScreenState();
}

class _ActiveQuizScreenState extends State<ActiveQuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedOption;
  bool _isAnswerChecked = false;

  void _checkAnswer() {
    if (_selectedOption == null) return;
    
    setState(() {
      _isAnswerChecked = true;
      
      String cleanSelected = _selectedOption!.trim();
      String cleanCorrect = widget.questions[_currentIndex]['correct_answer'].toString().trim();

      // Case-insensitive comparison for safety
      if (cleanSelected.toLowerCase() == cleanCorrect.toLowerCase()) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentIndex < widget.questions.length - 1) {
        _currentIndex++;
        _selectedOption = null;
        _isAnswerChecked = false;
      } else {
        _showResultsDialog();
      }
    });
  }

  void _showResultsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1F20),
        title: const Text('Quiz Complete! 🎉', textAlign: TextAlign.center),
        content: Text(
          'You scored $_score out of ${widget.questions.length}!',
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () {
                Navigator.of(context).pop(); // Close Dialog
                Navigator.of(context).pop(); // Go back to Setup Screen
              },
              child: const Text('Back to Menu', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No questions found!')),
      );
    }

    final currentQ = widget.questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of ${widget.questions.length}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The Question
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF282A2C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Text(
                currentQ['question'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // The Options
            _buildOptionCard(currentQ['option_a']),
            _buildOptionCard(currentQ['option_b']),
            _buildOptionCard(currentQ['option_c']),
            _buildOptionCard(currentQ['option_d']),
            
            const SizedBox(height: 24),

            // Explanation Box (Only shows after checking)
            if (_isAnswerChecked)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Use the trimmed comparison here!
                  color: _selectedOption!.trim() == currentQ['correct_answer'].toString().trim()
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedOption!.trim() == currentQ['correct_answer'].toString().trim() 
                        ? Colors.green 
                        : Colors.red
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedOption!.trim() == currentQ['correct_answer'].toString().trim() 
                          ? '✅ Correct!' 
                          : '❌ Incorrect!',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: _selectedOption!.trim() == currentQ['correct_answer'].toString().trim() 
                            ? Colors.greenAccent 
                            : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Akka says: ${currentQ['explanation']}',
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            // Action Button (Check or Next)
            ElevatedButton(
              onPressed: _selectedOption == null 
                  ? null 
                  : (_isAnswerChecked ? _nextQuestion : _checkAnswer),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _isAnswerChecked ? Colors.purpleAccent : Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isAnswerChecked ? 'Next Question' : 'Check Answer', 
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(String optionText) {
    // Clean strings for safe comparison
    String cleanOption = optionText.trim();
    String cleanSelected = _selectedOption?.trim() ?? '';
    String cleanCorrect = widget.questions[_currentIndex]['correct_answer'].toString().trim();

    bool isSelected = cleanSelected == cleanOption;
    bool isCorrectAnswer = cleanCorrect == cleanOption;
    
    Color borderColor = Colors.grey.shade800;
    Color bgColor = const Color(0xFF1E1F20);

    // If answer has been checked, highlight right/wrong
    if (_isAnswerChecked) {
      if (isCorrectAnswer) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.2);
      } else if (isSelected && !isCorrectAnswer) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.2);
      }
    } else if (isSelected) {
      // Just selected, not checked yet
      borderColor = Colors.blueAccent;
      bgColor = Colors.blueAccent.withOpacity(0.1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: _isAnswerChecked ? null : () {
          setState(() {
            _selectedOption = optionText;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Text(optionText, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}