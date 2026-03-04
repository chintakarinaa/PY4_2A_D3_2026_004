import 'package:flutter/material.dart';
import 'package:logbook_app_004/services/mongo_service.dart';
import '../auth/login_view.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'widgets/log_item_widget.dart';

class LogView extends StatefulWidget {
  final String username;

  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  late Future<void> _initialLoad;

  bool _isOffline = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = "Pribadi";
  String _searchQuery = "";

  final List<String> _categories = [
    "Pekerjaan",
    "Pribadi",
    "Urgent",
  ];

  @override
  void initState() {
    super.initState();
    _controller = LogController(widget.username);
    _initialLoad = _initApp();
  }

  Future<void> _initApp() async {
    try {
      await MongoService().connect();
      await _controller.fetchLogs();
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
    }
  }

  Future<void> _refresh() async {
    try {
      await MongoService().connect();
      await _controller.fetchLogs();
      if (mounted) {
        setState(() {
          _isOffline = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
      }
    }
  }

  void _confirmLogout() async {
    await MongoService().close();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  void _showAddDialog() {
    _titleController.clear();
    _descController.clear();
    _selectedCategory = "Pribadi";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Catatan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Judul"),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Deskripsi"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: _selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (value) {
                _selectedCategory = value!;
              },
              decoration: const InputDecoration(labelText: "Kategori"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              final desc = _descController.text.trim();

              if (title.isEmpty || desc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Judul dan deskripsi tidak boleh kosong"),
                    backgroundColor: Color.fromARGB(255, 137, 46, 255),
                  ),
                );
                return;
              }

              await _controller.addLog(title, desc, _selectedCategory);

              if (!mounted) return;

              Navigator.pop(context);
              await _refresh();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(LogModel log) {
    _titleController.text = log.title;
    _descController.text = log.description;
    _selectedCategory = log.category;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Catatan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController),
            TextField(controller: _descController),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: _selectedCategory,
              items: _categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (value) {
                _selectedCategory = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              final desc = _descController.text.trim();

              if (title.isEmpty || desc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Judul dan deskripsi tidak boleh kosong"),
                    backgroundColor: Color.fromARGB(255, 137, 46, 255),
                  ),
                );
                return;
              }

              await _controller.updateLogById(
                log.id!,
                title,
                desc,
                _selectedCategory,
              );

              if (!mounted) return;

              Navigator.pop(context);
              await _refresh();
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  List<LogModel> _applySearch(List<LogModel> logs) {
    if (_searchQuery.isEmpty) return logs;

    return logs.where((log) {
      return log.title.toLowerCase().contains(_searchQuery) ||
          log.description.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildOfflineView() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Column(
              children: [
                Icon(Icons.wifi_off, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text("Gagal terhubung ke Cloud."),
                SizedBox(height: 8),
                Text(
                  "Tarik ke bawah untuk mencoba lagi",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<LogModel> logs) {
    final filteredLogs = _applySearch(logs);

    if (filteredLogs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Icon(
              Icons.cloud_off,
              size: 90,
              color: Color.fromARGB(255, 104, 30, 184),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                "Belum ada catatan di Cloud.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 104, 30, 184),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredLogs.length,
        itemBuilder: (context, index) {
          final log = filteredLogs[index];

          return Dismissible(
            key: Key(log.id!.toHexString()),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) async {
              await _controller.deleteById(log.id!);
              await _refresh();
            },
            child: LogItemWidget(
              log: log,
              onEdit: () => _showEditDialog(log),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 104, 30, 184),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.arrow_back_ios, color: Colors.white),
              const Spacer(),
              const Text(
                "Logbook",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _confirmLogout,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 181, 143, 255),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Monitoring Aktivitas",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "Daftar Kegiatan Harian",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: const InputDecoration(
                hintText: "Cari catatan...",
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 177, 113, 255),
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<void>(
              future: _initialLoad,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          "Menghubungkan ke Cloud...",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          "Mengambil data...",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                if (_isOffline) {
                  return _buildOfflineView();
                }

                return ValueListenableBuilder<List<LogModel>>(
                  valueListenable: _controller.logsNotifier,
                  builder: (context, logs, _) {
                    return _buildList(logs);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}