import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';

class AttendancePopup extends StatefulWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onDismiss;

  const AttendancePopup({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  @override
  State<AttendancePopup> createState() => _AttendancePopupState();
}

class _AttendancePopupState extends State<AttendancePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAction(String action) async {
    await _controller.reverse();
    
    final courseId = widget.notification['courseId'] as int;

    final scheduleId = widget.notification['scheduleId'] as int;
    final now = DateTime.now();

    switch (action) {
      case 'attended':
        await DatabaseService.instance.addAttendanceRecord(
          courseId, 
          now, 
          isPresent: true
        );
        break;
      case 'skipped':
        await DatabaseService.instance.addAttendanceRecord(
          courseId, 
          now, 
          isPresent: false
        );
        break;
      case 'canceled':
        // Don't record attendance
        break;
    }

    // Remove from pending notifications
    await NotificationService().removePendingNotification(scheduleId);
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with course icon and name
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          Icons.school,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attend ${widget.notification['courseName']} Class Now!',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mark your attendance for this class',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await _controller.reverse();
                          widget.onDismiss();
                        },
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Attended',
                          icon: Icons.check_circle,
                          color: Colors.green,
                          onPressed: () => _handleAction('attended'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'Skipped',
                          icon: Icons.cancel,
                          color: Colors.orange,
                          onPressed: () => _handleAction('skipped'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'Canceled',
                          icon: Icons.event_busy,
                          color: Colors.red,
                          onPressed: () => _handleAction('canceled'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendancePopupOverlay extends StatefulWidget {
  const AttendancePopupOverlay({super.key});

  static OverlayEntry? _currentOverlay;

  static void show(BuildContext context, Map<String, dynamic> notification) {
    hide(); // Hide any existing overlay
    
    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: AttendancePopup(
            notification: notification,
            onDismiss: hide,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  @override
  State<AttendancePopupOverlay> createState() => _AttendancePopupOverlayState();
}

class _AttendancePopupOverlayState extends State<AttendancePopupOverlay> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}