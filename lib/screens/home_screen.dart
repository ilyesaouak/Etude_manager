import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/services.dart';
import '../models/models.dart';
import 'students_screen.dart';
import 'groups_screen.dart';
import 'sessions_screen.dart';
import 'payments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<_DashboardTabState> _dashboardKey =
      GlobalKey<_DashboardTabState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardTab(key: _dashboardKey),
      const StudentsScreen(),
      const GroupsScreen(),
      const SessionsScreen(),
      const PaymentsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            elevation: 0,
            backgroundColor: Colors.transparent,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              // Refresh dashboard when returning to it
              if (index == 0) {
                _dashboardKey.currentState?.loadDashboardData();
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Tableau de bord',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_rounded),
                label: 'Étudiants',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_rounded),
                label: 'Groupes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.event_note_rounded),
                label: 'Séances',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payment_rounded),
                label: 'Paiements',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _totalStudents = 0;
  int _totalGroups = 0;
  int _totalSessions = 0;
  int _pendingPayments = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      final studentProvider =
          Provider.of<StudentProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final sessionProvider =
          Provider.of<SessionProvider>(context, listen: false);

      // Load all data
      await Future.wait([
        studentProvider.loadStudents(),
        groupProvider.loadGroups(),
        sessionProvider.loadSessions(),
      ]);

      // Count pending payments
      int pendingCount = 0;
      for (final student in studentProvider.students) {
        final shouldPay = await studentProvider.shouldStudentPay(student.id!);
        if (shouldPay) pendingCount++;
      }

      setState(() {
        _totalStudents = studentProvider.students.length;
        _totalGroups = groupProvider.groups.length;
        _totalSessions = sessionProvider.sessions.length;
        _pendingPayments = pendingCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return RefreshIndicator(
      onRefresh: loadDashboardData,
      color: Theme.of(context).colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 32 : 20,
                    20,
                    isTablet ? 32 : 20,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gérez vos cours particuliers efficacement',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content Section
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(64.0),
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: EdgeInsets.all(isTablet ? 32 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsOverview(isTablet),
                    const SizedBox(height: 32),
                    _buildQuickActions(isTablet),
                    if (_pendingPayments > 0) ...[
                      const SizedBox(height: 32),
                      _buildPaymentReminders(),
                    ],
                    const SizedBox(height: 32),
                    _buildNotificationControls(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = isTablet ? 4 : 2;
            final childAspectRatio = isTablet ? 1.2 : 1.1;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
              children: [
                _buildStatCard(
                  'Étudiants',
                  _totalStudents.toString(),
                  Icons.people_rounded,
                  const Color(0xFF2563EB),
                ),
                _buildStatCard(
                  'Groupes',
                  _totalGroups.toString(),
                  Icons.groups_rounded,
                  const Color(0xFF059669),
                ),
                _buildStatCard(
                  'Séances',
                  _totalSessions.toString(),
                  Icons.event_note_rounded,
                  const Color(0xFFD97706),
                ),
                _buildStatCard(
                  'Paiements dus',
                  _pendingPayments.toString(),
                  Icons.payment_rounded,
                  _pendingPayments > 0
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF6B7280),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = isTablet ? 4 : 2;
            final childAspectRatio = isTablet ? 1.3 : 1.2;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
              children: [
                _buildQuickActionCard(
                  'Ajouter Étudiant',
                  Icons.person_add_rounded,
                  const Color(0xFF2563EB),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentsScreen()),
                  ),
                ),
                _buildQuickActionCard(
                  'Créer Groupe',
                  Icons.group_add_rounded,
                  const Color(0xFF059669),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GroupsScreen()),
                  ),
                ),
                _buildQuickActionCard(
                  'Nouvelle Séance',
                  Icons.event_note_rounded,
                  const Color(0xFFD97706),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SessionsScreen()),
                  ),
                ),
                _buildQuickActionCard(
                  'Voir Paiements',
                  Icons.payment_rounded,
                  const Color(0xFF7C3AED),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentReminders() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD97706).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rappels de paiement',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFD97706),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$_pendingPayments étudiant${_pendingPayments == 1 ? '' : 's'} ${_pendingPayments == 1 ? 'a' : 'ont'} des paiements en attente.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                ),
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Voir Paiements'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationControls() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBF4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2563EB).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Gérez les rappels automatiques de paiement.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendTestNotification,
                    icon: const Icon(Icons.notification_add_rounded),
                    label: const Text('Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkPaymentReminders,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Vérifier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      await notificationService.sendTestNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification de test envoyée!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkPaymentReminders() async {
    try {
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      await notificationService.checkAndSendPaymentReminders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vérification des rappels de paiement effectuée!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
