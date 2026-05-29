import 'package:flutter/material.dart';

import 'calculators/well_control.dart';

void main() {
  runApp(const DrillCalcApp());
}

class DrillCalcApp extends StatelessWidget {
  const DrillCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF006C60);
    const fieldSurface = Color(0xFFF4F6F2);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DrillCalc Field',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: fieldSurface,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF1D2522),
          displayColor: const Color(0xFF1D2522),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: scheme.primary, width: 1.4),
          ),
        ),
      ),
      home: const WellControlScreen(),
    );
  }
}

class WellControlScreen extends StatefulWidget {
  const WellControlScreen({super.key});

  @override
  State<WellControlScreen> createState() => _WellControlScreenState();
}

class _WellControlScreenState extends State<WellControlScreen> {
  final _defaults = WellControlInputs.sample();
  late final Map<_FieldId, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in _fieldDefinitions)
        field.id: TextEditingController(text: field.value(_defaults)),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _resetSample() {
    setState(() {
      for (final field in _fieldDefinitions) {
        _controllers[field.id]!.text = field.value(_defaults);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputs = _readInputs();
    final calculator = WellControlCalculator(inputs);
    final kill = calculator.killSheet();
    final kick = calculator.kickTolerance();
    final influx = calculator.influxAnalysis();
    final volumetric = calculator.volumetricMethod();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF1EC), Color(0xFFF7F7F3)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 920;
            final content = wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 380,
                        child: _Reveal(
                          child: _InputPanel(
                            controllers: _controllers,
                            onChanged: () => setState(() {}),
                            onReset: _resetSample,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _Reveal(
                          offset: const Offset(0, 18),
                          child: _ResultsPanel(
                            kill: kill,
                            kick: kick,
                            influx: influx,
                            volumetric: volumetric,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Reveal(
                        child: _InputPanel(
                          controllers: _controllers,
                          onChanged: () => setState(() {}),
                          onReset: _resetSample,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Reveal(
                        offset: const Offset(0, 16),
                        child: _ResultsPanel(
                          kill: kill,
                          kick: kick,
                          influx: influx,
                          volumetric: volumetric,
                        ),
                      ),
                    ],
                  );

            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 24 : 16,
                      18,
                      wide ? 24 : 16,
                      28,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: content,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  WellControlInputs _readInputs() {
    double read(_FieldId id) {
      final value = double.tryParse(_controllers[id]!.text.trim());
      return value ??
          _fieldDefinitions
              .firstWhere((field) => field.id == id)
              .rawValue(_defaults);
    }

    return WellControlInputs(
      holeSizeIn: read(_FieldId.holeSizeIn),
      casingIdIn: read(_FieldId.casingIdIn),
      currentMudWeightPpg: read(_FieldId.currentMudWeightPpg),
      holeMdFt: read(_FieldId.holeMdFt),
      holeTvdFt: read(_FieldId.holeTvdFt),
      casingShoeMdFt: read(_FieldId.casingShoeMdFt),
      casingShoeTvdFt: read(_FieldId.casingShoeTvdFt),
      sidppPsi: read(_FieldId.sidppPsi),
      sicpPsi: read(_FieldId.sicpPsi),
      influxAnalysisSicpPsi: read(_FieldId.influxAnalysisSicpPsi),
      pitGainBbl: read(_FieldId.pitGainBbl),
      lotFitEmwPpg: read(_FieldId.lotFitEmwPpg),
      mudWeightDuringFitPpg: read(_FieldId.mudWeightDuringFitPpg),
      drillPipeOdIn: read(_FieldId.drillPipeOdIn),
      drillCollarOdIn: read(_FieldId.drillCollarOdIn),
      drillCollarLengthFt: read(_FieldId.drillCollarLengthFt),
      slowCirculatingPressurePsi: read(_FieldId.slowCirculatingPressurePsi),
      surfaceToBitStrokes: read(_FieldId.surfaceToBitStrokes),
      gasGradientPsiPerFt: read(_FieldId.gasGradientPsiPerFt),
      safetyMarginPsi: read(_FieldId.safetyMarginPsi),
      pressureIncrementPsi: read(_FieldId.pressureIncrementPsi),
    );
  }
}

class _InputPanel extends StatelessWidget {
  const _InputPanel({
    required this.controllers,
    required this.onChanged,
    required this.onReset,
  });

  final Map<_FieldId, TextEditingController> controllers;
  final VoidCallback onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(Icons.oil_barrel, color: colors.onPrimary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DrillCalc Field',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text('Workbook-based well control'),
                  ],
                ),
              ),
              _Pressable(
                child: IconButton.filledTonal(
                  onPressed: onReset,
                  tooltip: 'Reset sample values',
                  icon: const Icon(Icons.restart_alt),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InputBadge(
              icon: Icons.fact_check_outlined,
              label: 'Excel source',
              foreground: colors.primary,
              background: colors.primaryContainer.withValues(alpha: 0.5),
            ),
            _InputBadge(
              icon: Icons.speed,
              label: 'Live results',
              foreground: const Color(0xFF6D4C00),
              background: const Color(0xFFFFF0C2),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Notice(
          icon: Icons.verified_user_outlined,
          text:
              'Engineering draft. Verify results against approved company procedures before field use.',
          tone: _NoticeTone.warning,
        ),
        const SizedBox(height: 16),
        _Reveal(
          offset: const Offset(0, 10),
          child: _SectionCard(
            title: 'Well Data',
            icon: Icons.vertical_align_bottom,
            children: _fieldsFor(_FieldGroup.well)
                .map(
                  (field) => _NumberInput(
                    definition: field,
                    controller: controllers[field.id]!,
                    onChanged: onChanged,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _Reveal(
          offset: const Offset(0, 10),
          child: _SectionCard(
            title: 'Kick Data',
            icon: Icons.warning_amber,
            children: _fieldsFor(_FieldGroup.kick)
                .map(
                  (field) => _NumberInput(
                    definition: field,
                    controller: controllers[field.id]!,
                    onChanged: onChanged,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        _Reveal(
          offset: const Offset(0, 10),
          child: _SectionCard(
            title: 'String, Pump, Safety',
            icon: Icons.tune,
            children: _fieldsFor(_FieldGroup.stringPump)
                .map(
                  (field) => _NumberInput(
                    definition: field,
                    controller: controllers[field.id]!,
                    onChanged: onChanged,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({
    required this.kill,
    required this.kick,
    required this.influx,
    required this.volumetric,
  });

  final KillSheetResult kill;
  final KickToleranceResult kick;
  final InfluxAnalysisResult influx;
  final VolumetricMethodResult volumetric;

  @override
  Widget build(BuildContext context) {
    final urgent = !influx.canCirculateSafely || !volumetric.hasOperatingWindow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusHeader(urgent: urgent, influx: influx),
        const SizedBox(height: 12),
        _MetricGrid(
          metrics: [
            _Metric(
              'Kill mud',
              _fmt(kill.killMudWeightPpg, 2),
              'ppg',
              Icons.opacity,
            ),
            _Metric(
              'ICP',
              _fmt(kill.initialCirculatingPressurePsi, 0),
              'psi',
              Icons.speed,
            ),
            _Metric(
              'FCP',
              _fmt(kill.finalCirculatingPressurePsi, 0),
              'psi',
              Icons.trending_down,
            ),
            _Metric(
              'MAASP',
              _fmt(kick.maaspPsi, 0),
              'psi',
              Icons.shield_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Kill Sheet',
          icon: Icons.fact_check_outlined,
          children: [
            _ResultRow(
              'Formation pressure',
              _fmt(kill.formationPressurePsi, 0),
              'psi',
            ),
            _ResultRow(
              'Present hydrostatic',
              _fmt(kill.presentHydrostaticPsi, 0),
              'psi',
            ),
            _ResultRow(
              'Kill mud weight',
              _fmt(kill.killMudWeightPpg, 2),
              'ppg',
            ),
            _ResultRow('Kill mud weight', _fmt(kill.killMudWeightSg, 2), 'sg'),
            _ResultRow('Pressure drop', _fmt(kill.pressureDropPsi, 0), 'psi'),
            _ResultRow(
              'Drop per 100 strokes',
              _fmt(kill.dropPerHundredStrokesPsi, 1),
              'psi',
            ),
            const SizedBox(height: 8),
            _PressureSchedule(steps: kill.pressureSchedule.take(7).toList()),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Kick Tolerance',
          icon: Icons.compress,
          children: [
            _ResultRow(
              'Fracture pressure at shoe',
              _fmt(kick.fracturePressureAtShoePsi, 0),
              'psi',
            ),
            _ResultRow(
              'Hydrostatic at shoe',
              _fmt(kick.hydrostaticAtShoePsi, 0),
              'psi',
            ),
            _ResultRow(
              'Max influx height',
              _fmtNullable(kick.maxInfluxHeightFt, 0),
              'ft',
            ),
            _ResultRow(
              'KT around DP',
              _fmtNullable(kick.kickToleranceAroundDpBbl, 1),
              'bbl',
            ),
            _ResultRow(
              'KT mixed DC/DP',
              _fmtNullable(kick.kickToleranceMixedBbl, 1),
              'bbl',
            ),
            _ResultRow(
              'Max kill MW without influx',
              _fmt(kick.maxKillMudWeightNoInfluxPpg, 2),
              'ppg',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Influx Analysis',
          icon: Icons.bubble_chart_outlined,
          children: [
            _Notice(
              icon: influx.canCirculateSafely
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              text: influx.canCirculateSafely
                  ? 'SICP is below MAASP for current inputs.'
                  : 'SICP exceeds MAASP. Treat as a critical review condition.',
              tone: influx.canCirculateSafely
                  ? _NoticeTone.ok
                  : _NoticeTone.danger,
            ),
            const SizedBox(height: 8),
            _ResultRow('Influx type', influx.influxType, ''),
            _ResultRow('Influx height', _fmt(influx.influxHeightFt, 0), 'ft'),
            _ResultRow(
              'Influx gradient',
              _fmt(influx.influxGradientPsiPerFt, 3),
              'psi/ft',
            ),
            _ResultRow(
              'Influx density',
              _fmt(influx.influxDensityPpg, 2),
              'ppg',
            ),
            _ResultRow(
              'MW increase required',
              _fmt(influx.mudWeightIncreaseRequiredPpg, 2),
              'ppg',
            ),
            _ResultRow('Action', influx.recommendedAction, ''),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Volumetric Method',
          icon: Icons.water_drop_outlined,
          children: [
            _Notice(
              icon: volumetric.hasOperatingWindow
                  ? Icons.check_circle_outline
                  : Icons.report_problem_outlined,
              text: volumetric.hasOperatingWindow
                  ? 'Operating window exists before max allowable SICP.'
                  : 'No safe pressure window with current margin and increment.',
              tone: volumetric.hasOperatingWindow
                  ? _NoticeTone.ok
                  : _NoticeTone.danger,
            ),
            const SizedBox(height: 8),
            _ResultRow(
              'Max allowable SICP',
              _fmt(volumetric.maxAllowableSicpPsi, 0),
              'psi',
            ),
            _ResultRow(
              'Next bleed start',
              _fmt(volumetric.nextBleedStartPressurePsi, 0),
              'psi',
            ),
            _ResultRow(
              'First bleed target',
              _fmt(volumetric.firstBleedTargetPsi, 0),
              'psi',
            ),
            _ResultRow(
              'Bleed volume per step, OH',
              _fmt(volumetric.volumeToBleedOpenHoleBbl, 1),
              'bbl',
            ),
            _ResultRow(
              'Bleed volume per step, CH',
              _fmt(volumetric.volumeToBleedCasedHoleBbl, 1),
              'bbl',
            ),
          ],
        ),
      ],
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, this.offset = const Offset(0, 12)});

  final Widget child;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: offset * (1 - value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child});

  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _InputBadge extends StatelessWidget {
  const _InputBadge({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.foreground});

  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.urgent, required this.influx});

  final bool urgent;
  final InfluxAnalysisResult influx;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = urgent ? colors.errorContainer : colors.primaryContainer;
    final foreground = urgent
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: foreground.withValues(alpha: urgent ? 0.10 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              urgent ? Icons.priority_high : Icons.task_alt,
              color: foreground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        urgent
                            ? 'Critical review required'
                            : 'Inputs within draft envelope',
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(
                      label: urgent ? 'Review' : 'OK',
                      foreground: foreground,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    '${influx.influxType}. ${influx.recommendedAction}',
                    key: ValueKey(
                      '${influx.influxType}-${influx.recommendedAction}',
                    ),
                    style: TextStyle(color: foreground, height: 1.25),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        final spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _MetricTile(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Pressable(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(metric.icon, size: 18, color: colors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AnimatedValueText(
                    value: metric.value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  if (metric.unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(metric.unit),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedValueText extends StatelessWidget {
  const _AnimatedValueText({
    required this.value,
    required this.style,
    this.textAlign,
  });

  final String value;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        value,
        key: ValueKey(value),
        textAlign: textAlign,
        style: style,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.52),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.definition,
    required this.controller,
    required this.onChanged,
  });

  final _FieldDefinition definition;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontWeight: FontWeight.w700),
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: definition.label,
            suffixText: definition.unit,
            suffixStyle: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
            prefixIcon: Icon(definition.icon, color: colors.primary),
            isDense: true,
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value, this.unit);

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: _AnimatedValueText(
                value: unit.isEmpty ? value : '$value $unit',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PressureSchedule extends StatelessWidget {
  const _PressureSchedule({required this.steps});

  final List<PressureStep> steps;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Strokes',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Pressure',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final (index, step) in steps.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: index.isEven
                      ? colors.surface.withValues(alpha: 0.58)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('${step.strokes}')),
                    Text(
                      '${_fmt(step.pressurePsi, 0)} psi',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.tone});

  final IconData icon;
  final String text;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color background;
    final Color foreground;

    switch (tone) {
      case _NoticeTone.ok:
        background = const Color(0xFFE4F4EC);
        foreground = const Color(0xFF164B35);
      case _NoticeTone.warning:
        background = const Color(0xFFFFF4D6);
        foreground = const Color(0xFF5A4100);
      case _NoticeTone.danger:
        background = colors.errorContainer;
        foreground = colors.onErrorContainer;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: foreground, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}

enum _NoticeTone { ok, warning, danger }

class _Metric {
  const _Metric(this.label, this.value, this.unit, this.icon);

  final String label;
  final String value;
  final String unit;
  final IconData icon;
}

enum _FieldGroup { well, kick, stringPump }

enum _FieldId {
  holeSizeIn,
  casingIdIn,
  currentMudWeightPpg,
  holeMdFt,
  holeTvdFt,
  casingShoeMdFt,
  casingShoeTvdFt,
  sidppPsi,
  sicpPsi,
  influxAnalysisSicpPsi,
  pitGainBbl,
  lotFitEmwPpg,
  mudWeightDuringFitPpg,
  drillPipeOdIn,
  drillCollarOdIn,
  drillCollarLengthFt,
  slowCirculatingPressurePsi,
  surfaceToBitStrokes,
  gasGradientPsiPerFt,
  safetyMarginPsi,
  pressureIncrementPsi,
}

class _FieldDefinition {
  const _FieldDefinition({
    required this.id,
    required this.group,
    required this.label,
    required this.unit,
    required this.icon,
    required this.rawValue,
    this.displayFractionDigits,
  });

  final _FieldId id;
  final _FieldGroup group;
  final String label;
  final String unit;
  final IconData icon;
  final double Function(WellControlInputs inputs) rawValue;
  final int? displayFractionDigits;

  String value(WellControlInputs inputs) {
    final number = rawValue(inputs);
    if (displayFractionDigits != null) {
      return number.toStringAsFixed(displayFractionDigits!);
    }
    if (number == number.roundToDouble()) {
      return number.toStringAsFixed(0);
    }
    return number.toString();
  }
}

List<_FieldDefinition> _fieldsFor(_FieldGroup group) {
  return _fieldDefinitions.where((field) => field.group == group).toList();
}

final _fieldDefinitions = [
  _FieldDefinition(
    id: _FieldId.holeSizeIn,
    group: _FieldGroup.well,
    label: 'Hole size',
    unit: 'in',
    icon: Icons.radio_button_unchecked,
    rawValue: (inputs) => inputs.holeSizeIn,
  ),
  _FieldDefinition(
    id: _FieldId.casingIdIn,
    group: _FieldGroup.well,
    label: 'Casing ID',
    unit: 'in',
    icon: Icons.adjust,
    rawValue: (inputs) => inputs.casingIdIn,
  ),
  _FieldDefinition(
    id: _FieldId.currentMudWeightPpg,
    group: _FieldGroup.well,
    label: 'Current mud weight',
    unit: 'ppg',
    icon: Icons.opacity,
    rawValue: (inputs) => inputs.currentMudWeightPpg,
  ),
  _FieldDefinition(
    id: _FieldId.holeMdFt,
    group: _FieldGroup.well,
    label: 'Hole MD',
    unit: 'ft',
    icon: Icons.straighten,
    rawValue: (inputs) => inputs.holeMdFt,
  ),
  _FieldDefinition(
    id: _FieldId.holeTvdFt,
    group: _FieldGroup.well,
    label: 'Hole TVD',
    unit: 'ft',
    icon: Icons.height,
    rawValue: (inputs) => inputs.holeTvdFt,
  ),
  _FieldDefinition(
    id: _FieldId.casingShoeMdFt,
    group: _FieldGroup.well,
    label: 'Casing shoe MD',
    unit: 'ft',
    icon: Icons.south,
    rawValue: (inputs) => inputs.casingShoeMdFt,
  ),
  _FieldDefinition(
    id: _FieldId.casingShoeTvdFt,
    group: _FieldGroup.well,
    label: 'Casing shoe TVD',
    unit: 'ft',
    icon: Icons.vertical_align_bottom,
    rawValue: (inputs) => inputs.casingShoeTvdFt,
  ),
  _FieldDefinition(
    id: _FieldId.sidppPsi,
    group: _FieldGroup.kick,
    label: 'SIDPP',
    unit: 'psi',
    icon: Icons.speed,
    rawValue: (inputs) => inputs.sidppPsi,
  ),
  _FieldDefinition(
    id: _FieldId.sicpPsi,
    group: _FieldGroup.kick,
    label: 'SICP',
    unit: 'psi',
    icon: Icons.speed_outlined,
    rawValue: (inputs) => inputs.sicpPsi,
  ),
  _FieldDefinition(
    id: _FieldId.influxAnalysisSicpPsi,
    group: _FieldGroup.kick,
    label: 'Influx analysis SICP',
    unit: 'psi',
    icon: Icons.speed_outlined,
    rawValue: (inputs) => inputs.influxAnalysisSicpPsi,
  ),
  _FieldDefinition(
    id: _FieldId.pitGainBbl,
    group: _FieldGroup.kick,
    label: 'Pit gain',
    unit: 'bbl',
    icon: Icons.add_chart,
    rawValue: (inputs) => inputs.pitGainBbl,
  ),
  _FieldDefinition(
    id: _FieldId.lotFitEmwPpg,
    group: _FieldGroup.kick,
    label: 'LOT/FIT EMW',
    unit: 'ppg',
    icon: Icons.shield_outlined,
    rawValue: (inputs) => inputs.lotFitEmwPpg,
  ),
  _FieldDefinition(
    id: _FieldId.mudWeightDuringFitPpg,
    group: _FieldGroup.kick,
    label: 'MW during LOT/FIT',
    unit: 'ppg',
    icon: Icons.science_outlined,
    rawValue: (inputs) => inputs.mudWeightDuringFitPpg,
  ),
  _FieldDefinition(
    id: _FieldId.drillPipeOdIn,
    group: _FieldGroup.stringPump,
    label: 'Drill pipe OD',
    unit: 'in',
    icon: Icons.linear_scale,
    rawValue: (inputs) => inputs.drillPipeOdIn,
  ),
  _FieldDefinition(
    id: _FieldId.drillCollarOdIn,
    group: _FieldGroup.stringPump,
    label: 'Drill collar OD',
    unit: 'in',
    icon: Icons.linear_scale,
    rawValue: (inputs) => inputs.drillCollarOdIn,
  ),
  _FieldDefinition(
    id: _FieldId.drillCollarLengthFt,
    group: _FieldGroup.stringPump,
    label: 'Drill collar length',
    unit: 'ft',
    icon: Icons.straighten,
    rawValue: (inputs) => inputs.drillCollarLengthFt,
  ),
  _FieldDefinition(
    id: _FieldId.slowCirculatingPressurePsi,
    group: _FieldGroup.stringPump,
    label: 'Slow circulating pressure',
    unit: 'psi',
    icon: Icons.compress,
    rawValue: (inputs) => inputs.slowCirculatingPressurePsi,
  ),
  _FieldDefinition(
    id: _FieldId.surfaceToBitStrokes,
    group: _FieldGroup.stringPump,
    label: 'Pump strokes',
    unit: 'stk',
    icon: Icons.av_timer,
    rawValue: (inputs) => inputs.surfaceToBitStrokes,
    displayFractionDigits: 0,
  ),
  _FieldDefinition(
    id: _FieldId.gasGradientPsiPerFt,
    group: _FieldGroup.stringPump,
    label: 'Assumed gas gradient',
    unit: 'psi/ft',
    icon: Icons.bubble_chart_outlined,
    rawValue: (inputs) => inputs.gasGradientPsiPerFt,
  ),
  _FieldDefinition(
    id: _FieldId.safetyMarginPsi,
    group: _FieldGroup.stringPump,
    label: 'Safety margin',
    unit: 'psi',
    icon: Icons.health_and_safety_outlined,
    rawValue: (inputs) => inputs.safetyMarginPsi,
  ),
  _FieldDefinition(
    id: _FieldId.pressureIncrementPsi,
    group: _FieldGroup.stringPump,
    label: 'Pressure increment',
    unit: 'psi',
    icon: Icons.exposure_plus_1,
    rawValue: (inputs) => inputs.pressureIncrementPsi,
  ),
];

String _fmt(double value, int fractionDigits) {
  if (value.isNaN || value.isInfinite) {
    return 'ERR';
  }
  return value.toStringAsFixed(fractionDigits);
}

String _fmtNullable(double? value, int fractionDigits) {
  if (value == null) {
    return 'ERR';
  }
  return _fmt(value, fractionDigits);
}
