import 'package:flutter/material.dart';
import 'package:max_baza/car_entryy_model.dart';

class EditEntryPage extends StatefulWidget {
  final CarEntry entry;

  const EditEntryPage({super.key, required this.entry});

  @override
  State<EditEntryPage> createState() => _EditEntryPageState();
}

class _EditEntryPageState extends State<EditEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _carNumberController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;
  late TextEditingController _carTypeController;
  late TextEditingController _commentController;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _carNumberController = TextEditingController(text: widget.entry.carNumber);
    _nameController = TextEditingController(text: widget.entry.name);
    _phoneController = TextEditingController(text: widget.entry.phoneNumber);
    _companyController = TextEditingController(text: widget.entry.companyName);
    _carTypeController = TextEditingController(text: widget.entry.carType);
    _commentController = TextEditingController(text: widget.entry.comment);
    _selectedDateTime = widget.entry.departureDateTime;
  }

  @override
  void dispose() {
    _carNumberController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _carTypeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _updateEntry() {
    if (_formKey.currentState!.validate()) {
      widget.entry.carNumber = _carNumberController.text;
      widget.entry.name = _nameController.text;
      widget.entry.phoneNumber = _phoneController.text;
      widget.entry.companyName = _companyController.text;
      widget.entry.carType = _carTypeController.text;
      widget.entry.departureDateTime = _selectedDateTime;
      widget.entry.comment = _commentController.text;
      widget.entry.save();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Запис оновлено!')));

      Navigator.pop(context);
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редагувати запис'), elevation: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _carNumberController,
                decoration: const InputDecoration(
                  labelText: 'Номер авто',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Введіть номер авто' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ім\'я',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Введіть ім\'я' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Номер телефону',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Введіть номер телефону' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Назва фірми',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Введіть назву фірми' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _carTypeController,
                decoration: const InputDecoration(
                  labelText: 'Тип авто',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Введіть тип авто' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Дата та час виїзду'),
                subtitle: Text(
                  '${_selectedDateTime.day}.${_selectedDateTime.month}.${_selectedDateTime.year} ${_selectedDateTime.hour}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                ),
                leading: const Icon(Icons.calendar_today),
                onTap: _selectDateTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Коментар',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _updateEntry,
                icon: const Icon(Icons.save),
                label: const Text('Оновити запис'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
