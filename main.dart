import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class User {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String phone;
  final int userStatus;

  User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.phone,
    required this.userStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phone': phone,
      'userStatus': userStatus,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phone: json['phone'] ?? '',
      userStatus: json['userStatus'] ?? 0,
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://petstore.swagger.io/v2';


  Future<User> getUser(String username) async {
    final response = await http.get(Uri.parse('$baseUrl/user/$username'));

    if (response.statusCode == 200) {

      return User.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Пользователь не найден');
    } else {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  }

  Future<bool> createUser(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteUser(String username) async {
    final response = await http.delete(Uri.parse('$baseUrl/user/$username'));
    return response.statusCode == 200;
  }
}

void main() => runApp(const PetStoreApp());

class PetStoreApp extends StatelessWidget {
  const PetStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetStore Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PetStore API Manager'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuButton(
              context,
              title: 'Поиск и удаление',
              icon: Icons.search,
              color: Colors.blueAccent,
              screen: const UserSearchScreen(),
            ),
            const SizedBox(height: 20),
            _buildMenuButton(
              context,
              title: 'Создать пользователя',
              icon: Icons.person_add_alt_1,
              color: Colors.green,
              screen: const CreateUserScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(250, 60),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      icon: Icon(icon),
      label: Text(title),
    );
  }
}

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _api = ApiService();
  User? _foundUser;
  bool _isLoading = false;

  void _onSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final user = await _api.getUser(_searchController.text.trim());
      setState(() => _foundUser = user);
    } catch (e) {
      setState(() => _foundUser = null);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onDelete() async {
    if (_foundUser == null) return;
    final success = await _api.deleteUser(_foundUser!.username);
    if (success) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пользователь удален')));
      setState(() => _foundUser = null);
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поиск пользователя')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Введите Username (напр. user1)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _onSearch),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (_foundUser != null) _buildUserCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Card(
      elevation: 4,
      child: ListTile(
        title: Text('${_foundUser!.firstName} ${_foundUser!.lastName}'),
        subtitle: Text('ID: ${_foundUser!.id}\nEmail: ${_foundUser!.email}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: _onDelete,
        ),
      ),
    );
  }
}

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final ApiService _api = ApiService();

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      final user = User(
        id: int.parse(_idController.text),
        username: _usernameController.text,
        firstName: 'Ivan',
        lastName: 'Ivanov',
        email: _emailController.text,
        password: 'qwerty_password',
        phone: '+79991234567',
        userStatus: 1,
      );

      final success = await _api.createUser(user);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Успешно создано!')));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка при создании')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый пользователь')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'ID (целое число)'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.isEmpty) ? 'Введите ID' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (v) => (v == null || v.isEmpty) ? 'Введите имя' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? 'Некорректный email' : null,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Зарегистрировать'),
            ),
          ],
        ),
      ),
    );
  }
}
