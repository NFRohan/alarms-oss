import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF4EDE1),
              Color(0xFFE8DDCF),
              Color(0xFFD8CAB5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text(
                'alarms-oss',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Android-first alarm engine, local-only storage, and a mission system built for extension.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF56483A),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              const _HeroStatusCard(),
              const SizedBox(height: 20),
              Text(
                'Sprint 1 focus',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const _MilestoneCard(
                title: 'Project bootstrap',
                detail:
                    'Flutter shell, Kotlin Android scaffold, and CI artifact builds are the first locked deliverables.',
                accent: Color(0xFFC85C3D),
              ),
              const SizedBox(height: 12),
              const _MilestoneCard(
                title: 'Architecture boundaries',
                detail:
                    'Alarm-critical behavior stays native. Flutter owns editing, presentation, and mission UI.',
                accent: Color(0xFF2B6A6C),
              ),
              const SizedBox(height: 12),
              const _MilestoneCard(
                title: 'Next implementation slice',
                detail:
                    'AlarmSpec, scheduling APIs, and ring-session ownership are the next core contracts.',
                accent: Color(0xFF6C4A8B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStatusCard extends StatelessWidget {
  const _HeroStatusCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: const Color(0xFF1C160F),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Foundation pass',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'The app shell is live. The alarm engine comes next.',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This screen is intentionally simple: it proves the Flutter shell while the native Android alarm engine remains the real execution core.',
              style: TextStyle(
                color: Color(0xFFE8DDCF),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.title,
    required this.detail,
    required this.accent,
  });

  final String title;
  final String detail;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: const Color(0xFFFFFBF4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF56483A),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
