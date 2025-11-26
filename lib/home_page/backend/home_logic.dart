import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:max_baza/car_entryy_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomeLogic with ChangeNotifier {
  int _selectedIndex = 0;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _searchQuery = '';
  bool _isLandscape = false;

  // Кеш для транслітерації
  final Map<String, String> _transliterationCache = {};

  // Оптимізовані словники (статичні константи)
  static const Map<String, String> _ukrainianNumberWords = {
    'нуль': '0',
    'один': '1',
    'два': '2',
    'три': '3',
    'чотири': '4',
    'п\'ять': '5',
    'шість': '6',
    'сім': '7',
    'вісім': '8',
    'дев\'ять': '9',
    'десять': '10',
    'одинадцять': '11',
    'дванадцять': '12',
    'тринадцять': '13',
    'чотирнадцять': '14',
    'п\'ятнадцять': '15',
    'шістнадцять': '16',
    'сімнадцять': '17',
    'вісімнадцять': '18',
    'дев\'ятнадцять': '19',
    'двадцять': '20',
    'тридцять': '30',
    'сорок': '40',
    'п\'ятдесят': '50',
    'шістдесят': '60',
    'сімдесят': '70',
    'вісімдесят': '80',
    'дев\'яносто': '90',
    'сто': '100',
  };

  static const Map<String, String> _russianNumberWords = {
    'ноль': '0',
    'один': '1',
    'два': '2',
    'три': '3',
    'четыре': '4',
    'пять': '5',
    'шесть': '6',
    'семь': '7',
    'восемь': '8',
    'девять': '9',
    'десять': '10',
    'одиннадцать': '11',
    'двенадцать': '12',
    'тринадцать': '13',
    'четырнадцать': '14',
    'пятнадцать': '15',
    'шестнадцать': '16',
    'семнадцать': '17',
    'восемнадцать': '18',
    'девятнадцать': '19',
    'двадцать': '20',
    'тридцать': '30',
    'сорок': '40',
    'пятьдесят': '50',
    'шестьдесят': '60',
    'семьдесят': '70',
    'восемьдесят': '80',
    'девяносто': '90',
    'сто': '100',
  };

  static const Map<String, String> _englishNumberWords = {
    'zero': '0',
    'one': '1',
    'two': '2',
    'three': '3',
    'four': '4',
    'five': '5',
    'six': '6',
    'seven': '7',
    'eight': '8',
    'nine': '9',
    'ten': '10',
    'eleven': '11',
    'twelve': '12',
    'thirteen': '13',
    'fourteen': '14',
    'fifteen': '15',
    'sixteen': '16',
    'seventeen': '17',
    'eighteen': '18',
    'nineteen': '19',
    'twenty': '20',
    'thirty': '30',
    'forty': '40',
    'fifty': '50',
    'sixty': '60',
    'seventy': '70',
    'eighty': '80',
    'ninety': '90',
    'hundred': '100',
  };

  static const Map<String, String> _transliterationMap = {
    // Українські літери
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'h', 'ґ': 'g',
    'д': 'd', 'е': 'e', 'є': 'ye', 'ж': 'zh', 'з': 'z',
    'и': 'y', 'і': 'i', 'ї': 'yi', 'й': 'y', 'к': 'k',
    'л': 'l', 'м': 'm', 'н': 'n', 'о': 'o', 'п': 'p',
    'р': 'r', 'с': 's', 'т': 't', 'у': 'u', 'ф': 'f',
    'х': 'H', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch',
    'ь': '', 'ю': 'u', 'я': 'ya',
    // Великі українські літери
    'А': 'A', 'Б': 'B', 'В': 'V', 'Г': 'H', 'Ґ': 'G',
    'Д': 'D', 'Е': 'E', 'Є': 'Ye', 'Ж': 'Zh', 'З': 'Z',
    'И': 'Y', 'І': 'I', 'Ї': 'Yi', 'Й': 'Y', 'К': 'K',
    'Л': 'L', 'М': 'M', 'Н': 'N', 'О': 'O', 'П': 'P',
    'Р': 'R', 'С': 'S', 'Т': 'T', 'У': 'U', 'Ф': 'F',
    'Х': 'H', 'Ц': 'Ts', 'Ч': 'Ch', 'Ш': 'Sh', 'Щ': 'Shch',
    'Ь': '', 'Ю': 'U', 'Я': 'Ya',
    // Російські літери
    'ы': 'y', 'э': 'e', 'ъ': '',
    // Великі російські літери
    'Ы': 'Y', 'Э': 'E', 'Ъ': '',
  };

  // Getters
  int get selectedIndex => _selectedIndex;
  bool get isListening => _isListening;
  String get searchQuery => _searchQuery;
  bool get isLandscape => _isLandscape;

  // Setters
  set selectedIndex(int value) {
    if (_selectedIndex != value) {
      _selectedIndex = value;
      notifyListeners();
    }
  }

  set searchQuery(String value) {
    if (_searchQuery != value) {
      _searchQuery = value;
      notifyListeners();
    }
  }

  // Оптимізована ініціалізація
  void initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );
      if (!available) {
        debugPrint('Voice search is not available on this device.');
      }
    } catch (e) {
      debugPrint('Speech initialization error: $e');
    }
  }

  void toggleScreenOrientation() {
    _isLandscape = !_isLandscape;

    final orientations = _isLandscape
        ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown];

    SystemChrome.setPreferredOrientations(orientations);

    if (_isListening) {
      _stopListening();
    }

    notifyListeners();
  }

  Future<String?> startListening() async {
    if (_isListening) {
      _stopListening();
      return null;
    }

    if (!_speech.isAvailable) {
      return 'Voice search is not available';
    }

    final preferredLocales = _getPreferredLocales();

    for (String localeId in preferredLocales) {
      try {
        _isListening = true;
        notifyListeners();

        _speech.listen(
          onResult: (result) {
            if (result.recognizedWords.isNotEmpty) {
              _searchQuery = _processSpeechText(result.recognizedWords);
              notifyListeners();
            }

            if (result.finalResult) {
              _stopListening();
            }
          },
          localeId: localeId,
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            listenMode: stt.ListenMode.dictation,
            cancelOnError: true,
            autoPunctuation: true,
          ),
        );

        return null;
      } catch (e) {
        debugPrint('Failed to start listening with $localeId: $e');
      }
    }

    _isListening = false;
    notifyListeners();
    return 'Failed to start speech recognition';
  }

  // Оптимізована обробка тексту - ВИДАЛЯЄМО ВСІ ПРОБІЛИ
  String _processSpeechText(String recognizedWords) {
    if (recognizedWords.isEmpty) return '';

    String processedText = recognizedWords.trim();

    // Швидка перевірка на наявність кирилиці
    final bool hasCyrillic = RegExp(
      r'[а-яА-ЯіІїЇєЄґҐ]',
    ).hasMatch(processedText);

    if (!hasCyrillic && !_containsNumberWords(processedText)) {
      // Видаляємо пробіли навіть для англійського тексту
      return processedText.replaceAll(' ', '');
    }

    final words = processedText.toLowerCase().split(' ');
    final buffer = StringBuffer();

    for (String word in words) {
      if (word.isEmpty) continue;

      String processedWord = word;

      processedWord =
          _ukrainianNumberWords[word] ??
          _russianNumberWords[word] ??
          _englishNumberWords[word] ??
          processedWord;

      if (hasCyrillic) {
        processedWord = _transliterateToEnglish(processedWord);
      }

      processedWord = processedWord.replaceAll(RegExp(r'[.,!?;:]'), '');

      // Записуємо слово без пробілів
      buffer.write(processedWord);
    }

    processedText = buffer.toString();

    // Додатково видаляємо всі пробіли (на випадок якщо щось залишилося)
    processedText = processedText.replaceAll(' ', '');

    // Оптимізоване форматування - ВИДАЛЯЄМО ВСІ ПРОБІЛИ
    return _optimizeTextFormat(processedText);
  }

  bool _containsNumberWords(String text) {
    return text.contains('нуль') ||
        text.contains('один') ||
        text.contains('two') ||
        text.contains('ноль') ||
        text.contains('one') ||
        text.contains('два');
  }

  // Спрощена функція форматування - ВИДАЛЯЄ ВСІ ПРОБІЛИ
  String _optimizeTextFormat(String text) {
    // Видаляємо всі пробіли незалежно від вмісту
    return text.replaceAll(' ', '');
  }

  // Оптимізована транслітерація з кешуванням
  String _transliterateToEnglish(String text) {
    if (text.isEmpty) return text;

    // Перевірка кешу
    if (_transliterationCache.containsKey(text)) {
      return _transliterationCache[text]!;
    }

    final result = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      result.write(_transliterationMap[char] ?? char);
    }

    final resultString = result.toString();

    // Кешування результатів (обмежений розмір кешу)
    if (_transliterationCache.length < 1000) {
      _transliterationCache[text] = resultString;
    }

    return resultString;
  }

  List<String> _getPreferredLocales() {
    try {
      final systemLocale = _getSystemLocale();
      const defaultLocales = ['en_US', 'ru_RU', 'uk_UA'];

      if (systemLocale != null && defaultLocales.contains(systemLocale)) {
        return [
          systemLocale,
          ...defaultLocales.where((loc) => loc != systemLocale),
        ];
      }

      return defaultLocales;
    } catch (e) {
      debugPrint('Error getting preferred locales: $e');
      return ['en_US'];
    }
  }

  String? _getSystemLocale() {
    try {
      final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
      final systemLocales = platformDispatcher.locales;

      if (systemLocales.isNotEmpty) {
        final primaryLocale = systemLocales.first;
        return '${primaryLocale.languageCode}_${primaryLocale.countryCode?.toUpperCase() ?? 'US'}';
      }
    } catch (e) {
      debugPrint('Error getting system locale: $e');
    }
    return null;
  }

  void _stopListening() {
    if (_speech.isListening) {
      _speech.stop();
    }
    _isListening = false;
    notifyListeners();
  }

  void stopListening() {
    _stopListening();
  }

  // Оптимізований імпорт з Excel
  Future<String?> importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      List<int>? bytes;

      if (file.bytes != null) {
        bytes = file.bytes;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null || bytes.isEmpty) {
        return 'Failed to read file';
      }

      final excel = Excel.decodeBytes(bytes);
      final sheet = _findSheet(excel);

      if (sheet == null || sheet.rows.isEmpty) {
        return 'File is empty or contains no data';
      }

      return await _processExcelData(sheet);
    } catch (e, stackTrace) {
      debugPrint('Import error: $e\n$stackTrace');
      return 'IMPORT ERROR: ${e.toString().split('\n').first}';
    }
  }

  Sheet? _findSheet(Excel excel) {
    for (var name in ['Автомобілі', 'Cars', ...excel.tables.keys]) {
      final sheet = excel.tables[name];
      if (sheet != null) return sheet;
    }
    return excel.tables.isNotEmpty ? excel.tables.values.first : null;
  }

  Future<String> _processExcelData(Sheet sheet) async {
    final box = Hive.box<CarEntry>('cars');
    int importedCount = 0, skippedCount = 0, duplicateCount = 0;

    final startRow = _detectHeaderRow(sheet);
    final uniqueCombinations = <String>{};
    final existingEntries = _getExistingEntriesMap(box);

    for (int i = startRow; i < sheet.rows.length; i++) {
      if (i % 50 == 0) {
        await Future.delayed(const Duration(milliseconds: 1)); // Yield to UI
      }

      final row = sheet.rows[i];
      if (row.isEmpty || row.every((cell) => cell?.value == null)) continue;

      try {
        final result = _processRow(row, uniqueCombinations, existingEntries);
        if (result != null) {
          await box.add(result);
          importedCount++;
        } else {
          duplicateCount++;
        }
      } catch (e) {
        skippedCount++;
      }
    }

    return 'IMPORT COMPLETED!\nAdded: $importedCount\nDuplicates: $duplicateCount\nErrors: $skippedCount';
  }

  int _detectHeaderRow(Sheet sheet) {
    if (sheet.rows.isEmpty) return 0;

    final firstRow = sheet.rows[0];
    for (var cell in firstRow) {
      if (cell?.value != null) {
        final cellValue = cell!.value.toString().toLowerCase();
        if (cellValue.contains('номер') ||
            cellValue.contains('number') ||
            cellValue.contains("ім'я") ||
            cellValue.contains('name') ||
            cellValue.contains('телефон') ||
            cellValue.contains('phone') ||
            cellValue.contains('фірма') ||
            cellValue.contains('company') ||
            cellValue.contains('тип') ||
            cellValue.contains('type') ||
            cellValue.contains('коментар') ||
            cellValue.contains('comment') ||
            cellValue.contains('дата') ||
            cellValue.contains('date')) {
          return 1;
        }
      }
    }
    return 0;
  }

  Map<String, bool> _getExistingEntriesMap(Box<CarEntry> box) {
    final map = <String, bool>{};
    for (final entry in box.values) {
      final key =
          '${entry.carNumber.trim().toLowerCase()}|${entry.name.trim().toLowerCase()}';
      map[key] = true;
    }
    return map;
  }

  CarEntry? _processRow(
    List<Data?> row,
    Set<String> uniqueCombinations,
    Map<String, bool> existingEntries,
  ) {
    final carNumber = _transliterateToEnglish(_getCellValue(row, 0));
    final name = _transliterateToEnglish(_getCellValue(row, 1));

    if (carNumber.isEmpty || name.isEmpty) return null;

    final uniqueKey =
        '${carNumber.trim().toLowerCase()}|${name.trim().toLowerCase()}';

    if (uniqueCombinations.contains(uniqueKey) ||
        existingEntries.containsKey(uniqueKey)) {
      return null;
    }

    uniqueCombinations.add(uniqueKey);

    return CarEntry(
      carNumber: carNumber,
      name: name.isNotEmpty ? name : 'Not specified',
      phoneNumber: _getCellValue(row, 2).isNotEmpty
          ? _getCellValue(row, 2)
          : 'Not specified',
      companyName: _transliterateToEnglish(_getCellValue(row, 3)).isNotEmpty
          ? _transliterateToEnglish(_getCellValue(row, 3))
          : 'Not specified',
      carType: _transliterateToEnglish(_getCellValue(row, 4)).isNotEmpty
          ? _transliterateToEnglish(_getCellValue(row, 4))
          : 'Not specified',
      departureDateTime: _parseDateTime(_getCellValue(row, 5)),
      comment: _transliterateToEnglish(_getCellValue(row, 6)),
    );
  }

  String _getCellValue(List<Data?> row, int index) {
    try {
      if (index >= row.length) return '';
      final cell = row[index];
      if (cell == null || cell.value == null) return '';

      final value = cell.value;
      return value.toString().trim();
    } catch (e) {
      return '';
    }
  }

  DateTime _parseDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return DateTime.now();

    try {
      if (dateTimeStr.contains('.')) {
        final parts = dateTimeStr.split(' ');
        final dateParts = parts[0].split('.');

        if (dateParts.length >= 3) {
          final day = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final year = int.parse(dateParts[2]);

          int hour = 0, minute = 0;

          if (parts.length > 1 && parts[1].contains(':')) {
            final timeParts = parts[1].split(':');
            hour = int.parse(timeParts[0]);
            minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
          }

          return DateTime(year, month, day, hour, minute);
        }
      }

      return DateTime.parse(dateTimeStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<String?> exportToExcel() async {
    try {
      final box = Hive.box<CarEntry>('cars');
      final entries = box.values.toList();

      if (entries.isEmpty) return 'No data to export';

      final excel = Excel.createExcel();
      final sheet = excel['Автомобілі'];

      // Додаємо заголовки
      sheet.appendRow([
        TextCellValue('Номер авто'),
        TextCellValue('Ім\'я'),
        TextCellValue('Телефон'),
        TextCellValue('Фірма'),
        TextCellValue('Тип авто'),
        TextCellValue('Дата виїзду'),
        TextCellValue('Коментар'),
      ]);

      // Додаємо дані пачками
      for (int i = 0; i < entries.length; i++) {
        if (i % 100 == 0) {
          await Future.delayed(const Duration(milliseconds: 1)); // Yield to UI
        }

        final entry = entries[i];
        sheet.appendRow([
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

      // Перевірка дозволів
      if (Platform.isAndroid) {
        final status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }

      final directory = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      final fileName =
          'cars_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';

      File(filePath)
        ..create(recursive: true)
        ..writeAsBytes(excel.encode()!);

      return 'Exported: $fileName';
    } catch (e) {
      return 'Export error: ${e.toString().split('\n').first}';
    }
  }

  // Очищення ресурсів
  @override
  void dispose() {
    super.dispose();
    _stopListening();
    _transliterationCache.clear();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}
