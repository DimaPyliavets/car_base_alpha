import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:max_baza/add_entry_page.dart';
import 'package:max_baza/car_entryy_model.dart';
import 'package:max_baza/search_page.dart';
//import 'package:max_baza/theme_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLandscape = false;
  //final bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /*void _toggleTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleTheme();
  }*/

  void _toggleScreenOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });

    if (_isLandscape) {
      // Змінити на горизонтальну орієнтацію
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Змінити на вертикальну орієнтацію
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onError: (error) => print('Помилка: $error'),
        onStatus: (status) => print('Статус: $status'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _searchQuery = result.recognizedWords.toLowerCase().replaceAll(
                ' ',
                '',
              );
            });
          },
          localeId: 'ru_RU',
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            onDevice: false,
            listenMode: stt.ListenMode.confirmation,
            cancelOnError: false,
            autoPunctuation: false,
          ),
          onSoundLevelChange: null,
        );
      } else {
        _tryAlternativeLanguages();
      }
    }
  }

  void _tryAlternativeLanguages() async {
    final languages = ['uk_UA', 'ru_RU', 'en_US'];

    for (String locale in languages) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _searchQuery = result.recognizedWords.toLowerCase().replaceAll(
                ' ',
                '',
              );
            });
          },
          localeId: locale,
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation,
          ),
        );
        break;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Скинути орієнтацію при закритті
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _importFromExcel() async {
    try {
      // Вибір файлу
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      // Показати індикатор завантаження
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Читання файлу...'),
            ],
          ),
        ),
      );

      PlatformFile file = result.files.first;
      List<int>? bytes;

      // Отримати bytes файлу
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null || bytes.isEmpty) {
        if (mounted) Navigator.of(context).pop();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалося прочитати файл')),
        );
        return;
      }

      // Декодувати Excel
      Excel excel;
      try {
        excel = Excel.decodeBytes(bytes);
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Помилка читання Excel: $e')));
        return;
      }

      // Знайти лист з даними
      Sheet? sheet;

      // Спробувати знайти лист за назвою
      for (var name in excel.tables.keys) {
        if (name == 'Автомобілі') {
          sheet = excel.tables[name];
          print('Знайдено лист: $name');
          break;
        }
      }

      // Якщо не знайшли, взяти перший лист
      if (sheet == null && excel.tables.isNotEmpty) {
        sheet = excel.tables.values.first;
        print('Використано перший лист: ${excel.tables.keys.first}');
      }

      if (sheet == null || sheet.rows.isEmpty) {
        if (mounted) Navigator.of(context).pop();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл порожній або не містить даних')),
        );
        return;
      }

      final box = Hive.box<CarEntry>('cars');
      int importedCount = 0;
      int skippedCount = 0;
      int duplicateCount = 0;

      // Визначити, чи перший рядок - заголовки
      int startRow = 0;
      if (sheet.rows.isNotEmpty) {
        var firstRow = sheet.rows[0];
        // Перевірити, чи перший рядок містить українські заголовки
        bool hasHeaders = false;
        for (var cell in firstRow) {
          if (cell?.value != null) {
            String cellValue = cell!.value.toString().toLowerCase();
            if (cellValue.contains('номер') ||
                cellValue.contains("ім'я") ||
                cellValue.contains('телефон') ||
                cellValue.contains('фірма') ||
                cellValue.contains('тип') ||
                cellValue.contains('коментар')) {
              hasHeaders = true;
              break;
            }
          }
        }
        if (hasHeaders) {
          startRow = 1;
          print('Пропущено рядок заголовків');
        }
      }

      print('Початок обробки з рядка: $startRow');
      print('Всього рядків: ${sheet.rows.length}');

      // Список для відстеження унікальних комбінацій номер авто + ім'я
      Set<String> uniqueCombinations = {};

      // Обробити кожен рядок
      for (int i = startRow; i < sheet.rows.length; i++) {
        var row = sheet.rows[i];

        // Пропустити порожні рядки
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          continue;
        }

        try {
          // ОТРИМАТИ ДАНІ З РЯДКА ЗА ПРАВИЛЬНИМ ПОРЯДКОМ З EXCEL
          String carNumber = _getCellValue(row, 0); // Номер авто (стовпець 0)
          String name = _getCellValue(row, 1); // Ім'я (стовпець 1)
          String phoneNumber = _getCellValue(row, 2); // Телефон (стовпець 2)
          String companyName = _getCellValue(row, 3); // Фірма (стовпець 3)
          String carType = _getCellValue(row, 4); // Тип авто (стовпець 4)
          String dateTimeStr = _getCellValue(
            row,
            5,
          ); // Дата виїзду (стовпець 5)
          String comment = _getCellValue(row, 6); // Коментар (стовпець 6)

          print('Обробка рядка $i: $carNumber, $name');

          // Перевірити обов'язкові поля (номер авто та ім'я)
          if (carNumber.isEmpty || name.isEmpty) {
            print('Пропущено рядок $i: порожній номер авто або ім\'я');
            skippedCount++;
            continue;
          }

          // Створити унікальний ключ: номер авто + ім'я
          String uniqueKey = carNumber.trim().toLowerCase();

          // Перевірити на дублікат в поточному імпорті
          if (uniqueCombinations.contains(uniqueKey)) {
            print('Пропущено дублікат в файлі: $carNumber - $name');
            duplicateCount++;
            continue;
          }

          // Додати до множини унікальних комбінацій
          uniqueCombinations.add(uniqueKey);

          // Парсинг дати з файлу
          DateTime departureDateTime = _parseDateTime(dateTimeStr);

          // Перевірити дублікати в базі даних за комбінацією номер авто + ім'я
          bool existsInDatabase = box.values.any((entry) {
            String entryKey =
                '${entry.carNumber.trim().toLowerCase()}|${entry.name.trim().toLowerCase()}';
            return entryKey == uniqueKey;
          });

          if (!existsInDatabase) {
            final newEntry = CarEntry(
              carNumber: carNumber,
              name: name.isNotEmpty ? name : 'Не вказано',
              phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : 'Не вказано',
              companyName: companyName.isNotEmpty ? companyName : 'Не вказано',
              carType: carType.isNotEmpty ? carType : 'Не вказано',
              departureDateTime: departureDateTime,
              comment: comment,
            );

            await box.add(newEntry);
            importedCount++;
            print('Додано запис: $carNumber - $name');
          } else {
            duplicateCount++;
            print('Пропущено дублікат в базі: $carNumber - $name');
          }
        } catch (e) {
          print('Помилка обробки рядка $i: $e');
          skippedCount++;
        }
      }

      // Закрити діалог
      if (mounted) Navigator.of(context).pop();

      // Показати результат
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ІМПОРТ ЗАВЕРШЕНО!\n'
            'Додано: $importedCount записів\n'
            'Пропущено дублікатів: $duplicateCount\n'
            'Пропущено помилок: $skippedCount',
          ),
          duration: const Duration(seconds: 5),
        ),
      );

      print(
        'Імпорт завершено. Додано: $importedCount, Дублікатів: $duplicateCount, Помилок: $skippedCount',
      );
    } catch (e, stackTrace) {
      print('Помилка імпорту: $e');
      print('StackTrace: $stackTrace');

      // Закрити діалог
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ПОМИЛКА ІМПОРТУ: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Спрощена функція для отримання значення комірки
  String _getCellValue(List<Data?> row, int index) {
    try {
      if (index >= row.length) return '';
      var cell = row[index];
      if (cell == null || cell.value == null) return '';

      var value = cell.value;

      // Обробити різні типи даних
      if (value is String) {
        return value.toString().trim();
      } else if (value is TextCellValue) {
        return value.value.toString().trim();
      } else if (value is num) {
        return value.toString();
      } else {
        return value.toString().trim();
      }
    } catch (e) {
      print('Помилка читання комірки [$index]: $e');
      return '';
    }
  }

  // Допоміжний метод для парсингу дати
  DateTime _parseDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) {
      return DateTime.now();
    }

    try {
      // Формат "dd.MM.yyyy HH:mm" або "dd.MM.yyyy"
      if (dateTimeStr.contains('.')) {
        var parts = dateTimeStr.split(' ');
        var dateParts = parts[0].split('.');

        if (dateParts.length >= 3) {
          int day = int.parse(dateParts[0]);
          int month = int.parse(dateParts[1]);
          int year = int.parse(dateParts[2]);

          int hour = 0;
          int minute = 0;

          if (parts.length > 1 && parts[1].contains(':')) {
            var timeParts = parts[1].split(':');
            hour = int.parse(timeParts[0]);
            minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
          }

          return DateTime(year, month, day, hour, minute);
        }
      }

      // Спробувати ISO формат
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      print('Помилка парсингу дати "$dateTimeStr": $e');
      return DateTime.now();
    }
  }

  Future<void> _exportToExcel() async {
    try {
      // Отримати всі записи з бази
      final box = Hive.box<CarEntry>('cars');
      final entries = box.values.toList();

      if (entries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Немає даних для експорту')),
        );
        return;
      }

      // Створити Excel документ
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Автомобілі'];

      // Додати заголовки
      sheetObject.appendRow([
        TextCellValue('Номер авто'),
        TextCellValue('Ім\'я'),
        TextCellValue('Телефон'),
        TextCellValue('Фірма'),
        TextCellValue('Тип авто'),
        TextCellValue('Дата виїзду'),
        TextCellValue('Коментар'),
      ]);

      // Додати дані
      for (var entry in entries) {
        sheetObject.appendRow([
          TextCellValue(entry.carNumber),
          TextCellValue(entry.name),
          TextCellValue(entry.phoneNumber),
          TextCellValue(entry.companyName),
          TextCellValue(entry.carType),
          TextCellValue(
            '${entry.departureDateTime.day}.${entry.departureDateTime.month}.${entry.departureDateTime.year} ${entry.departureDateTime.hour}:${entry.departureDateTime.minute.toString().padLeft(2, '0')}',
          ),
          TextCellValue(entry.comment),
        ]);
      }

      // Запитати дозвіл на збереження
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }

        // Для Android 13+ використовуємо manageExternalStorage
        if (Platform.isAndroid) {
          var manageStatus = await Permission.manageExternalStorage.status;
          if (!manageStatus.isGranted) {
            manageStatus = await Permission.manageExternalStorage.request();
          }
        }
      }

      // Зберегти файл
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      String fileName =
          'cars_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      String filePath = '${directory.path}/$fileName';

      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Експортовано: $fileName'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Помилка експорту: $e')));
    }
  }

  void _showSearchDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пошук за номером авто'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Введіть номер авто',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _searchController.text),
            child: const Text('Пошук'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _searchQuery = result;
      });
    }
    _searchController.clear();
  }

  // В HomePage додай цю функцію для меню:
  void _showImportExportMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'import',
          child: Row(
            children: [
              Icon(Icons.file_upload),
              SizedBox(width: 8),
              Text('Import from Excel'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.file_download),
              SizedBox(width: 8),
              Text('Export to Excel'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'import') {
        _importFromExcel();
      } else if (value == 'export') {
        _exportToExcel();
      }
    });
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      SearchPage(
        searchQuery: _searchQuery,
        onClearSearch: () => setState(() => _searchQuery = ''),
        onExportToExcel: _exportToExcel,
        onImportFromExcel: _importFromExcel,
      ),
      const AddEntryPage(),
    ];

    return Scaffold(
      // Компактний AppBar в ландшафтному режимі
      appBar: _isLandscape
          ? AppBar(
              toolbarHeight: 40,
              title: Text(
                _selectedIndex == 0 ? 'Search' : 'Add Entry',
                style: const TextStyle(fontSize: 16),
              ),
              elevation: 1,
              actions: [
                // Кнопка імпорт/експорт в ландшафтному режимі
                IconButton(
                  icon: const Icon(Icons.import_export, size: 20),
                  tooltip: 'Import/Export',
                  onPressed: _showImportExportMenu,
                ),
                IconButton(
                  icon: Icon(
                    _isLandscape
                        ? Icons.screen_lock_portrait
                        : Icons.screen_lock_rotation,
                    size: 20,
                  ),
                  tooltip: _isLandscape ? 'Vertical mode' : 'Horizontal mode',
                  onPressed: _toggleScreenOrientation,
                ),
              ],
            )
          : AppBar(
              title: Text(_selectedIndex == 0 ? 'Search' : 'Add Entry'),
              elevation: 2,
              actions: _selectedIndex == 0
                  ? [
                      // Кнопка імпорт/експорт в портретному режимі
                      IconButton(
                        icon: const Icon(Icons.import_export),
                        tooltip: 'Import/Export',
                        onPressed: _showImportExportMenu,
                      ),
                      IconButton(
                        icon: Icon(
                          _isLandscape
                              ? Icons.screen_lock_portrait
                              : Icons.screen_lock_rotation,
                        ),
                        tooltip: _isLandscape
                            ? 'Vertical mode'
                            : 'Horizontal mode',
                        onPressed: _toggleScreenOrientation,
                      ),
                    ]
                  : null,
            ),

      body: pages[_selectedIndex],

      // FloatingActionButton адаптований для ландшафтного режиму
      floatingActionButton: _selectedIndex == 0
          ? _isLandscape
                ? Row(
                    // Горизонтальне розташування в ландшафтному режимі
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Кнопка пошуку
                      Container(
                        margin: const EdgeInsets.only(
                          right: 70,
                        ), // Відступ для мікрофона
                        child: FloatingActionButton(
                          heroTag: 'searchButtonLandscape',
                          onPressed: _showSearchDialog,
                          backgroundColor: Colors.blue,
                          mini: true, // Менша кнопка
                          child: const Icon(Icons.search, size: 20),
                        ),
                      ),
                      // Кнопка мікрофона
                      FloatingActionButton(
                        heroTag: 'micButtonLandscape',
                        onPressed: _isListening
                            ? _stopListening
                            : _startListening,
                        backgroundColor: _isListening
                            ? Colors.red
                            : Colors.blue,
                        mini: true, // Менша кнопка
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          size: 20,
                        ),
                      ),
                    ],
                  )
                : Column(
                    // Вертикальне розташування в портретному режимі
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 12),
                      FloatingActionButton(
                        heroTag: 'searchButtonPortrait',
                        onPressed: _showSearchDialog,
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.search),
                      ),
                      const SizedBox(height: 16),
                      FloatingActionButton(
                        heroTag: 'micButtonPortrait',
                        onPressed: _isListening
                            ? _stopListening
                            : _startListening,
                        backgroundColor: _isListening
                            ? Colors.red
                            : Colors.blue,
                        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      ),
                    ],
                  )
          : null,

      // Компактний BottomNavigationBar або повністю прихований
      bottomNavigationBar: _isLandscape
          ? null // Повністю ховаємо в ландшафтному режимі
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 1) {
                    _searchQuery = '';
                    _stopListening();
                  }
                });
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.search), label: 'Пошук'),
                NavigationDestination(icon: Icon(Icons.add), label: 'Додати'),
              ],
            ),
    );
  }
}
