import 'package:flutter/material.dart';

void main() => runApp(const CalculatorApp());

const List<String> operators = ['+', '-', '×', '÷', '%'];

bool isOperator(String c) => operators.contains(c);

double evaluate(String expression) {
  var expr = expression;

  while (expr.isNotEmpty && isOperator(expr[expr.length - 1])) {
    expr = expr.substring(0, expr.length - 1);
  }
  if (expr.isEmpty) return 0;

  final numbers = <double>[];
  final ops = <String>[];
  var buffer = '';

  for (var i = 0; i < expr.length; i++) {
    final c = expr[i];
    if (isOperator(c)) {
      if (i == 0 && c == '-') {
        buffer = '-';
        continue;
      }
      numbers.add(_parse(buffer));
      ops.add(c);
      buffer = '';
    } else {
      buffer += c;
    }
  }
  numbers.add(_parse(buffer));

  final nums2 = <double>[numbers.first];
  final ops2 = <String>[];
  for (var i = 0; i < ops.length; i++) {
    final op = ops[i];
    final right = numbers[i + 1];
    if (op == '×' || op == '÷' || op == '%') {
      final left = nums2.removeLast();
      nums2.add(_apply(left, op, right));
    } else {
      ops2.add(op);
      nums2.add(right);
    }
  }

  var result = nums2.first;
  for (var i = 0; i < ops2.length; i++) {
    result = _apply(result, ops2[i], nums2[i + 1]);
  }
  return result;
}

double _parse(String s) {
  if (s.isEmpty || s == '-') return 0;
  final value = double.tryParse(s);
  if (value == null) throw const FormatException('Nombre invalide');
  return value;
}

double _apply(double a, String op, double b) {
  switch (op) {
    case '+':
      return a + b;
    case '-':
      return a - b;
    case '×':
      return a * b;
    case '÷':
      if (b == 0) throw const FormatException('Division par zéro');
      return a / b;
    case '%':
      if (b == 0) throw const FormatException('Modulo par zéro');
      return a % b;
    default:
      throw FormatException('Opérateur inconnu : $op');
  }
}

String formatNumber(double value) {
  if (value.isNaN || value.isInfinite) return 'Erreur';
  if (value == value.roundToDouble() && value.abs() < 1e15) {
    return value.toInt().toString();
  }
  var s = value.toStringAsFixed(8);

  s = s.replaceFirst(RegExp(r'0+$'), '');
  s = s.replaceFirst(RegExp(r'\.$'), '');
  return s;
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculatrice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static const Color _buttonColor = Color(0xFF333333);
  static const Color _equalsColor = Color(0xFFFF9500);

  String _expression = '';

  String _result = '0';

  static const List<List<String>> _keys = [
    ['C', '%', '÷', '×'],
    ['7', '8', '9', '-'],
    ['4', '5', '6', '+'],
    ['1', '2', '3', '='],
    ['0', '.'],
  ];

  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'C') {
        _clear();
      } else if (key == '=') {
        _equals();
      } else if (isOperator(key)) {
        _addOperator(key);
      } else if (key == '.') {
        _addDecimalPoint();
      } else {
        _addDigit(key);
      }
    });
  }

  void _clear() {
    _expression = '';
    _result = '0';
  }

  void _equals() {
    if (_expression.isEmpty) return;
    try {
      final value = formatNumber(evaluate(_expression));
      _result = value;
      _expression = value;
    } on FormatException catch (e) {
      _result = e.message;
      _expression = '';
    }
  }

  void _addDigit(String digit) {
    _expression += digit;
    _updateLiveResult();
  }

  void _addOperator(String op) {
    if (_expression.isEmpty) {
      if (op == '-') _expression = '-';
      return;
    }
    final last = _expression[_expression.length - 1];
    if (isOperator(last)) {
      // Évite "5+×3" : on remplace l'opérateur précédent.
      if (_expression.length == 1) return; // "-" seul
      _expression = _expression.substring(0, _expression.length - 1) + op;
    } else {
      _expression += op;
    }
  }

  void _addDecimalPoint() {
    var start = 0;
    for (var i = _expression.length - 1; i >= 0; i--) {
      if (isOperator(_expression[i])) {
        start = i + 1;
        break;
      }
    }
    final current = _expression.substring(start);
    if (current.contains('.')) return;
    _expression += current.isEmpty ? '0.' : '.';
  }

  void _updateLiveResult() {
    try {
      _result = formatNumber(evaluate(_expression));
    } on FormatException {
      // On ignore l'erreur pendant la saisie.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Zone d'affichage (prend l'espace restant => responsive).
            Expanded(flex: 2, child: _buildDisplay()),
            // Clavier.
            Expanded(flex: 4, child: _buildKeypad()),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.bottomRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _result,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _expression,
              style: const TextStyle(color: Colors.white70, fontSize: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final row in _keys)
            Expanded(
              child: Row(
                children: [
                  for (final key in row) _buildButton(key),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildButton(String label) {
    final isEquals = label == '=';
    final isZero = label == '0';
    return Expanded(
      flex: isZero ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ElevatedButton(
          onPressed: () => _onKeyPressed(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: isEquals ? _equalsColor : _buttonColor,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
          ),
        ),
      ),
    );
  }
}