import 'dart:async';
import 'package:flutter/material.dart';

// Deborah Maignan
void main() => runApp(const PetApp());


const Duration _hungerInterval = Duration(seconds: 60);
const Duration _winDuration = Duration(minutes: 3);

// Colors
const _bg = Color.fromARGB(255, 253, 253, 253);
const _ink = Color.fromARGB(255, 7, 26, 22);
const _happyColor = Color.fromARGB(255, 20, 156, 101);
const _hungerColor = Color.fromARGB(255, 14, 169, 212);
const _energyColor = Color.fromARGB(255, 240, 142, 38);
const _trackColor = Color.fromARGB(255, 250, 251, 249);
const _accent = Color.fromARGB(255, 211, 128, 18);

/// StatelessWidget:
class PetApp extends StatelessWidget {
  const PetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Pet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(seedColor: _happyColor),
        useMaterial3: true,
      ),
      home: const PetScreen(),
    );
  }
}

/// StatefulWidget immutable
class PetScreen extends StatefulWidget {
  const PetScreen({super.key});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  // Game state 
  int _happiness = 50;
  int _hunger = 50;
  int _energy = 70;
  String _petName = 'Pip';
  bool _gameOver = false;
  bool _hasWon = false;
  String _lastResult = 'Choose an action to see which pet values change.';

  // Timers and controllers 
  Timer? _hungerTimer;
  Timer? _highMoodTimer;
  final TextEditingController _nameController =
      TextEditingController(text: 'Pip');

  bool get _careDisabled => _gameOver || _hasWon;

  int _clampMeter(int value) => value.clamp(0, 100).toInt();

  // Lifecycle
  @override
  void initState() {
    super.initState();
    _startHungerTimer();
  }

