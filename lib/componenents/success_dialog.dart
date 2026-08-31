import 'package:flutter/material.dart';




import '../routes/route_manager.dart';

class SuccessDialog {
  static void show(BuildContext context) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _SuccessDialogContent(
        onDismiss: () {
          overlayEntry?.remove();
        },
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }
}

class _SuccessDialogContent extends StatefulWidget {
  final VoidCallback onDismiss;

  const _SuccessDialogContent({required this.onDismiss});

  @override
  _SuccessDialogContentState createState() => _SuccessDialogContentState();
}

class _SuccessDialogContentState extends State<_SuccessDialogContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.6), // Darker semi-transparent background
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 200,
            maxWidth: 320,
          ),
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Patient Information saved successfully!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onDismiss();

                    RouteManager.redirectToHomeDashboard();
                    RouteManager.navigateToPatientRegistrationDashboard();
                    RouteManager.navigateToBagStatusDashboard();
                  },
                  style: ElevatedButton.styleFrom(

                    /*backgroundColor: Colors.green,
                    foregroundColor: Colors.white,*/
                    /*minimumSize: const Size( 48),*/
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}