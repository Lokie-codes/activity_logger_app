
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _tickedDays = {};
  Map<DateTime, String> _notes = {};
  String _noteText = "";
  bool _tempTicked = false;
  bool _isLoading = true;
  late TextEditingController _noteController;

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _tempTicked = _tickedDays.contains(selectedDay);
      _noteController.text = _notes[selectedDay] ?? "";
    });
  }

  void _loadData() async {
    final firestore = FirebaseFirestore.instance;
    final docRef = firestore.collection('calendar').doc(userId);

    try {
      final snapshot = await docRef.get();
      if(snapshot.exists) {
        final data = snapshot.data()!;
        final tickedDaysList = List<String>.from(data['tickedDays'] ?? []);
        final notesMap = Map<String, String>.from(data['notes'] ?? {});
        setState(() {
          _tickedDays = tickedDaysList.map((date) => DateTime.parse(date)).toSet();
          _notes = notesMap.map((key, value) => MapEntry(DateTime.parse(key), value));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveChanges() async {
    if(_selectedDay == null) return;

    final firestore = FirebaseFirestore.instance;
    final docRef = firestore.collection('calendar').doc(userId);
    try {
      setState(() {
        if(_tempTicked) {
          _tickedDays.add(_selectedDay!);
        } else {
          _tickedDays.remove(_selectedDay!);
        }

        if(_noteController.text.isNotEmpty) {
          _notes[_selectedDay!] = _noteController.text;
        } else {
          _notes.remove(_selectedDay!);
        }
      });

      await docRef.set({
        'tickedDays': _tickedDays.map((date) => date.toIso8601String()).toList(),
        'notes': _notes.map((key, value) => MapEntry(key.toIso8601String(), value)),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e')),
      );
    }
  }

  void _discardChanges() {
    setState(() {
      _tempTicked = _tickedDays.contains(_selectedDay!);
      _noteText = _notes[_selectedDay] ?? "";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes discarded.')),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(),)
        : SingleChildScrollView(
          child: Column(
          children: [
          TableCalendar(
            focusedDay: _focusedDay, 
            firstDay: DateTime.utc(2000, 1, 1), 
            lastDay:  DateTime.utc(2100, 12, 31),
            selectedDayPredicate: (day) => 
              isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(formatButtonVisible: false),
            eventLoader: (day) {
              return _tickedDays.contains(day) ? ['Tick']:[];
            },
            rowHeight: 70,
            ),
            const SizedBox(height: 16),
            if(_selectedDay != null) 
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Day: ${_selectedDay!.toLocal()}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(value: _tempTicked, onChanged: (value) {
                          setState(() {
                            _tempTicked = value!;
                          });
                        },
                        ),
                        Center(child: const Text('Did it. Tick It!')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Note for the day',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      textDirection: TextDirection.ltr,
                      onChanged: (value) {
                        _noteText = value;
                      },                      
                      controller: _noteController,
                    ),
                    const SizedBox(height: 16,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _saveChanges, 
                          child: const Text('Save')
                          ),
                        OutlinedButton(
                          onPressed: _discardChanges, 
                          child: const Text('Discard')
                          ),
                      ],
                    ),
                  ],
                )
              ),
        ],
      ),
      ),
    );
  }
}
