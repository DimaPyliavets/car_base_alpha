import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:max_baza/car_entryy_model.dart';

class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _carNumberController = TextEditingController();
  final _carTypeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _commentController = TextEditingController();

  final _nameFocus = FocusNode();
  final _companyFocus = FocusNode();
  final _carNumberFocus = FocusNode();
  final _carTypeFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _commentFocus = FocusNode();

  // Списки для випадаючих меню
  List<String> _companySuggestions = [];
  List<String> _carTypeSuggestions = [];
  List<String> _nameSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    // Clean up focus nodes to prevent memory leaks
    _nameFocus.dispose();
    _companyFocus.dispose();
    _carNumberFocus.dispose();
    _carTypeFocus.dispose();
    _phoneFocus.dispose();
    _commentFocus.dispose();

    _nameController.dispose();
    _companyController.dispose();
    _carNumberController.dispose();
    _carTypeController.dispose();
    _phoneController.dispose();
    _commentController.dispose();

    super.dispose();
  }

  void _loadSuggestions() {
    final box = Hive.box<CarEntry>('cars');
    final entries = box.values.toList();

    // Отримати унікальні значення з бази даних
    _companySuggestions = entries
        .map((e) => e.companyName)
        .where((company) => company.isNotEmpty)
        .toSet()
        .toList();

    _carTypeSuggestions = entries
        .map((e) => e.carType)
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();

    _nameSuggestions = entries
        .map((e) => e.name)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    setState(() {});
  }

  // Функція для перевірки на дублікати
  bool _checkForDuplicate() {
    final box = Hive.box<CarEntry>('cars');
    final entries = box.values.toList();

    String carNumber = _carNumberController.text.trim().toUpperCase();
    String name = _nameController.text.trim().toUpperCase();

    // Створити унікальний ключ: номер авто + ім'я
    String uniqueKey = '$carNumber|$name';

    // Перевірити чи існує такий запис в базі
    bool duplicateExists = entries.any((entry) {
      String entryKey =
          '${entry.carNumber.trim().toUpperCase()}|${entry.name.trim().toUpperCase()}';
      return entryKey == uniqueKey;
    });

    return duplicateExists;
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      // Перевірити на дублікат перед збереженням
      if (_checkForDuplicate()) {
        _showDuplicateWarning();
        return;
      }

      final box = Hive.box<CarEntry>('cars');
      final entry = CarEntry(
        name: _nameController.text.toUpperCase(),
        companyName: _companyController.text.toUpperCase(),
        carNumber: _carNumberController.text.toUpperCase(),
        carType: _carTypeController.text.toUpperCase(),
        phoneNumber: _phoneController.text.toUpperCase(),
        comment: _commentController.text.toUpperCase(),
        departureDateTime: DateTime.now(),
      );

      box.add(entry);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('RECORD SAVED!')));

      // Оновити списки після збереження нового запису
      _loadSuggestions();

      _formKey.currentState!.reset();
      _nameController.clear();
      _companyController.clear();
      _carNumberController.clear();
      _carTypeController.clear();
      _phoneController.clear();
      _commentController.clear();

      // Use a post-frame callback to ensure focus is set after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_nameFocus);
      });
    }
  }

  // Функція для показу попередження про дублікат
  void _showDuplicateWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Flexible(
                // FIX: Use Flexible instead of letting Row overflow
                child: Text(
                  'DUPLICATE RECORD',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RECORD ALREADY EXISTS:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text('CAR NUMBER: ${_carNumberController.text.toUpperCase()}'),
              Text('NAME: ${_nameController.text.toUpperCase()}'),
              const SizedBox(height: 16),
              Text(
                'This combination of car number and name already exists in the database.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _forceSaveEntry(); // Примусове збереження
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('SAVE ANYWAY'),
            ),
          ],
        );
      },
    );
  }

  // Функція для примусового збереження (якщо користувач хоче зберегти дублікат)
  void _forceSaveEntry() {
    final box = Hive.box<CarEntry>('cars');
    final entry = CarEntry(
      name: _nameController.text.toUpperCase(),
      companyName: _companyController.text.toUpperCase(),
      carNumber: _carNumberController.text.toUpperCase(),
      carType: _carTypeController.text.toUpperCase(),
      phoneNumber: _phoneController.text.toUpperCase(),
      comment: _commentController.text.toUpperCase(),
      departureDateTime: DateTime.now(),
    );

    box.add(entry);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('RECORD SAVED (DUPLICATE)!')));

    // Оновити списки після збереження нового запису
    _loadSuggestions();

    _formKey.currentState!.reset();
    _nameController.clear();
    _companyController.clear();
    _carNumberController.clear();
    _carTypeController.clear();
    _phoneController.clear();
    _commentController.clear();

    // Use a post-frame callback to ensure focus is set after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocus);
    });
  }

  // Simplified version without Autocomplete to fix focus issues
  Widget _buildDropdownFormField({
    required String label,
    required List<String> suggestions,
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode nextFocus,
    required String? Function(String?) validator,
    required IconData prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) {
        nextFocus.requestFocus();
      },
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suggestions.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_drop_down),
                onPressed: () {
                  _showAllOptionsDialog(
                    context,
                    label,
                    suggestions,
                    controller,
                    focusNode,
                  );
                },
              )
            : null,
      ),
      validator: validator,
    );
  }

  void _showAllOptionsDialog(
    BuildContext context,
    String title,
    List<String> options,
    TextEditingController controller,
    FocusNode focusNode,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('SELECT $title'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(options[index]),
                  onTap: () {
                    controller.text = options[index];
                    Navigator.of(context).pop();
                    // Refocus the field after selection
                    focusNode.requestFocus();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ім'я з випадаючим меню
            _buildDropdownFormField(
              label: 'NAME',
              suggestions: _nameSuggestions,
              controller: _nameController,
              focusNode: _nameFocus,
              nextFocus: _companyFocus,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'ENTER NAME' : null,
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 16),

            // Фірма з випадаючим меню
            _buildDropdownFormField(
              label: 'COMPANY',
              suggestions: _companySuggestions,
              controller: _companyController,
              focusNode: _companyFocus,
              nextFocus: _carNumberFocus,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'ENTER COMPANY NAME' : null,
              prefixIcon: Icons.business,
            ),
            const SizedBox(height: 16),

            // Номер авто (без випадаючого меню)
            TextFormField(
              controller: _carNumberController,
              focusNode: _carNumberFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                _carTypeFocus.requestFocus();
              },
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'CAR NUMBER',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'ENTER CAR NUMBER' : null,
            ),
            const SizedBox(height: 16),

            // Тип авто з випадаючим меню
            _buildDropdownFormField(
              label: 'CAR TYPE',
              suggestions: _carTypeSuggestions,
              controller: _carTypeController,
              focusNode: _carTypeFocus,
              nextFocus: _phoneFocus,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'ENTER CAR TYPE' : null,
              prefixIcon: Icons.local_shipping,
            ),
            const SizedBox(height: 16),

            // Телефон (без випадаючого меню)
            TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                _commentFocus.requestFocus();
              },
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'PHONE',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'ENTER PHONE NUMBER' : null,
            ),
            const SizedBox(height: 16),

            // Коментар (без випадаючого меню)
            TextFormField(
              controller: _commentController,
              focusNode: _commentFocus,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                _saveEntry();
              },
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'COMMENT',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Інформація про автоматичну дату
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    // FIX: Use Expanded to prevent overflow
                    child: Text(
                      'DATE AND TIME WILL BE SET AUTOMATICALLY TO CURRENT TIME',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Кнопка збереження
            ElevatedButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.save),
              label: const Text('SAVE RECORD'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
