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
      home: const DashboardPage(),
    );
  }
}

double parseMoney(String text) {
  final raw = text.trim().replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(raw) ?? 0;
}

String money(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0];
  final decimal = parts[1];
  final buffer = StringBuffer();
  for (int i = 0; i < whole.length; i++) {
    final reverseIndex = whole.length - i;
    buffer.write(whole[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write('.');
  }
  return '${negative ? '-' : ''}₺${buffer.toString()},$decimal';
}

String shortDuration(int totalSeconds) {
  if (totalSeconds <= 0) return 'Tamamlandı';
  final days = totalSeconds ~/ 86400;
  final hours = (totalSeconds % 86400) ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (days > 0) return '$days gün $hours saat';
  if (hours > 0) return '$hours saat $minutes dakika';
  return '$minutes dakika';
}

class BannerAdBox extends StatefulWidget {
  const BannerAdBox({super.key});

  @override
  State<BannerAdBox> createState() => _BannerAdBoxState();
}

class _BannerAdBoxState extends State<BannerAdBox> {
  BannerAd? _bannerAd;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: kBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _ready = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _ready = false);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _bannerAd == null) return const SizedBox.shrink();
    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final tools = [
      _Tool('💰', 'Maaş Sayacı', 'Maaşının ay boyunca nasıl aktığını canlı takip et.', const SalaryCounterPage()),
      _Tool('📈', 'Zam Hesabı', 'Zam oranına göre yeni maaşını hızlıca hesapla.', const RaiseCalculatorPage()),
      _Tool('⏱️', 'Fazla Mesai', 'Saatlik mesai ücretini ve toplam kazancını gör.', const OvertimeCalculatorPage()),
      _Tool('🏖️', 'İzin Hesabı', 'Çalışma yılına göre yıllık izin hakkını hesapla.', const LeaveCalculatorPage()),
      _Tool('💼', 'Kıdem Tazminatı', 'Tahmini kıdem tazminatını pratik şekilde gör.', const SeveranceCalculatorPage()),
      _Tool('📅', 'Maaş Günü', 'Maaşa kalan gün, saat ve dakikayı takip et.', const PaydayCountdownPage()),
      _Tool('🧾', 'Vergi Dilimi', 'Gelirine göre tahmini vergi dilimini öğren.', const TaxBracketPage()),
      _Tool('🎁', 'Prim Hesabı', 'Satış tutarı ve oranla prim kazancını hesapla.', const BonusCalculatorPage()),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF07130D),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF14532D),
                          Color(0xFF052E16),
                          Color(0xFF020617),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.35),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.10),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(.12)),
                              ),
                              child: const Text('💸', style: TextStyle(fontSize: 30)),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Maaş Asistanı',
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'V2 Çalışan Araçları',
                                    style: TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Maaş, zam, fazla mesai, izin, kıdem, vergi ve prim hesaplamaları tek uygulamada.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.84),
                            height: 1.35,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tools.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: .88,
                    ),
                    itemBuilder: (context, index) {
                      final tool = tools[index];
                      return _ToolCard(tool: tool, onTap: () => _open(context, tool.page));
                    },
                  ),
                ],
              ),
            ),
            const BannerAdBox(),
          ],
        ),
      ),
    );
  }
}

class _Tool {
  final String icon;
  final String title;
  final String subtitle;
  final Widget page;
  const _Tool(this.icon, this.title, this.subtitle, this.page);
}

