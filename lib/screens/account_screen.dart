import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/helpers/database_helper.dart';
import 'package:recipe_app/providers/auth_provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    if (_passwordController.text.isEmpty ||
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('As senhas não coincidem ou estão vazias.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final userId = context.read<AuthProvider>().currentUser!.id;
    await _dbHelper.updatePassword(userId, _passwordController.text);

    if (mounted) {
      setState(() => _isLoading = false);
      _passwordController.clear();
      _confirmPasswordController.clear();
      FocusManager.instance.primaryFocus?.unfocus(); // Esconde o teclado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha atualizada com sucesso!')),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Assiste (watch) às mudanças no AuthProvider
    final authProvider = context.watch<AuthProvider>();
    final username = authProvider.currentUser?.username ?? 'Usuário';

    return Scaffold(
      appBar: AppBar(title: const Text('Minha Conta')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 80),
                const SizedBox(height: 16),
                Text(
                  'Logado como: $username',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),

                // --- Formulário de Alteração de Senha ---
                Text('Alterar Senha',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Nova Senha'),
                  obscureText: true,
                ),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirmar Nova Senha'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _updatePassword,
                  child: const Text('Salvar Nova Senha'),
                ),

                // --- Botão de Logout ---
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Logout (Sair)'),
                  onPressed: () {
                    context.read<AuthProvider>().logout();
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}