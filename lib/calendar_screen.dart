
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
  bool _tempTicked = false;

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _tempTicked = _tickedDays.contains(selectedDay);
    });
  } 

  void _saveChanges() {
    setState(() {
      if(_tempTicked) {
        _tickedDays.add(_selectedDay!);
      } else {
        _tickedDays.remove(_selectedDay!);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved.')),
    );
  }

  void _discardChanges() {
    setState(() {
      _tempTicked = _tickedDays.contains(_selectedDay!);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes discarded.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Column(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(onPressed: _saveChanges, child: const Text('Save')),
                        OutlinedButton(onPressed: _discardChanges, child: const Text('Discard')),
                      ],)
                  ],
                )
              ),
        ],
      ),
    );
  }
}