class _ToolCard extends StatelessWidget {
  final _Tool tool;
  final VoidCallback onTap;
  const _ToolCard({required this.tool, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F1F17),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tool.icon, style: const TextStyle(fontSize: 34)),
              const Spacer(),
              Text(
                tool.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                tool.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(.68), height: 1.25),
              ),
              const SizedBox(height: 4),
              Icon(Icons.arrow_forward_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color? color;

  const ResultCard({super.key, required this.title, required this.value, this.subtitle, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color ?? const Color(0xFF12351F),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class AppInfoNote extends StatelessWidget {
  final String text;
  const AppInfoNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF172033),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class SalaryCounterPage extends StatefulWidget {
  const SalaryCounterPage({super.key});

  @override
  State<SalaryCounterPage> createState() => _SalaryCounterPageState();
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

class _SalaryCounterPageState extends State<SalaryCounterPage> {
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
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
    final value = parseMoney(_salaryController.text);
    if (value <= 0) {
      _showSnack('Geçerli bir maaş gir.');
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
    final amount = parseMoney(_goalAmountController.text);
    if (name.isEmpty) {
      _showSnack('Hedef adı gir. Örn: iPhone, tatil, PS5');
      return;
    }
    if (amount <= 0) {
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
      _lastModeResult = '${mode.resultText} ${money(amount)} kazandın 😄';
      _activeMode = null;
      _modeStart = null;
    });
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _durationText(int totalSeconds) {
    if (totalSeconds <= 0) return 'Hedef tamamlandı 🎉';
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
            const BannerAdBox(),
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
    return ResultCard(title: 'Bu ay şu ana kadar kazandın', value: money(_earnedThisMonth), subtitle: 'Bugün: ${money(_earnedToday)}');
  }

  Widget _statsGrid() {
    return Column(children: [
      Row(children: [Expanded(child: _miniStat('Günlük', money(_perDay))), const SizedBox(width: 8), Expanded(child: _miniStat('Saatlik', money(_perHour)))]),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _miniStat('Dakikalık', money(_perMinute))), const SizedBox(width: 8), Expanded(child: _miniStat('Saniyelik', money(_perSecond)))]),
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
            Text(money(_activeModeEarned), textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
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
        child: Text('Bugün hafta sonu, resmi tatil ya da boş gün olabilir. Ama sayaç yine çalışıyor: ${money(_earnedToday)} 😄\n\nBu paranın %20’sini kenara atsaydın: ${money(passiveIncome)} birikirdi.', textAlign: TextAlign.center),
      ),
    );
  }
}

class RaiseCalculatorPage extends StatefulWidget {
  const RaiseCalculatorPage({super.key});

  @override
  State<RaiseCalculatorPage> createState() => _RaiseCalculatorPageState();
}

class _RaiseCalculatorPageState extends State<RaiseCalculatorPage> {
  final salary = TextEditingController();
  final rate = TextEditingController();
  double? newSalary;
  double? increase;

  @override
  void dispose() {
    salary.dispose();
    rate.dispose();
    super.dispose();
  }

  void calculate() {
    final s = parseMoney(salary.text);
    final r = parseMoney(rate.text);
    if (s <= 0 || r < 0) return;
    setState(() {
      increase = s * r / 100;
      newSalary = s + increase!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: 'Zam Hesapla',
      children: [
        MoneyField(controller: salary, label: 'Mevcut maaş', hint: '40000'),
        PercentField(controller: rate, label: 'Zam oranı', hint: '25'),
        CalcButton(onPressed: calculate),
        if (newSalary != null) ...[
          ResultCard(title: 'Yeni maaş', value: money(newSalary!), subtitle: 'Maaş artışı: ${money(increase!)}'),
          _ScenarioCard(baseSalary: parseMoney(salary.text)),
        ],
      ],
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final double baseSalary;
  const _ScenarioCard({required this.baseSalary});

  @override
  Widget build(BuildContext context) {
    if (baseSalary <= 0) return const SizedBox.shrink();
    final rates = [10, 15, 20, 25, 30, 35, 40, 50];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Hızlı zam senaryoları', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...rates.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('%$r zam'),
                  Text(money(baseSalary * (1 + r / 100)), style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
              )),
        ]),
      ),
    );
  }
}

class OvertimeCalculatorPage extends StatefulWidget {
  const OvertimeCalculatorPage({super.key});

  @override
  State<OvertimeCalculatorPage> createState() => _OvertimeCalculatorPageState();
}

class _OvertimeCalculatorPageState extends State<OvertimeCalculatorPage> {
  final salary = TextEditingController();
  final hours = TextEditingController();
  double? hourly;
  double? overtime;

  @override
  void dispose() {
    salary.dispose();
    hours.dispose();
    super.dispose();
  }

  void calculate() {
    final s = parseMoney(salary.text);
    final h = parseMoney(hours.text);
    if (s <= 0 || h <= 0) return;
    final normalHourly = s / 225;
    setState(() {
      hourly = normalHourly * 1.5;
      overtime = hourly! * h;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: 'Fazla Mesai',
      children: [
        MoneyField(controller: salary, label: 'Aylık brüt / net maaş', hint: '40000'),
        NumberField(controller: hours, label: 'Fazla mesai saati', hint: '12'),
        CalcButton(onPressed: calculate),
        if (overtime != null)
          ResultCard(title: 'Tahmini fazla mesai', value: money(overtime!), subtitle: 'Saatlik mesai: ${money(hourly!)}\nHesaplama: aylık ücret / 225 saat x 1,5'),
        const AppInfoNote('Not: Fazla mesai hesapları çalışma düzeni, sözleşme ve mevzuata göre değişebilir. Bu sonuç bilgilendirme amaçlıdır.'),
      ],
    );
  }
}

class LeaveCalculatorPage extends StatefulWidget {
  const LeaveCalculatorPage({super.key});

