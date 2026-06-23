import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../themes/app_theme.dart';
import '../../../data/models/operation_log_model.dart';
import '../../../data/repositories/operation_log_repository.dart';
import '../../widgets/whale_loading.dart';

class OperationLogsScreen extends StatefulWidget {
  const OperationLogsScreen({super.key});

  @override
  State<OperationLogsScreen> createState() => _OperationLogsScreenState();
}

class _OperationLogsScreenState extends State<OperationLogsScreen> {
  final OperationLogRepository _repository = OperationLogRepository();
  final List<OperationLogModel> _logs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  OperationLogPage? _lastPage;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() => _isLoading = true);
    }

    final page = await _repository.getLogs(
      startAfter: loadMore ? _lastPage?.lastDoc : null,
      limit: 20,
    );

    setState(() {
      if (loadMore) {
        _logs.addAll(page.logs);
      } else {
        _logs
          ..clear()
          ..addAll(page.logs);
      }
      _lastPage = page;
      _hasMore = page.logs.length == 20;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'سجل العمليات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: AppTheme.primary,
            ),
          ),
          backgroundColor: AppTheme.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? Center(child: WhaleLoading())
            : _logs.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد عمليات',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: AppTheme.secondary,
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return _buildLogCard(_logs[index]);
                      },
                    ),
                  ),
                  if (_hasMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoadingMore
                              ? null
                              : () => _loadLogs(loadMore: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.textLight,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoadingMore
                              ? WhaleLoading(
                                  size: 18,
                                  color: AppTheme.cardBackground,
                                )
                              : const Text(
                                  'تحميل المزيد',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildLogCard(OperationLogModel log) {
    final actionLabel = _actionLabel(log.action);
    final actionColor = _actionColor(log.action);
    final icon = _actionIcon(log.action);
    final createdAt = log.createdAt != null
        ? intl.DateFormat('yyyy-MM-dd HH:mm').format(log.createdAt!)
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: actionColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: actionColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$actionLabel - ${_entityTitle(log)}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'المستخدم: ${log.userEmail ?? 'النظام'}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'التاريخ: $createdAt',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppTheme.secondary,
                  ),
                ),
                if (log.details != null && log.details!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _detailsText(log.details!),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _entityTitle(OperationLogModel log) {
    if (log.entityName != null && log.entityName!.isNotEmpty) {
      return log.entityName!;
    }
    return log.entityType;
  }

  String _detailsText(Map<String, dynamic> details) {
    final parts = details.entries.map((e) => '${e.key}: ${e.value}');
    final text = parts.join(' | ');
    return text.length > 140 ? '${text.substring(0, 140)}...' : text;
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'create':
        return 'إضافة';
      case 'update':
        return 'تعديل';
      case 'delete':
        return 'حذف';
      default:
        return 'عملية';
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      default:
        return AppTheme.primary;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }
}
