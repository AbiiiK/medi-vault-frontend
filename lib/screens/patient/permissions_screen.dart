import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  List<dynamic> _permissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    final response = await ApiService.get(Constants.myDoctors);
    if (response['success'] == true) {
      setState(() {
        _permissions = response['permissions'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeAccess(String permissionId, String doctorName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text(
          'Are you sure you want to revoke access for $doctorName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await ApiService.put(
        '${Constants.permissions}/revoke/$permissionId',
        {},
      );
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access revoked successfully'),
            backgroundColor: Color(0xFF0F6E56),
          ),
        );
        _loadPermissions();
      }
    }
  }

  Future<void> _showGrantDialog() async {
    final providerIdController = TextEditingController();
    String selectedScope = 'all';
    String selectedCategory = 'lab_report';

    final List<Map<String, String>> categories = [
      {'value': 'lab_report', 'label': 'Lab Report'},
      {'value': 'prescription', 'label': 'Prescription'},
      {'value': 'radiology', 'label': 'Radiology'},
      {'value': 'discharge_summary', 'label': 'Discharge Summary'},
      {'value': 'other', 'label': 'Other'},
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grant Doctor Access',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: providerIdController,
                decoration: const InputDecoration(
                  labelText: 'Doctor User ID',
                  prefixIcon: Icon(Icons.person_search),
                  hintText: 'Enter the doctor\'s user ID',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Access Scope',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('All records'),
                    value: 'all',
                    groupValue: selectedScope,
                    activeColor: const Color(0xFF0F6E56),
                    onChanged: (value) =>
                        setModalState(() => selectedScope = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('By category'),
                    value: 'category',
                    groupValue: selectedScope,
                    activeColor: const Color(0xFF0F6E56),
                    onChanged: (value) =>
                        setModalState(() => selectedScope = value!),
                  ),
                ],
              ),
              if (selectedScope == 'category') ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat['value'],
                      child: Text(cat['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setModalState(() => selectedCategory = value);
                    }
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (providerIdController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a doctor ID'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final body = {
                    'provider_user_id': providerIdController.text.trim(),
                    'scope_type': selectedScope,
                    if (selectedScope == 'category')
                      'shared_category': selectedCategory,
                  };

                  final response = await ApiService.post(
                    Constants.grantPermission,
                    body,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  if (response['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Access granted successfully'),
                        backgroundColor: Color(0xFF0F6E56),
                      ),
                    );
                    _loadPermissions();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          response['message'] ?? 'Failed to grant access',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Grant Access'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Access'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _permissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No doctors have access yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to grant a doctor access',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPermissions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _permissions.length,
                    itemBuilder: (context, index) {
                      final permission = _permissions[index];
                      final provider = permission['provider_id'];
                      final user = provider?['user_id'];
                      final doctorName = user != null
                          ? '${user['first_name']} ${user['last_name']}'
                          : 'Unknown Doctor';
                      final email = user?['email'] ?? '';
                      final scope = permission['scope_type'] ?? 'all';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF0F6E56).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.medical_services,
                              color: Color(0xFF0F6E56),
                            ),
                          ),
                          title: Text(
                            doctorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(email),
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F6E56)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  scope == 'all'
                                      ? 'Full access'
                                      : scope == 'category'
                                          ? 'Category: ${permission['shared_category'] ?? ''}'
                                          : 'Specific record',
                                  style: const TextStyle(
                                    color: Color(0xFF0F6E56),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _revokeAccess(
                              permission['_id'],
                              doctorName,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGrantDialog,
        backgroundColor: const Color(0xFF0F6E56),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}