  @override
  State<LeaveCalculatorPage> createState() => _LeaveCalculatorPageState();
}

class _LeaveCalculatorPageState extends State<LeaveCalculatorPage> {
  final startYear = TextEditingController();
  final usedDays = TextEditingController();
  int? total;
  int? remaining;
  int? years;

  @override
  void dispose() {
    startYear.dispose();
    usedDays.dispose();
    super.dispose();
  }

  void calculate() {
    final y = int.tryParse(startYear.text.trim()) ?? 0;
    final used = parseMoney(usedDays.text).round();
    final current = DateTime.now().year;
    if (y <= 1900 || y > current) return;
    final service = current - y;
    int days;
    if (service < 1) {
      days = 0;
    } else if (service <= 5) {
      days = 14;
    } else if (service < 15) {
      days = 20;
    } else {
      days = 26;
    }
    setState(() {
      years = service;
      total = days;
      remaining = (days - used).clamp(0, 365);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: 'İzin Hesabı',
      children: [
        NumberField(controller: startYear, label: 'İşe giriş yılı', hint: '2020'),
        NumberField(controller: usedDays, label: 'Bu yıl kullanılan izin', hint: '5'),
        CalcButton(onPressed: calculate),
        if (total != null)
          ResultCard(title: 'Tahmini yıllık izin', value: '$total gün', subtitle: 'Çalışma süresi: $years yıl\nKalan izin: $remaining gün'),
        const AppInfoNote('Not: Yaş, sektör, sözleşme ve özel çalışma koşulları izin hakkını değiştirebilir.'),
      ],
    );
  }
}

class SeveranceCalculatorPage extends StatefulWidget {
  const SeveranceCalculatorPage({super.key});

  @override
  State<SeveranceCalculatorPage> createState() => _SeveranceCalculatorPageState();
}

class _SeveranceCalculatorPageState extends State<SeveranceCalculatorPage> {
  final grossSalary = TextEditingController();
  final years = TextEditingController();
  final months = TextEditingController();
  double? result;

  @override
  void dispose() {
    grossSalary.dispose();
    years.dispose();
    months.dispose();
    super.dispose();
  }

  void calculate() {
    final salary = parseMoney(grossSalary.text);
    final y = parseMoney(years.text);
    final m = parseMoney(months.text);
    if (salary <= 0 || (y <= 0 && m <= 0)) return;
    setState(() {
      result = salary * (y + (m / 12));
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: 'Kıdem Tazminatı',
      children: [
        MoneyField(controller: grossSalary, label: 'Aylık brüt maaş', hint: '50000'),
        Row(children: [
          Expanded(child: NumberField(controller: years, label: 'Yıl', hint: '4')),
          const SizedBox(width: 8),
          Expanded(child: NumberField(controller: months, label: 'Ay', hint: '6')),
        ]),
        CalcButton(onPressed: calculate),
        if (result != null) ResultCard(title: 'Tahmini kıdem tazminatı', value: money(result!)),
        const AppInfoNote('Not: Kıdem tazminatında tavan tutar, damga vergisi ve hak kazanma şartları bulunur. Sonuç tahminidir.'),
      ],
    );
  }
}

class PaydayCountdownPage extends StatefulWidget {
  const PaydayCountdownPage({super.key});

  @override
  State<PaydayCountdownPage> createState() => _PaydayCountdownPageState();
}

class _PaydayCountdownPageState extends State<PaydayCountdownPage> {
  final dayController = TextEditingController();
  Timer? timer;
  DateTime now = DateTime.now();
  int payday = 1;

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('payday') ?? 1;
    setState(() {
      payday = saved;
      dayController.text = saved.toString();
    });
  }

  Future<void> save() async {
    final d = int.tryParse(dayController.text.trim()) ?? 1;
    final safe = d.clamp(1, 31);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('payday', safe);
    setState(() => payday = safe);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maaş günü kaydedildi.')));
    }
  }

