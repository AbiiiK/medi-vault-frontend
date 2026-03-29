import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../models/record_model.dart';

class SharedRecordsScreen extends StatefulWidget {
  const SharedRecordsScreen({super.key});

  @override
  State<SharedRecordsScreen> createState() => _SharedRecordsScreenState();
}

class _SharedRecordsScreenState extends State<SharedRecordsScreen> {
  List<Map<String, dynamic>> _patientData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSharedRecords();
  }

  Future<void> _loadSharedRecords() async {
    setState(() => _isLoading = true);
    final response = await ApiService.get(Constants.sharedWithMe);
    if (response['success'] == true) {
      setState(() {
        _patientData = List<Map<String, dynamic>>.from(response['data']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'lab_report': return const Color(0xFF185FA5);
      case 'prescription': return const Color(0xFF0F6E56);
      case 'radiology': return const Color(0xFF854F0B);
      case 'discharge_summary': return const Color(0xFF993C1D);
      default: return Colors.grey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'lab_report': return Icons.science;
      case 'prescription': return Icons.medication;
      case 'radiology': return Icons.image_search;
      case 'discharge_summary': return Icons.assignment;
      default: return Icons.description;
    }
  }

  Future<void> _logDownload(String recordId, String title) async {
    await ApiService.post('${Constants.records}/$recordId/download', {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download logged for: $title'),
        backgroundColor: const Color(0xFF0F6E56),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Records'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patientData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No records shared with you yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSharedRecords,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _patientData.length,
                    itemBuilder: (context, index) {
                      final item = _patientData[index];
                      final patient = item['patient'];
                      final records = (item['records'] as List)
                          .map((r) => RecordModel.fromJson(r))
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8,
                              top: 8,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Color(0xFF185FA5),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Patient ID: ${patient['_id'].toString().substring(0, 8)}...',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF185FA5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF185FA5)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${records.length} records',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF185FA5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...records.map((record) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _categoryColor(record.category)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _categoryIcon(record.category),
                                    color: _categoryColor(record.category),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  record.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${record.categoryDisplay} · ${record.uploadDate.day}/${record.uploadDate.month}/${record.uploadDate.year}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.download_outlined,
                                    color: Color(0xFF185FA5),
                                  ),
                                  onPressed: () =>
                                      _logDownload(record.id, record.title),
                                ),
                              ),
                            );
                          }),
                          const Divider(),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}