import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:max_baza/car_entryy_model.dart';
import 'package:max_baza/edit_entry_page.dart';

class SearchPage extends StatefulWidget {
  final String searchQuery;
  final VoidCallback onClearSearch;
  final VoidCallback onExportToExcel;
  final VoidCallback onImportFromExcel;

  const SearchPage({
    super.key,
    required this.searchQuery,
    required this.onClearSearch,
    required this.onExportToExcel,
    required this.onImportFromExcel,
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
        case 1: // Company
          aValue = a.companyName.toLowerCase();
          bValue = b.companyName.toLowerCase();
          break;
        case 2: // Car Number
          aValue = a.carNumber.toLowerCase();
          bValue = b.carNumber.toLowerCase();
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
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.blue),
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

              if (widget.searchQuery.isNotEmpty) {
                entries = entries
                    .where(
                      (e) => e.carNumber.toLowerCase().contains(
                        widget.searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();
              }

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
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    showCheckboxColumn: false,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 50,
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Менший шрифт заголовків
                    ),
                    dataTextStyle: const TextStyle(
                      fontSize: 20, // Менший шрифт даних
                    ),
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      DataColumn(
                        label: const SizedBox(width: 92, child: Text('NAME')),
                        onSort: (columnIndex, ascending) =>
                            _sort((e) => e.name.toLowerCase(), columnIndex),
                      ),
                      DataColumn(
                        label: const SizedBox(
                          width: 70,
                          child: Text('COMPANY'),
                        ),
                        onSort: (columnIndex, ascending) => _sort(
                          (e) => e.companyName.toLowerCase(),
                          columnIndex,
                        ),
                      ),
                      DataColumn(
                        label: const SizedBox(
                          width: 70,
                          child: Text('CAR NUMBER'),
                        ),
                        onSort: (columnIndex, ascending) => _sort(
                          (e) => e.carNumber.toLowerCase(),
                          columnIndex,
                        ),
                      ),
                      DataColumn(
                        label: const SizedBox(
                          width: 70,
                          child: Text('CAR TYPE'),
                        ),
                        onSort: (columnIndex, ascending) =>
                            _sort((e) => e.carType.toLowerCase(), columnIndex),
                      ),
                      DataColumn(
                        label: const SizedBox(width: 92, child: Text('PHONE')),
                        onSort: (columnIndex, ascending) =>
                            _sort((e) => e.phoneNumber, columnIndex),
                      ),
                      DataColumn(
                        label: const SizedBox(
                          width: 30,
                          child: Text('COMMENT'),
                        ),
                        onSort: (columnIndex, ascending) =>
                            _sort((e) => e.comment.toLowerCase(), columnIndex),
                      ),
                      const DataColumn(
                        label: SizedBox(width: 92, child: Text('ACTIONS')),
                      ),
                    ],
                    rows: entries.map((entry) {
                      return DataRow(
                        onSelectChanged: (_) {
                          _showEntryDetails(entry);
                        },
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 70,
                              child: Text(
                                entry.name.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 70,
                              child: Text(
                                entry.companyName.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 70,
                              child: Text(
                                entry.carNumber.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 70,
                              child: Text(
                                entry.carType.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 70,
                              child: Text(
                                entry.phoneNumber.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 30,
                              child: Text(
                                entry.comment.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: 18, // Менші іконки
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
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 18, // Менші іконки
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
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
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
