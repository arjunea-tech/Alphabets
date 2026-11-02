import 'package:flutter/material.dart';
import '../../services/progress_service.dart';
import 'aytham_screen.dart';

class UyirmeiScreen extends StatelessWidget {
  final ProgressService progressService;

  const UyirmeiScreen({super.key, required this.progressService});

  @override
  Widget build(BuildContext context) {
    return AythamScreen(progressService: progressService);
  }
}
