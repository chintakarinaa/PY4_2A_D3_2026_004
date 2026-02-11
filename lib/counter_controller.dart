class CounterController {
  int _counter = 0;
  int _step = 1;

  final List<String> _history = [];

  int get value => _counter;
  int get step => _step;
  List<String> get history => List.unmodifiable(_history);

  void setStep(int newStep) {
    if (newStep > 0) {
      _step = newStep;
    }
  }

  void _addHistory(String message) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    _history.add('[$time] $message');

    // Batasin 5 data terakhir
    if (_history.length > 5) {
      _history.removeAt(0);
    }
  }

  void increment() {
    _counter += _step;
    _addHistory("Tambah $_step");
  }

  void decrement() {
    if (_counter - _step >= 0) {
      _counter -= _step;
      _addHistory("Kurang $_step");
    }
  }

  void reset() {
    _counter = 0;
    _addHistory("Reset counter");
  }
}
