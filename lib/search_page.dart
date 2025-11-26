import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:max_baza/car_entryy_model.dart';
import 'package:max_baza/edit_entry_page.dart';

class SearchPage extends StatefulWidget {
  final String searchQuery;
  final VoidCallback onClearSearch;
  final VoidCallback onExportToExcel;
  final VoidCallback onImportFromExcel;
  final bool isLandscape;

  const SearchPage({
    super.key,
    required this.searchQuery,
    required this.onClearSearch,
    required this.onExportToExcel,
    required this.onImportFromExcel,
    this.isLandscape = false,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  void _sort<T>(
    Comparable<T> Function(CarEntry entry) getField,
    int columnIndex,
  ) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
    });
  }

  List<CarEntry> _sortEntries(List<CarEntry> entries) {
    if (_sortColumnIndex == null) return entries;

    entries.sort((a, b) {
      Comparable aValue;
      Comparable bValue;

      switch (_sortColumnIndex) {
        case 0: // Name
          aValue = a.name.toLowerCase();
          bValue = b.name.toLowerCase();
          break;
        case 1: // Car Number
          aValue = a.carNumber.toLowerCase();
          bValue = b.carNumber.toLowerCase();
          break;
        case 2: // Company
          aValue = a.companyName.toLowerCase();
          bValue = b.companyName.toLowerCase();
          break;
        case 3: // Car Type
          aValue = a.carType.toLowerCase();
          bValue = b.carType.toLowerCase();
          break;
        case 4: // Phone
          aValue = a.phoneNumber;
          bValue = b.phoneNumber;
          break;
        case 5: // Comment
          aValue = a.comment.toLowerCase();
          bValue = b.comment.toLowerCase();
          break;
        default:
          return 0;
      }

      return _sortAscending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });

    return entries;
  }

  // Функція для фільтрації записів по всіх полях
  List<CarEntry> _filterEntries(List<CarEntry> entries, String query) {
    if (query.isEmpty) return entries;

    final lowerQuery = query.toLowerCase();

    return entries.where((entry) {
      return entry.carNumber.toLowerCase().contains(lowerQuery) ||
          entry.name.toLowerCase().contains(lowerQuery) ||
          entry.companyName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Function to show entry details
  void _showEntryDetails(CarEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('DETAILS - ${entry.carNumber.toUpperCase()}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('NAME:', entry.name.toUpperCase()),
              _buildDetailRow('COMPANY:', entry.companyName.toUpperCase()),
              _buildDetailRow('CAR NUMBER:', entry.carNumber.toUpperCase()),
              _buildDetailRow('CAR TYPE:', entry.carType.toUpperCase()),
              _buildDetailRow('PHONE:', entry.phoneNumber.toUpperCase()),
              _buildDetailRow('COMMENT:', entry.comment.toUpperCase()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditEntryPage(entry: entry),
                ),
              );
            },
            child: const Text('EDIT'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'NOT SPECIFIED',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.searchQuery.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SEARCH: ${widget.searchQuery.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: widget.onClearSearch,
                ),
              ],
            ),
          ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: Hive.box<CarEntry>('cars').listenable(),
            builder: (context, Box<CarEntry> box, _) {
              var entries = box.values.toList();

              // Використовуємо нову функцію фільтрації по всіх полях
              entries = _filterEntries(entries, widget.searchQuery);
              entries = _sortEntries(entries);

              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.searchQuery.isEmpty
                            ? 'NO RECORDS'
                            : 'NO RESULTS FOUND',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (widget.searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Searching in: car number, name, company',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                );
              }

              // Компактні розміри для таблиці
              final double headingFontSize = widget.isLandscape ? 10 : 12;
              final double dataFontSize = widget.isLandscape ? 10 : 11;
              final double rowHeight = widget.isLandscape ? 40 : 45;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    showCheckboxColumn: false,
                    dataRowMinHeight: rowHeight,
                    dataRowMaxHeight: rowHeight,
                    headingRowHeight: 40,
                    horizontalMargin: 8,
                    columnSpacing: 4,
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: headingFontSize,
                      color: Colors.white,
                    ),
                    dataTextStyle: TextStyle(
                      fontSize: dataFontSize,
                      fontWeight: FontWeight.w400,
                    ),
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: 70,
                          child: Text('NAME', overflow: TextOverflow.ellipsis),
                        ),
                        onSort: (columnIndex, ascending) =>
                            _sort((e) => e.name.toLowerCase(), columnIndex),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 80,
                          child: Text(
                            'CAR NUMBER',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onSort: (columnIndex, ascending) => _sort(
                          (e) => e.carNumber.toLowerCase(),
                          columnIndex,
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 70,
                          child: Text(
                            'COMPANY',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onSort: (columnIndex, ascending) => _sort(
                          (e) => e.companyName.toLowerCase(),
                          columnIndex,
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 60,
                          child: Text('TYPE', overflow: TextOverflow.ellipsis),
                        ),
                        onSort: (columnIndex, ascending) =>
                            _sort((e) => e.carType.toLowerCase(), columnIndex),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 80,
                          child: Text('PHONE', overflow: TextOverflow.ellipsis),
                        ),
                        onSort: (columnIndex, ascending) =>
                            _sort((e) => e.phoneNumber, columnIndex),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 90,
                          child: Text(
                            'COMMENT',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onSort: (columnIndex, ascending) =>
                            _sort((e) => e.comment.toLowerCase(), columnIndex),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 70,
                          child: Text(
                            'ACTIONS',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    rows: entries.asMap().entries.map((entryWithIndex) {
                      final index = entryWithIndex.key;
                      final entry = entryWithIndex.value;

                      // Альтернуючі кольори для рядків
                      final bool isEven = index % 2 == 0;
                      final Color rowColor = isEven
                          ? Colors.grey.shade900.withOpacity(0.3)
                          : Colors.grey.shade800.withOpacity(0.2);

                      return DataRow(
                        color: WidgetStateProperty.resolveWith<Color>((
                          Set<WidgetState> states,
                        ) {
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.blueGrey.withOpacity(0.3);
                          }
                          return rowColor;
                        }),
                        onSelectChanged: (_) {
                          _showEntryDetails(entry);
                        },
                        cells: [
                          DataCell(
                            Tooltip(
                              message: entry.name.toUpperCase(),
                              child: Text(
                                entry.name.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: dataFontSize),
                              ),
                            ),
                          ),
                          DataCell(
                            Tooltip(
                              message: entry.carNumber.toUpperCase(),
                              child: Text(
                                entry.carNumber.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: dataFontSize),
                              ),
                            ),
                          ),
                          DataCell(
                            Tooltip(
                              message: entry.companyName.toUpperCase(),
                              child: Text(
                                entry.companyName.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: dataFontSize),
                              ),
                            ),
                          ),
                          DataCell(
                            Tooltip(
                              message: entry.carType.toUpperCase(),
                              child: Text(
                                entry.carType.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: dataFontSize),
                              ),
                            ),
                          ),
                          DataCell(
                            Tooltip(
                              message: entry.phoneNumber.toUpperCase(),
                              child: Text(
                                entry.phoneNumber.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: dataFontSize),
                              ),
                            ),
                          ),
                          DataCell(
                            Tooltip(
                              message: entry.comment.toUpperCase(),
                              child: Text(
                                entry.comment.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(fontSize: dataFontSize),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.blue.shade300,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditEntryPage(entry: entry),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red.shade300,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('DELETE RECORD?'),
                                        content: Text(
                                          'DELETE RECORD FOR ${entry.carNumber.toUpperCase()}?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('CANCEL'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              entry.delete();
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('DELETE'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
