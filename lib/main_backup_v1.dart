import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kBannerAdUnitId = 'ca-app-pub-7094485651472008/3776015512';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const MaasSayaciApp());
}

class MaasSayaciApp extends StatelessWidget {
  const MaasSayaciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maaş Sayacı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22C55E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum ModeType {
  wc('🚽', 'WC Modu', 'Bu WC molasında'),
  yemek('🍽️', 'Yemek Modu', 'Bu yemekte'),
  toplanti('🤝', 'Toplantı Modu', 'Bu toplantıda'),
  yatis('🛌', 'Yatış Modu', 'Yatarak'),
  kahve('☕', 'Kahve Modu', 'Bu kahve molasında'),
  trafik('🚗', 'Trafik Modu', 'Bu trafikte beklerken'),
  sosyal('📱', 'Instagram Modu', 'Bu kaydırma seansında'),
  tatil('🏖️', 'Tatil Modu', 'Tatil yaparken');

  final String icon;
  final String title;
  final String resultText;
  const ModeType(this.icon, this.title, this.resultText);
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _goalAmountController = TextEditingController();

  Timer? _timer;
  double _monthlySalary = 0;
  DateTime _now = DateTime.now();

  String _goalName = '';
  double _goalAmount = 0;

  ModeType? _activeMode;
  DateTime? _modeStart;
  String? _lastModeResult;

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  double get _perSecond => _monthlySalary / 30 / 24 / 60 / 60;
  double get _perMinute => _perSecond * 60;
  double get _perHour => _perMinute * 60;
  double get _perDay => _monthlySalary / 30;

  double get _earnedThisMonth {
    if (_monthlySalary <= 0) return 0;
    final monthStart = DateTime(_now.year, _now.month, 1);
    final seconds = _now.difference(monthStart).inSeconds;
    return seconds * _perSecond;
  }

  double get _earnedToday {
    if (_monthlySalary <= 0) return 0;
    final dayStart = DateTime(_now.year, _now.month, _now.day);
    final seconds = _now.difference(dayStart).inSeconds;
    return seconds * _perSecond;
  }

  double get _activeModeEarned {
    if (_monthlySalary <= 0 || _modeStart == null) return 0;
    return _now.difference(_modeStart!).inSeconds * _perSecond;
  }

  double get _goalProgress {
    if (_goalAmount <= 0 || _earnedThisMonth <= 0) return 0;
    return (_earnedThisMonth / _goalAmount).clamp(0, 1);
  }

  int get _goalRemainingSeconds {
    if (_goalAmount <= 0 || _perSecond <= 0) return 0;
    final remaining = (_goalAmount - _earnedThisMonth).clamp(0, double.infinity);
    return (remaining / _perSecond).ceil();
  }

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _loadBannerAd();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: kBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isBannerAdReady = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _isBannerAdReady = false);
        },
      ),
    );
    _bannerAd!.load();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final salary = prefs.getDouble('monthlySalary') ?? 0;
    final goalName = prefs.getString('goalName') ?? '';
    final goalAmount = prefs.getDouble('goalAmount') ?? 0;

    setState(() {
      _monthlySalary = salary;
      _goalName = goalName;
      _goalAmount = goalAmount;
      if (salary > 0) _salaryController.text = salary.toStringAsFixed(0);
      if (goalName.isNotEmpty) _goalNameController.text = goalName;
      if (goalAmount > 0) _goalAmountController.text = goalAmount.toStringAsFixed(0);
    });
  }

  Future<void> _saveSalary() async {
    final raw = _salaryController.text.replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      _showSnack('Geçerli bir maaş gir kral.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlySalary', value);
    setState(() {
      _monthlySalary = value;
      _lastModeResult = null;
      _activeMode = null;
      _modeStart = null;
    });
    _showSnack('Maaş kaydedildi. Sayaç akmaya başladı 💰');
  }

  Future<void> _saveGoal() async {
    final name = _goalNameController.text.trim();
    final raw = _goalAmountController.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(raw);
    if (name.isEmpty) {
      _showSnack('Hedef adı gir. Örn: iPhone, tatil, PS5');
      return;
    }
    if (amount == null || amount <= 0) {
      _showSnack('Geçerli bir hedef tutarı gir.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('goalName', name);
    await prefs.setDouble('goalAmount', amount);
    setState(() {
      _goalName = name;
      _goalAmount = amount;
    });
    _showSnack('$name hedefi kaydedildi 🎯');
  }

  Future<void> _clearGoal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('goalName');
    await prefs.remove('goalAmount');
    setState(() {
      _goalName = '';
      _goalAmount = 0;
      _goalNameController.clear();
      _goalAmountController.clear();
    });
    _showSnack('Hedef temizlendi.');
  }

  void _startMode(ModeType mode) {
    if (_monthlySalary <= 0) {
      _showSnack('Önce aylık maaşını gir.');
      return;
    }
    setState(() {
      _activeMode = mode;
      _modeStart = DateTime.now();
      _lastModeResult = null;
    });
  }

  void _stopMode() {
    if (_activeMode == null || _modeStart == null) return;
    final amount = _activeModeEarned;
    final mode = _activeMode!;
    setState(() {
      _lastModeResult = '${mode.resultText} ${_money(amount)} kazandın 😄';
      _activeMode = null;
      _modeStart = null;
    });
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _money(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts[0];
    final decimal = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      final reverseIndex = whole.length - i;
      buffer.write(whole[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write('.');
    }
    return '₺${buffer.toString()},$decimal';
  }

  String _durationText(int totalSeconds) {
    if (totalSeconds <= 0) return 'Hedef tamamlandı kral 🎉';
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (days > 0) return '$days gün $hours saat $minutes dakika';
    if (hours > 0) return '$hours saat $minutes dakika';
    return '$minutes dakika';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _salaryController.dispose();
    _goalNameController.dispose();
    _goalAmountController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSalary = _monthlySalary > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Maaş Sayacı'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text('Maaşın çalışıyor. Sen ne yapıyorsun?', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  _salaryInputCard(),
                  const SizedBox(height: 18),
                  if (hasSalary) ...[
                    _bigCounterCard(),
                    const SizedBox(height: 12),
                    _statsGrid(),
                    const SizedBox(height: 18),
                    _goalCard(),
                    const SizedBox(height: 18),
                    _modeSection(),
                    const SizedBox(height: 18),
                    _funCard(),
                  ] else
                    const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Maaşını gir, sayaç 7/24 akmaya başlasın.', textAlign: TextAlign.center))),
                ],
              ),
            ),
            if (_isBannerAdReady && _bannerAd != null)
              Container(width: _bannerAd!.size.width.toDouble(), height: _bannerAd!.size.height.toDouble(), alignment: Alignment.center, child: AdWidget(ad: _bannerAd!)),
          ],
        ),
      ),
    );
  }

  Widget _salaryInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _salaryController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Aylık net maaş', hintText: 'Örn: 80000', prefixText: '₺ ', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _saveSalary, child: const Text('Kaydet ve Başlat'))),
          const SizedBox(height: 6),
          const Text('Hesaplama 30 gün üzerinden yapılır. Hafta sonu ve tatilde de sayaç akar.', textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _bigCounterCard() {
    return Card(
      color: const Color(0xFF12351F),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(children: [
          const Text('Bu ay şu ana kadar kazandın'),
          const SizedBox(height: 8),
          Text(_money(_earnedThisMonth), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Bugün: ${_money(_earnedToday)}'),
        ]),
      ),
    );
  }

  Widget _statsGrid() {
    return Column(children: [
      Row(children: [Expanded(child: _miniStat('Günlük', _money(_perDay))), const SizedBox(width: 8), Expanded(child: _miniStat('Saatlik', _money(_perHour)))]),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _miniStat('Dakikalık', _money(_perMinute))), const SizedBox(width: 8), Expanded(child: _miniStat('Saniyelik', _money(_perSecond)))]),
    ]);
  }

  Widget _miniStat(String title, String value) {
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [Text(title), const SizedBox(height: 6), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))])));
  }

  Widget _goalCard() {
    final hasGoal = _goalName.isNotEmpty && _goalAmount > 0;
    final progressPercent = (_goalProgress * 100).toStringAsFixed(1);
    return Card(
      color: const Color(0xFF172033),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('🎯 Maaş Hedefi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: _goalNameController, decoration: const InputDecoration(labelText: 'Hedef', hintText: 'PS5, iPhone, tatil...', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _goalAmountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tutar', hintText: '35000', prefixText: '₺ ', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 10),
          FilledButton.tonal(onPressed: _saveGoal, child: const Text('Hedefi Kaydet')),
          if (hasGoal) ...[
            const SizedBox(height: 14),
            Text('$_goalName hedefi için gereken süre:', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(_durationText(_goalRemainingSeconds), textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: _goalProgress),
            const SizedBox(height: 6),
            Text('%$progressPercent tamamlandı', textAlign: TextAlign.center),
            TextButton(onPressed: _clearGoal, child: const Text('Hedefi Temizle')),
          ],
        ]),
      ),
    );
  }

  Widget _modeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Eğlence Modları', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_activeMode != null) ...[
            Text('${_activeMode!.icon} ${_activeMode!.title} çalışıyor', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_money(_activeModeEarned), textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            FilledButton.tonal(onPressed: _stopMode, child: const Text('Durdur')),
          ] else ...[
            Wrap(spacing: 8, runSpacing: 8, children: ModeType.values.map((mode) => ActionChip(label: Text('${mode.icon} ${mode.title}'), onPressed: () => _startMode(mode))).toList()),
          ],
          if (_lastModeResult != null) ...[
            const SizedBox(height: 12),
            Text(_lastModeResult!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ]),
      ),
    );
  }

  Widget _funCard() {
    final passiveIncome = _earnedToday * 0.20;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Bugün hafta sonu, resmi tatil ya da boş gün olabilir. Ama sayaç yine çalışıyor: ${_money(_earnedToday)} 😄\n\nBu paranın %20’sini kenara atsaydın: ${_money(passiveIncome)} birikirdi.', textAlign: TextAlign.center),
      ),
    );
  }
}
