import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logbook_app_004/services/mongo_service.dart';
import 'package:logbook_app_004/features/logbook/log_editor_page.dart';
import 'package:logbook_app_004/features/logbook/widgets/log_item_widget.dart';
import '../auth/login_view.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'package:logbook_app_004/services/access_control_service.dart';

class LogView extends StatefulWidget {
  final dynamic currentUser;

  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  late Future<void> _initialLoad;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _controller = LogController(widget.currentUser);
    _initialLoad = _initApp();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });

    _connectivity.onConnectivityChanged.listen((result) async {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });

      if (_isOnline) {
        await _controller.syncLogs();
      }
    });
  }

  Future<void> _initApp() async {
    await MongoService().connect();
    await _controller.loadLogs(widget.currentUser['teamId']);
  }

  Future<void> _refresh() async {
    await _controller.loadLogs(widget.currentUser['teamId']);
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

  void _goToEditor({LogModel? log}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
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

  List<LogModel> _applyVisibility(List<LogModel> logs) {
    final currentUserId = widget.currentUser['uid'];

    return logs.where((log) {
      return log.authorId == currentUserId || log.isPublic == true;
    }).toList();
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 160),
          const Icon(
            Icons.note_alt_outlined,
            size: 90,
            color: Color.fromARGB(255, 104, 30, 184),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Belum ada catatan.",
              style: TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 104, 30, 184),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed: () => _goToEditor(),
              child: const Text("Buat Catatan Pertama"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<LogModel> logs) {
    final visibleLogs = _applyVisibility(logs);
    final filteredLogs = _applySearch(visibleLogs);

    if (filteredLogs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredLogs.length,
        itemBuilder: (context, index) {
          final log = filteredLogs[index];
          final bool isOwner = log.authorId == widget.currentUser['uid'];

          final bool canEdit = isOwner;
          final bool canDelete = isOwner;

          return Dismissible(
            key: Key(log.id ?? index.toString()),
            direction:
                canDelete ? DismissDirection.endToStart : DismissDirection.none,
            background: Container(
              color: const Color.fromARGB(255, 189, 127, 255),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              if (log.id != null) {
                _controller.removeLog(log.id!);
              }
            },
            child: LogItemWidget(
              log: log,
              onEdit: canEdit ? () => _goToEditor(log: log) : null,
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
              const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
              Row(
                children: [
                  Icon(
                    _isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color:
                        _isOnline ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _confirmLogout,
                  ),
                ],
              )
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
            decoration: const BoxDecoration(color: Colors.white),
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 177, 113, 255),
        foregroundColor: Colors.white,
        onPressed: () => _goToEditor(),
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