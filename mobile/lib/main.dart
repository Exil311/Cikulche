import 'dart:convert';
import 'package:flutter/foundation.dart'; // Нужно за kIsWeb и defaultTargetPlatform
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- КОНФИГУРАЦИЯ НА АДРЕСИТЕ ---
String getBaseUrl() {
  // 1. Ако сме в Браузър
  if (kIsWeb) return 'http://localhost:8080';
  
  // 2. ВАЖНО ЗА WINDOWS (Error 121 Fix)
  // Windows понякога блокира "localhost", затова използваме директния IP 127.0.0.1
  if (defaultTargetPlatform == TargetPlatform.windows) {
    return 'http://127.0.0.1:8080';
  }

  // 3. За Mac/Linux
  if (defaultTargetPlatform == TargetPlatform.macOS || 
      defaultTargetPlatform == TargetPlatform.linux) {
    return 'http://localhost:8080';
  }

  // 4. Ако сме на Android Emulator
  return 'http://10.0.2.2:8080'; 
}

void main() {
  runApp(const CikulcheApp());
}

class CikulcheApp extends StatelessWidget {
  const CikulcheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cikulche',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE91E63)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// --- 1. ЕКРАН ЗА ВХОД (LOGIN) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = "";

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final url = Uri.parse('${getBaseUrl()}/api/auth/login');
    print("Trying to connect to: $url");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(token: data['token'], userName: data['name'])),
          );
        }
      } else {
        setState(() => _errorMessage = "Грешка (${response.statusCode}): Проверете данните.");
      }
    } catch (e) {
      print("Error: $e");
      // Специално съобщение за грешка 121
      if (e.toString().contains("121")) {
        setState(() => _errorMessage = "Грешка във връзка (Error 121).\nОпитваме се да я оправим с 127.0.0.1.");
      } else {
        setState(() => _errorMessage = "Няма връзка с Backend-а.\nУвери се, че Spring Boot работи!");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop, size: 80, color: Colors.pink),
              const SizedBox(height: 16),
              const Text("Cikulche", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.pink)),
              const SizedBox(height: 40),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Парола", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)), obscureText: true),
              const SizedBox(height: 24),
              if (_errorMessage.isNotEmpty) 
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade50,
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
                      child: const Text("Влез", style: TextStyle(fontSize: 18)),
                    ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text("Нямаш акаунт? Регистрирай се."),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. ЕКРАН ЗА РЕГИСТРАЦИЯ ---
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthYearController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = "";

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "";
    });
    
    final url = Uri.parse('${getBaseUrl()}/api/auth/register');
    print("Trying register at: $url");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _nameController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
          "birthYear": int.tryParse(_birthYearController.text) ?? 2000,
        }),
      );

      print("Register Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(token: data['token'], userName: data['name'])),
          );
        }
      } else {
        setState(() => _statusMessage = "Грешка ${response.statusCode}: Вероятно имейлът е зает!");
      }
    } catch (e) {
      print("Register Error: $e");
      setState(() => _statusMessage = "Грешка при връзка: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Регистрация")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Име", icon: Icon(Icons.person))),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", icon: Icon(Icons.email))),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Парола", icon: Icon(Icons.lock)), obscureText: true),
              TextField(controller: _birthYearController, decoration: const InputDecoration(labelText: "Година на раждане", icon: Icon(Icons.cake)), keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _register, child: const Text("Създай акаунт")),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_statusMessage, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 3. DASHBOARD ---
class HomeScreen extends StatelessWidget {
  final String token;
  final String userName;

  const HomeScreen({super.key, required this.token, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Моят Календар"),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Здравей, $userName! 👋", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Днес е ${DateTime.now().day}.${DateTime.now().month}", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: const Column(
                  children: [
                    Text("Прогноза", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text("Остават ? дни до цикъла", style: TextStyle(fontSize: 22, color: Colors.pink)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text("Бързи действия", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickActionButton(
                    icon: Icons.water_drop, 
                    label: "Дойде ми", 
                    color: Colors.redAccent,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Нов цикъл?"),
                          content: const Text("Искаш ли да маркираш днес като начало на цикъла?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Не")),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Запазено!")));
                              },
                              child: const Text("Да"),
                            ),
                          ],
                        )
                      );
                    }
                  ),
                  _QuickActionButton(
                    icon: Icons.mood, 
                    label: "Симптоми", 
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => SymptomsScreen(token: token))
                      );
                    }
                  ),
                  _QuickActionButton(
                    icon: Icons.chat_bubble, 
                    label: "Чатбот", 
                    color: Colors.purpleAccent,
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Чатботът идва скоро!")));
                    }
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 30)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500))
        ],
      ),
    );
  }
}

// --- 4. ЕКРАН ЗА СИМПТОМИ (Daily Log) ---
class SymptomsScreen extends StatefulWidget {
  final String token;
  const SymptomsScreen({super.key, required this.token});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final List<String> _allSymptoms = ["Главоболие", "Болки в корема", "Подуване", "Акне", "Умора", "Глад за сладко", "Гадене"];
  final Set<String> _selectedSymptoms = {};
  String _bleedingLevel = "NONE"; 
  final TextEditingController _notesController = TextEditingController();

  Future<void> _saveEntry() async {
    final body = {
      "date": DateTime.now().toIso8601String().split('T')[0],
      "bleeding": _bleedingLevel,
      "symptoms": _selectedSymptoms.toList(),
      "mood": "NORMAL", 
      "notes": _notesController.text
    };
    print("Изпращане към Java: $body");
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Записът е запазен локално!")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Как си днес?")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Кървене", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "NONE", label: Text("Няма")),
                ButtonSegment(value: "LIGHT", label: Text("Леко")),
                ButtonSegment(value: "MEDIUM", label: Text("Средно")),
                ButtonSegment(value: "HEAVY", label: Text("Силно")),
              ],
              selected: {_bleedingLevel},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _bleedingLevel = newSelection.first);
              },
            ),
            const SizedBox(height: 30),
            const Text("Симптоми", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: _allSymptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            const Text("Бележки", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _notesController, decoration: const InputDecoration(hintText: "Нещо друго важно?", border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
                child: const Text("ЗАПАЗИ", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}