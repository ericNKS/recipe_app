import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/helpers/database_helper.dart';
import 'package:recipe_app/models/recipe_model.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'dart:io'; // Para File
// Importa a nova tela
import 'package:recipe_app/screens/recipe_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Recipe>> _recipesFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  void _loadRecipes() {
    // Pega o ID do usuário logado
    final userId = Provider.of<AuthProvider>(context, listen: false).currentUser!.id;
    setState(() {
      _recipesFuture = _dbHelper.getRecipes(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Receitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/account'),
          ),
        ],
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Você ainda não adicionou nenhuma receita.'),
            );
          }

          final recipes = snapshot.data!;
          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: recipe.imagePath != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.file(
                      File(recipe.imagePath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(Icons.fastfood, size: 50),
                  title: Text(recipe.name),
                  subtitle: Text(
                    recipe.preparationSteps,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    // *** ESTA É A MUDANÇA ***
                    // Navega para a tela de detalhes/edição
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );

                    // Se a receita foi atualizada (retornou true), recarrega
                    if (result == true) {
                      _loadRecipes();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_recipe');
          if (result == true) {
            _loadRecipes();
          }
        },
      ),
    );
  }
}