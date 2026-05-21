import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/banner_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/support_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _service = SupportService();
  List<SupportTicketModel> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    final tickets = await _service.getUserTickets(uid);
    if (mounted) {
      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    }
  }

  void _createTicket() {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final auth = context.read<AuthProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Support Ticket',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            CustomTextField(
              controller: subjectCtrl,
              label: 'Subject',
              hint: 'What is your issue?',
              prefixIcon: Icons.subject_rounded,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe your issue in detail...',
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Submit Ticket',
              onPressed: () async {
                if (subjectCtrl.text.isEmpty || messageCtrl.text.isEmpty) {
                  return;
                }
                final ticketId = await _service.createTicket(
                  userId: auth.user!.uid,
                  userName: auth.user!.name,
                  subject: subjectCtrl.text,
                  firstMessage: messageCtrl.text,
                );
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(ctx);
                await _loadTickets();
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                context.push('/support/$ticketId');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Customer Support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTicket,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Ticket',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.support_agent_outlined,
                          size: 64, color: AppColors.textHint),
                      SizedBox(height: 16),
                      Text('No support tickets',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      Text('Create a ticket to get help',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTickets,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _TicketCard(ticket: _tickets[i]),
                  ),
                ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicketModel ticket;
  const _TicketCard({required this.ticket});

  Color get _statusColor {
    switch (ticket.status) {
      case 'open':
        return AppColors.primary;
      case 'in_progress':
        return AppColors.warning;
      case 'closed':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/support/${ticket.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'Last reply: ${DateFormat('dd MMM, HH:mm').format(ticket.lastReply)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
