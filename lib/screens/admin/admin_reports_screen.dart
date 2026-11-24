import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../../services/admin_service.dart';
import '../../services/alert_service.dart';

enum _ReportRangePreset { today, last7Days, last30Days, custom }

class AdminReportsScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdminReportsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  _ReportRangePreset _preset = _ReportRangePreset.last30Days;
  late DateTime _startDate;
  late DateTime _endDate;
  late Future<AdminReportData> _reportFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 29));
    _reportFuture = AdminService.getReportData(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _selectPreset(_ReportRangePreset preset) async {
    final now = DateTime.now();
    if (preset == _ReportRangePreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2023),
        lastDate: now.add(const Duration(days: 365)),
        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      );
      if (picked == null) return;
      setState(() {
        _preset = _ReportRangePreset.custom;
        _startDate = picked.start;
        _endDate = picked.end;
        _reload();
      });
      return;
    }

    setState(() {
      _preset = preset;
      _endDate = now;
      switch (preset) {
        case _ReportRangePreset.today:
          _startDate = DateTime(now.year, now.month, now.day);
          break;
        case _ReportRangePreset.last7Days:
          _startDate = now.subtract(const Duration(days: 6));
          break;
        case _ReportRangePreset.last30Days:
          _startDate = now.subtract(const Duration(days: 29));
          break;
        case _ReportRangePreset.custom:
          break;
      }
      _reload();
    });
  }

  void _reload() {
    _reportFuture = AdminService.getReportData(
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _exportCsv(AdminReportData data) async {
    final csv = AdminService.buildReportCsv(data);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;

    AlertService.showSuccessToast(
      context,
      'Reporte CSV copiado al portapapeles',
    );

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vista previa CSV'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
      child: FutureBuilder<AdminReportData>(
        future: _reportFuture,
        builder: (context, snapshot) {
          final report = snapshot.data;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Reportes y Analítica'),
              actions: [
                if (report != null)
                  IconButton(
                    tooltip: 'Exportar CSV',
                    icon: const Icon(Icons.download_outlined),
                    onPressed: () => _exportCsv(report),
                  ),
                IconButton(
                  tooltip: 'Actualizar',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(_reload),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.analytics_outlined), text: 'Resumen'),
                  Tab(icon: Icon(Icons.calendar_month), text: 'Citas'),
                  Tab(icon: Icon(Icons.people_outline), text: 'Usuarios'),
                ],
              ),
            ),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Hoy'),
                              selected: _preset == _ReportRangePreset.today,
                              onSelected: (_) =>
                                  _selectPreset(_ReportRangePreset.today),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('7 días'),
                              selected: _preset == _ReportRangePreset.last7Days,
                              onSelected: (_) =>
                                  _selectPreset(_ReportRangePreset.last7Days),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('30 días'),
                              selected:
                                  _preset == _ReportRangePreset.last30Days,
                              onSelected: (_) =>
                                  _selectPreset(_ReportRangePreset.last30Days),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Personalizado'),
                              selected: _preset == _ReportRangePreset.custom,
                              onSelected: (_) =>
                                  _selectPreset(_ReportRangePreset.custom),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Periodo: ${df.format(_startDate)} — ${df.format(_endDate)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : snapshot.hasError
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'Error cargando reportes:\n${snapshot.error}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : TabBarView(
                              children: [
                                _buildSummaryTab(report!),
                                _buildAppointmentsTab(report),
                                _buildUsersTab(report),
                              ],
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryTab(AdminReportData report) {
    final resolutionRate = report.totalTicketsInPeriod == 0
        ? 0
        : ((report.resolvedTickets / report.totalTicketsInPeriod) * 100)
            .round();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _buildKpiCard(
              'Nuevos usuarios',
              '${report.newUsersInPeriod}',
              '${report.newDoctorsInPeriod} médicos',
              Icons.person_add_alt_1,
              Colors.blue,
            ),
            _buildKpiCard(
              'Citas en periodo',
              '${report.appointmentsInPeriod}',
              '${report.appointmentsBySpecialty.length} especialidades',
              Icons.event_available,
              Colors.green,
            ),
            _buildKpiCard(
              'Tickets soporte',
              '${report.totalTicketsInPeriod}',
              '${report.openTickets + report.inProgressTickets} pendientes',
              Icons.support_agent,
              Colors.orange,
            ),
            _buildKpiCard(
              'Tasa resolución',
              '$resolutionRate%',
              '${report.resolvedTickets} resueltos',
              Icons.task_alt,
              Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: 'Distribución de Roles',
          child: Column(
            children: [
              _buildBarRow(
                'Pacientes',
                report.patientsCount,
                report.totalUsers,
                Colors.blue,
              ),
              _buildBarRow(
                'Médicos',
                report.doctorsCount,
                report.totalUsers,
                Colors.orange,
              ),
              _buildBarRow(
                'Administradores',
                report.adminsCount,
                report.totalUsers,
                Colors.red,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Estado de Soporte en el Periodo',
          child: Column(
            children: [
              _buildBarRow(
                'Abiertos',
                report.openTickets,
                report.totalTicketsInPeriod,
                Colors.red,
              ),
              _buildBarRow(
                'En progreso',
                report.inProgressTickets,
                report.totalTicketsInPeriod,
                Colors.orange,
              ),
              _buildBarRow(
                'Resueltos',
                report.resolvedTickets,
                report.totalTicketsInPeriod,
                Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsTab(AdminReportData report) {
    final specialties = report.appointmentsBySpecialty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final doctors = report.appointmentsByDoctor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Citas por Especialidad',
          child: specialties.isEmpty
              ? const Text(
                  'No hay citas registradas en el periodo seleccionado.',
                  style: TextStyle(color: Colors.grey),
                )
              : Column(
                  children: specialties
                      .map(
                        (e) => _buildBarRow(
                          e.key,
                          e.value,
                          report.appointmentsInPeriod,
                          Colors.teal,
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Médicos con más citas',
          child: doctors.isEmpty
              ? const Text(
                  'Sin actividad de médicos en este rango.',
                  style: TextStyle(color: Colors.grey),
                )
              : Column(
                  children: doctors
                      .take(10)
                      .map(
                        (e) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.medical_services_outlined,
                            color: Colors.orange,
                          ),
                          title: Text(e.key),
                          trailing: Chip(
                            label: Text('${e.value} citas'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildUsersTab(AdminReportData report) {
    final df = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Estado de Cuentas y Ficha Médica',
          child: Column(
            children: [
              _buildBarRow(
                'Cuentas activas',
                report.activeUsers,
                report.totalUsers,
                Colors.green,
              ),
              _buildBarRow(
                'Cuentas suspendidas',
                report.suspendedUsers,
                report.totalUsers,
                Colors.grey,
              ),
              const SizedBox(height: 8),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                ),
                title: const Text('Pacientes sin ficha médica completa'),
                trailing: Text(
                  '${report.usersWithoutMedicalData}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Altas recientes en el periodo',
          child: report.recentUsers.isEmpty
              ? const Text(
                  'No hubo registros nuevos en este periodo.',
                  style: TextStyle(color: Colors.grey),
                )
              : Column(
                  children: report.recentUsers.take(15).map((u) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text(
                          u.fullName.isNotEmpty
                              ? u.fullName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(u.fullName),
                      subtitle: Text(
                        '${u.email} • ${df.format(u.createdAt)}',
                      ),
                      trailing: Text(
                        u.role == UserRole.doctor
                            ? 'MÉDICO'
                            : u.role == UserRole.admin
                                ? 'ADMIN'
                                : 'PACIENTE',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBarRow(String label, int count, int total, Color color) {
    final ratio = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
              Text(
                '$count',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
