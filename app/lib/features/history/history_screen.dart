import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../domain/donation.dart';
import '../../domain/live_session.dart';
import '../../features/live/live_screen.dart' show formatDuration;
import '../../state/providers.dart';
import '../../widgets/donation_tile.dart';

/// All-time donations (straight from the Stripe API, paginated) and the
/// locally recorded session archive.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Donations'),
              Tab(text: 'Sessions'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DonationsTab(),
            _SessionsTab(),
          ],
        ),
      ),
    );
  }
}

class _DonationsTab extends ConsumerStatefulWidget {
  const _DonationsTab();

  @override
  ConsumerState<_DonationsTab> createState() => _DonationsTabState();
}

class _DonationsTabState extends ConsumerState<_DonationsTab> {
  final List<Donation> _donations = [];
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 300) _loadMore();
    });
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_loading) return;
    final requests = ref.read(stripeRequestsProvider);
    final jar = ref.read(appStateProvider).effectiveTipJar;
    if (requests == null || jar == null || jar.isDemo) return;

    setState(() {
      _loading = true;
      if (reset) {
        _donations.clear();
        _hasMore = true;
        _error = null;
      }
    });
    try {
      if (!_hasMore) return;
      final page = await requests.listDonations(
        paymentLinkId: jar.paymentLinkId,
        startingAfter: _donations.isEmpty ? null : _donations.last.id,
      );
      if (!mounted) return;
      setState(() {
        _donations.addAll(page.donations);
        _hasMore = page.hasMore;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);
    final theme = Theme.of(context);

    if (app.demo) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Demo mode has no Stripe history.\nConnect your account to see '
            'every donation you\'ve ever received.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_error != null && _donations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _loadMore(reset: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_donations.isEmpty && !_loading) {
      return const Center(
        child: Text('No donations yet — they\'ll all show up here.'),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadMore(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _donations.length + (_hasMore || _loading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _donations.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5)),
            );
          }
          return DonationTile(donation: _donations[index]);
        },
      ),
    );
  }
}

class _SessionsTab extends ConsumerWidget {
  const _SessionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessions = ref
        .read(localStoreProvider)
        .readSessionHistory()
        .reversed
        .toList();

    if (sessions.isEmpty) {
      return const Center(
        child: Text('No sessions yet — hit “Start live session” on stage!'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final started = session.startedAt;
        final date =
            '${started.year}-${started.month.toString().padLeft(2, '0')}-${started.day.toString().padLeft(2, '0')}';
        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(
              formatAmount(session.totalMinor, session.currency),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            subtitle: Text(
              '$date · ${session.count} tips · ${formatDuration(session.elapsed(session.endedAt))} · '
              'goal ${(session.progress * 100).round()}%'
              '${session.goalReached ? ' 🎉' : ''}',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showSessionDetail(context, session),
          ),
        );
      },
    );
  }

  void _showSessionDetail(BuildContext context, LiveSession session) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    formatAmount(session.totalMinor, session.currency),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.count} tips · '
                    '${formatDuration(session.elapsed(session.endedAt))}'
                    '${session.goalReached ? ' · goal reached 🎉' : ''}',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: session.donations.isEmpty
                  ? const Center(child: Text('No tips in this session.'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: session.donations.length,
                      itemBuilder: (context, index) => DonationTile(
                        donation: session
                            .donations[session.donations.length - 1 - index],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