  @override
  void dispose() {
    _hungerTimer?.cancel();
    _highMoodTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  // Timers
  void _startHungerTimer() {
    _hungerTimer?.cancel();
    _hungerTimer = Timer.periodic(_hungerInterval, (timer) {
      if (!mounted || _careDisabled) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_hunger + 5 > 100) {
          _hunger = 100;
          _happiness = _clampMeter(_happiness - 20);
        } else {
          _hunger += 5;
        }
        _lastResult = 'Time passed: hunger rose.';
      });
      _updateOutcome();
    });
  }

  void _updateOutcome() {
    if (_careDisabled) return;

    // Loss
    if (_hunger == 100 && _happiness <= 10) {
      _highMoodTimer?.cancel();
      _highMoodTimer = null;
      _hungerTimer?.cancel();
      setState(() {
        _gameOver = true;
        _lastResult = 'Game over. $_petName is to hungry and sad.';
      });
      return;
    }

    // Happiness dropped to 80 or below
    if (_happiness <= 80) {
      _highMoodTimer?.cancel();
      _highMoodTimer = null;
      return;
    }

    // Happiness is greater than80
    _highMoodTimer ??= Timer(_winDuration, () {
      _highMoodTimer = null;
      if (!mounted || _gameOver || _happiness <= 80) return;
      _hungerTimer?.cancel();
      setState(() {
        _hasWon = true;
        _lastResult = 'You win! $_petName stayed happy the whole time.';
      });
    });
  }

  // Actions
  void _feedPet() {
    if (_careDisabled) return;

    final nextHunger = _clampMeter(_hunger - 10);
    final happinessChange = nextHunger < 30 ? -20 : 10;
    final nextHappiness = _clampMeter(_happiness + happinessChange);

    setState(() {
      _hunger = nextHunger;
      _happiness = nextHappiness;
      _lastResult = happinessChange > 0
          ? 'Fed: hunger -10, happiness +10.'
          : 'Fed: hunger -10, but overfeeding made $_petName sluggish (happiness -20).';
    });
    _updateOutcome();
  }

  void _playWithPet() {
    if (_careDisabled) return;

    setState(() {
      _happiness = _clampMeter(_happiness + 15);
      _hunger = _clampMeter(_hunger + 10);
      _energy = _clampMeter(_energy - 15);
      _lastResult = 'Played: happiness +15, hunger +10, energy -15.';
    });
    _updateOutcome();
  }

  void _restPet() {
    if (_careDisabled) return;

    setState(() {
      _energy = _clampMeter(_energy + 25);
      _hunger = _clampMeter(_hunger + 5);
      _lastResult = 'Rested: energy +25, hunger +5.';
    });
    _updateOutcome();
  }

  void _reset() {
    _highMoodTimer?.cancel();
    _highMoodTimer = null;
    setState(() {
      _happiness = 50;
      _hunger = 50;
      _energy = 70;
      _gameOver = false;
      _hasWon = false;
      _lastResult = 'Choose an action to see which pet values change.';
    });
    _startHungerTimer(); 
  }

  void _confirmName() {
    final text = _nameController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _petName = text;
      _lastResult = 'Name confirmed: $_petName.';
    });
  }

  // Derived values
  String get _petMessage {
    if (_gameOver) return 'I need a rest.';
    if (_hasWon) return 'Best day ever!';
    if (_hunger > 80) return "I'm starving!";
    if (_happiness <= 30) return 'Play with me?';
    if (_energy < 20) return 'So sleepy...';
    return "Hi, I'm $_petName!";
  }

  double get _petScale =>
      _happiness > 70 ? 1.06 : (_happiness < 30 ? 0.94 : 1.0);

  Color get _moodColor {
    if (_happiness > 70) return Colors.green;
    if (_happiness >= 30) return Colors.yellow;
    return Colors.red;
  }

  String get _moodLabel {
    if (_hasWon) return 'Winner';
    if (_gameOver) return 'Game over';
    if (_happiness > 70) return 'Happy';
    if (_happiness >= 30) return 'Neutral';
    return 'Sad';
  }

  IconData get _moodIcon {
    if (_hasWon) return Icons.emoji_events;
    if (_gameOver) return Icons.heart_broken;
    if (_happiness > 70) return Icons.sentiment_very_satisfied;
    if (_happiness >= 30) return Icons.sentiment_neutral;
    return Icons.sentiment_very_dissatisfied;
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const Divider(color: Color(0xFFCFD8CF)),
                  const SizedBox(height: 8),
                  _petRow(reduceMotion),
                  const SizedBox(height: 16),
                  _meter('Happiness', _happiness, _happyColor, reduceMotion),
                  _meter('Hunger', _hunger, _hungerColor, reduceMotion),
                  _meter('Energy', _energy, _energyColor, reduceMotion),
                  const SizedBox(height: 12),
                  _nameRow(),
                  const SizedBox(height: 12),
                  _buttons(),
                  const SizedBox(height: 14),
                  _resultBox(),
                  const SizedBox(height: 12),
                  const Text(
                    'Mood changes the coat color, face, and size.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('State preview',
              style: TextStyle(fontWeight: FontWeight.w600, color: _ink)),
          // Mood shown as icon + text, so color is never the only signal.
          Row(children: [
            Icon(_moodIcon, size: 20, color: _ink),
            const SizedBox(width: 6),
            Text(_moodLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _ink)),
          ]),
        ],
      );

  Widget _petRow(bool reduceMotion) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFCFE6E0),
              border: Border.all(color: _accent, width: 3),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(8),
            child: AnimatedScale(
              scale: _petScale,
              duration:
                  reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(_moodColor, BlendMode.modulate),
                child: Image.asset('assets/pet.png', semanticLabel: 'Pet'),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_petName,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                        color: _ink)),
                const SizedBox(height: 4),
                const Text('Try an action',
                    style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _trackColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    child: Text(_petMessage,
                        key: ValueKey(_petMessage),
                        style: const TextStyle(color: _ink)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _meter(String label, int value, Color color, bool reduceMotion) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(
              width: 92,
              child: Text(label, style: const TextStyle(color: _ink))),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value / 100),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                color: color,
                backgroundColor: _trackColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text('$value',
                textAlign: TextAlign.right,
                style: const TextStyle(color: _ink)),
          ),
        ]),
      );

  Widget _nameRow() => Row(children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            maxLength: 16,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirmName(),
            decoration: const InputDecoration(
              labelText: 'Pet name',
              counterText: '',
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: _confirmName, child: const Text('Confirm')),
      ]);

  Widget _buttons() => Wrap(spacing: 8, runSpacing: 8, children: [
        _btn('Play', _careDisabled ? null : _playWithPet),
        _btn('Feed', _careDisabled ? null : _feedPet),
        _btn('Rest', _careDisabled ? null : _restPet),
        _btn('Reset', _reset), // Reset is always enabled
      ]);

  Widget _btn(String text, VoidCallback? onPressed) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFB9C4BC)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  Widget _resultBox() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFFDCEEF0),
          border: Border(left: BorderSide(color: _hungerColor, width: 4)),
        ),
        // liveRegion: screen readers announce the result when it changes.
        child: Semantics(
          liveRegion: true,
          child: Text(_lastResult, style: const TextStyle(color: _ink)),
        ),
      );
}
