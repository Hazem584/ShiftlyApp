import 'package:flutter/material.dart';

import 'employee_performance_screen_state.dart';

class EmployeePerformanceScreen extends StatefulWidget {
  const EmployeePerformanceScreen({required this.membershipId, super.key});
  final String membershipId;
  @override
  State<EmployeePerformanceScreen> createState() =>
      EmployeePerformanceScreenState();
}
