import 'package:flutter/material.dart';
import 'package:feedbacks/pallet.dart';
import 'package:feedbacks/services/application_service.dart';
import 'package:feedbacks/models/application.dart';
import 'package:feedbacks/services/api_service.dart';
import 'package:intl/intl.dart';

class AllApplicationsScreen extends StatefulWidget {
  const AllApplicationsScreen({super.key});

  @override
  State<AllApplicationsScreen> createState() =>
      _AllApplicationsScreenState();
}

class _AllApplicationsScreenState
    extends State<AllApplicationsScreen> {
  List<Application> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final apps = await ApplicationService.getAllApplications();
    if (mounted) {
      setState(() {
        _applications = apps;
        _isLoading = false;
      });
    }
  }

  List<Application> get _filtered {
    if (_searchQuery.isEmpty) return _applications;
    final q = _searchQuery.toLowerCase();
    return _applications
        .where((a) =>
            a.name.toLowerCase().contains(q) ||
            (a.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  String _fmt(DateTime d) =>
      DateFormat('dd/MM/yyyy HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de busca
        Container(
          color: surfaceColor,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar aplicações...',
                    hintStyle:
                        const TextStyle(color: textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: textMuted, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMd),
                      borderSide:
                          const BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMd),
                      borderSide:
                          const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusMd),
                      borderSide: const BorderSide(
                          color: primaryColor, width: 1.5),
                    ),
                    filled: true,
                    fillColor: surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  style: const TextStyle(
                      color: textPrimary, fontSize: 13),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                color: textMuted,
                onPressed: _loadApplications,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: borderColor),
        // Lista
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: primaryColor))
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: statusCancelled, size: 40),
                          const SizedBox(height: 12),
                          Text(_errorMessage!,
                              style: const TextStyle(
                                  color: textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadApplications,
                            child:
                                const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _searchQuery.isEmpty
                                    ? Icons.apps_rounded
                                    : Icons.search_off_rounded,
                                color: textMuted,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Nenhuma aplicação encontrada'
                                    : 'Sem resultados para "$_searchQuery"',
                                style: const TextStyle(
                                    color: textSecondary,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadApplications,
                          color: primaryColor,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final app = _filtered[i];
                              final isMine =
                                  app.createdBy ==
                                      ApiService.currentUserId;
                              return GestureDetector(
                                onTap: () =>
                                    _showDetails(app),
                                child: Container(
                                  padding:
                                      const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: surfaceColor,
                                    borderRadius:
                                        BorderRadius.circular(
                                            radiusMd),
                                    border: Border.all(
                                      color: isMine
                                          ? primaryColor
                                              .withOpacity(0.35)
                                          : borderColor,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isMine
                                              ? primaryColor
                                                  .withOpacity(0.12)
                                              : surfaceElevated,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  radiusS),
                                        ),
                                        child: Icon(
                                          Icons.apps_rounded,
                                          color: isMine
                                              ? primaryColor
                                              : textSecondary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    app.name,
                                                    style:
                                                        const TextStyle(
                                                      color:
                                                          textPrimary,
                                                      fontWeight:
                                                          FontWeight
                                                              .w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                if (isMine)
                                                  Container(
                                                    margin:
                                                        const EdgeInsets
                                                            .only(
                                                            left: 6),
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal:
                                                                6,
                                                            vertical:
                                                                2),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: primaryColor
                                                          .withOpacity(
                                                              0.15),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  4),
                                                    ),
                                                    child: const Text(
                                                      'Sua',
                                                      style: TextStyle(
                                                        color:
                                                            primaryColor,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight
                                                                .w600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (app.description !=
                                                    null &&
                                                app.description!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                app.description!,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                                style: const TextStyle(
                                                    color:
                                                        textSecondary,
                                                    fontSize: 12),
                                              ),
                                            ],
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons
                                                        .person_outline_rounded,
                                                    size: 11,
                                                    color: textMuted),
                                                const SizedBox(
                                                    width: 4),
                                                Text(
                                                  'Admin #${app.createdBy ?? '?'}',
                                                  style: const TextStyle(
                                                      color: textMuted,
                                                      fontSize: 11),
                                                ),
                                                const SizedBox(
                                                    width: 12),
                                                const Icon(
                                                    Icons
                                                        .calendar_today_rounded,
                                                    size: 10,
                                                    color: textMuted),
                                                const SizedBox(
                                                    width: 4),
                                                Text(
                                                  _fmt(app.createdAt),
                                                  style: const TextStyle(
                                                      color: textMuted,
                                                      fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                          Icons
                                              .chevron_right_rounded,
                                          color: textMuted,
                                          size: 18),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  void _showDetails(Application app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderColor),
        ),
        title: Row(
          children: [
            const Icon(Icons.apps_rounded,
                color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(app.name,
                  style: const TextStyle(
                      color: textPrimary, fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceElevated,
                borderRadius: BorderRadius.circular(radiusMd),
                border:
                    const BorderSide(color: borderColor).asBorderSide,
              ),
              child: Text(
                app.description ?? 'Sem descrição',
                style: const TextStyle(
                    color: textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            _row('ID', app.id.toString()),
            _row('Criado por', 'Admin #${app.createdBy ?? '?'}'),
            _row('Data', _fmt(app.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

extension on BorderSide {
  Border get asBorderSide => Border.all(color: color, width: width);
}