  DateTime get nextPayday {
    final thisMonthLast = DateTime(now.year, now.month + 1, 0).day;
    var day = payday.clamp(1, thisMonthLast);
    var target = DateTime(now.year, now.month, day);
    if (!target.isAfter(now)) {
      final nextMonthLast = DateTime(now.year, now.month + 2, 0).day;
      day = payday.clamp(1, nextMonthLast);
      target = DateTime(now.year, now.month + 1, day);
    }
    return target;
  }

  @override
  void dispose() {
    timer?.cancel();
    dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = nextPayday.difference(now).inSeconds;
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return CalculatorScaffold(
      title: 'Maaş Günü',
      children: [
        NumberField(controller: dayController, label: 'Maaş günü', hint: '5'),
        FilledButton(onPressed: save, child: const Text('Kaydet')),
        ResultCard(title: 'Maaşa kalan süre', value: '$days gün', subtitle: '$hours saat $minutes dakika\nMaaş günü: Her ayın $payday. günü'),
      ],
    );
  }
}

class TaxBracketPage extends StatefulWidget {
  const TaxBracketPage({super.key});

  @override
  State<TaxBracketPage> createState() => _TaxBracketPageState();
}

class _TaxBracketPageState extends State<TaxBracketPage> {
  final monthlyGross = TextEditingController();
  final month = TextEditingController(text: DateTime.now().month.toString());
  String? bracket;
  double? annual;

  @override
  void dispose() {
    monthlyGross.dispose();
    month.dispose();
    super.dispose();
  }

  void calculate() {
    final gross = parseMoney(monthlyGross.text);
    final m = parseMoney(month.text).round().clamp(1, 12);
    if (gross <= 0) return;
    final cumulative = gross * m;
    String b;
    if (cumulative <= 110000) {
      b = '%15';
    } else if (cumulative <= 230000) {
      b = '%20';
    } else if (cumulative <= 870000) {
      b = '%27';
    } else if (cumulative <= 3000000) {
      b = '%35';
    } else {
      b = '%40';
    }
    setState(() {
      annual = cumulative;
      bracket = b;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: 'Vergi Dilimi',
      children: [
        MoneyField(controller: monthlyGross, label: 'Aylık brüt gelir', hint: '50000'),
        NumberField(controller: month, label: 'Kaçıncı ay', hint: '7'),
        CalcButton(onPressed: calculate),
        if (bracket != null)
          ResultCard(title: 'Tahmini vergi dilimi', value: bracket!, subtitle: 'Kümülatif gelir: ${money(annual!)}'),
        const AppInfoNote('Not: Vergi dilimleri yıllara göre değişebilir. Bu ekran basit tahmini takip içindir.'),
      ],
    );
  }
}

class BonusCalculatorPage extends StatefulWidget {
  const BonusCalculatorPage({super.key});

  @override
  State<BonusCalculatorPage> createState() => _BonusCalculatorPageState();
}

class _BonusCalculatorPageState extends State<BonusCalculatorPage> {
  final sales = TextEditingController();
  final rate = TextEditingController();
  double? bonus;

  @override
  void dispose() {
    sales.dispose();
    rate.dispose();
    super.dispose();
  }

  void calculate() {
    final s = parseMoney(sales.text);
    final r = parseMoney(rate.text);
    if (s <= 0 || r < 0) return;
    setState(() => bonus = s * r / 100);
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorScaffold(
      title: 'Prim Hesaplayıcı',
      children: [
        MoneyField(controller: sales, label: 'Satış / ciro tutarı', hint: '250000'),
        PercentField(controller: rate, label: 'Prim oranı', hint: '3'),
        CalcButton(onPressed: calculate),
        if (bonus != null) ResultCard(title: 'Tahmini prim', value: money(bonus!)),
      ],
    );
  }
}

class CalculatorScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const CalculatorScaffold({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  ...children.expand((w) => [w, const SizedBox(height: 12)]),
                ],
              ),
            ),
            const BannerAdBox(),
          ],
        ),
      ),
    );
  }
}

class MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const MoneyField({super.key, required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, hintText: hint, prefixText: '₺ ', border: const OutlineInputBorder()),
    );
  }
}

class PercentField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const PercentField({super.key, required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, hintText: hint, suffixText: '%', border: const OutlineInputBorder()),
    );
  }
}

class NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const NumberField({super.key, required this.controller, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
    );
  }
}

class CalcButton extends StatelessWidget {
  final VoidCallback onPressed;
  const CalcButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity, child: FilledButton(onPressed: onPressed, child: const Text('Hesapla')));
  }
}
