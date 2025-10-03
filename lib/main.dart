
import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:another_telephony/telephony.dart';
import 'alert_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e, s) {
    developer.log('Firebase initialization failed', name: 'main', error: e, stackTrace: s);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anzen',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  String _alertStatus = 'SAFE';
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref('test/status');
  List<Contact> _emergencyContacts = [];
  StreamSubscription<DatabaseEvent>? _alertSubscription;
  Position? _currentPosition;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _activateAlertListener();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _activateAlertListener() {
    _alertSubscription = _databaseReference.onValue.listen((event) {
      if (!mounted) return;
      try {
        final data = event.snapshot.value;
        developer.log('Alert data received: $data', name: 'FirebaseListener');
        if (data != null && data == 'ALERT') {
          if (_alertStatus != 'ALERT') {
            setState(() {
              _alertStatus = 'ALERT';
            });
            Future.delayed(const Duration(milliseconds: 100), () {
              _sendSmsDirectly();
            });
          }
        } else {
          if (_alertStatus != 'SAFE') {
            setState(() {
              _alertStatus = 'SAFE';
            });
          }
        }
      } catch (e, s) {
        developer.log('Error processing alert data', name: 'FirebaseListener', error: e, stackTrace: s);
      }
    }, onError: (error, stackTrace) {
      developer.log('Error in alert stream', name: 'FirebaseListener', error: error, stackTrace: stackTrace);
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!await Permission.location.isGranted) {
        await Permission.location.request();
      }
      if (await Permission.location.isGranted) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      } else {
         if (mounted) {
          setState(() {
            _currentPosition = null;
          });
        }
      }
    } catch (e,s) {
       developer.log('Error getting location', name: 'Location', error: e, stackTrace: s);
       if (mounted) {
          setState(() {
            _currentPosition = null;
          });
        }
    }
  }


  Future<void> _sendSmsDirectly() async {
    if (_emergencyContacts.isEmpty) {
      developer.log('No emergency contacts selected, skipping direct SMS.', name: 'SendSmsDirectly');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No emergency contacts to alert. Please select contacts.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_currentPosition == null) {
      developer.log('Location not available. Cannot send SMS.', name: 'SendSmsDirectly');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location not available. Cannot send alert.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final Telephony telephony = Telephony.instance;
      final message = 'EMERGENCY! I need help! My current location is: https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}';
      List<String> recipients = _emergencyContacts
          .where((c) => c.phones.isNotEmpty)
          .map((c) => c.phones.first.number)
          .toList();

      if (recipients.isEmpty) {
        developer.log('No contacts with phone numbers.', name: 'SendSmsDirectly');
        return;
      }

      for (String recipient in recipients) {
        await telephony.sendSms(
          to: recipient,
          message: message,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Direct SMS sent to emergency contacts!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, s) {
      developer.log('Error sending direct SMS', name: 'SendSmsDirectly', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while sending the direct SMS: $e')),
        );
      }
    }
  }

  void _testEmergency() {
    _databaseReference.set('ALERT');
  }

  @override
  Widget build(BuildContext context) {
    final isAlert = _alertStatus == 'ALERT';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anzen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlertHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            
            isAlert 
            ? FadeTransition(
                opacity: _animationController,
                child: const Text(
                  'ALERT! EMERGENCY!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const Text(
                'Status: SAFE',
                 textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 20),
            
            Text(
              _currentPosition != null 
                ? 'Location: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                : 'Location: Getting location...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 40),

            Text(
              '${_emergencyContacts.length} emergency contacts selected.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _testEmergency,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('TEST EMERGENCY', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _getCurrentLocation,
               style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Get Current Location', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final selectedContacts = await Navigator.push<List<Contact>>(
            context,
            MaterialPageRoute(builder: (context) => const ContactsScreen()),
          );
          if (selectedContacts != null) {
            if (!mounted) return;
            setState(() {
              _emergencyContacts = selectedContacts;
            });
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${selectedContacts.length} contacts selected.')),
            );
          }
        },
        tooltip: 'Select Contacts',
        child: const Icon(Icons.contacts),
      ),
    );
  }
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact>? _contacts;
  final List<Contact> _selectedContacts = [];
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _getContacts();
  }

  Future<void> _getContacts() async {
    try {
       if (!await Permission.contacts.isGranted) {
        if (await Permission.contacts.request().isDenied) {
           if (!mounted) return;
          setState(() {
            _permissionDenied = true;
          });
          return;
        }
      }

      final contacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: false);
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
      });

    } catch (e, s) {
      developer.log('Error getting contacts', name: 'ContactsScreen', error: e, stackTrace: s);
      if (!mounted) return;
      setState(() {
        _permissionDenied = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Emergency Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_selectedContacts.length > 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You can only select up to 5 contacts.'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                Navigator.pop(context, _selectedContacts);
              }
            },
          ),
        ],
      ),
      body: switch (_contacts) {
        null when _permissionDenied => const Center(child: Text('Permission to access contacts was denied.')),
        null => const Center(child: CircularProgressIndicator()),
        final contacts => ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final isSelected = _selectedContacts.any((c) => c.id == contact.id);
              return CheckboxListTile(
                title: Text(contact.displayName),
                subtitle: Text(contact.phones.isNotEmpty ? contact.phones.first.number : 'No phone number'),
                value: isSelected,
                onChanged: contact.phones.isEmpty ? null : (bool? value) {
                  if (!mounted) return;
                  setState(() {
                    if (value == true) {
                      _selectedContacts.add(contact);
                    } else {
                      _selectedContacts.removeWhere((c) => c.id == contact.id);
                    }
                  });
                },
              );
            },
          ),
      },
    );
  }
}
