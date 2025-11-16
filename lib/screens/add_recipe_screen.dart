import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:recipe_app/helpers/database_helper.dart';
import 'package:recipe_app/models/recipe_model.dart';
import 'package:recipe_app/providers/auth_provider.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  final _picker = ImagePicker();

  // Controladores para os campos
  final _recipeNameController = TextEditingController();
  final _preparationController = TextEditingController();
  final _ingredientNameController = TextEditingController();
  final _ingredientQtyController = TextEditingController();

  File? _imageFile;
  final List<Ingredient> _ingredients = [];
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _addIngredient() {
    if (_ingredientNameController.text.isNotEmpty &&
        _ingredientQtyController.text.isNotEmpty) {
      setState(() {
        _ingredients.add(Ingredient(
          name: _ingredientNameController.text,
          quantity: _ingredientQtyController.text,
        ));
        _ingredientNameController.clear();
        _ingredientQtyController.clear();
      });
      FocusManager.instance.primaryFocus?.unfocus(); // Esconde o teclado
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate() || _ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Preencha todos os campos e adicione pelo menos 1 ingrediente.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? finalImagePath;
    if (_imageFile != null) {
      // Salva a imagem no diretório do app
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(_imageFile!.path);
      final savedImage = await _imageFile!.copy('${appDir.path}/$fileName');
      finalImagePath = savedImage.path;
    }

    final userId = context.read<AuthProvider>().currentUser!.id;

    final newRecipe = Recipe(
      userId: userId,
      name: _recipeNameController.text,
      preparationSteps: _preparationController.text,
      imagePath: finalImagePath,
      ingredients: _ingredients,
    );

    await _dbHelper.addRecipe(newRecipe);

    if (mounted) {
      setState(() => _isLoading = false);
      // Retorna 'true' para a HomeScreen saber que precisa recarregar
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Receita'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveRecipe,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- NOME DA RECEITA ---
              TextFormField(
                controller: _recipeNameController,
                decoration: const InputDecoration(labelText: 'Nome da Receita'),
                validator: (value) =>
                value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // --- FOTO ---
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                      : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50),
                          Text('Adicionar Foto (Opcional)'),
                        ],
                      )),
                ),
              ),
              const SizedBox(height: 16),

              // --- INGREDIENTES ---
              Text('Ingredientes',
                  style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _ingredientNameController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _ingredientQtyController,
                      decoration: const InputDecoration(labelText: 'Qtd.'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addIngredient,
                  ),
                ],
              ),
              // Lista de ingredientes adicionados
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  itemCount: _ingredients.length,
                  itemBuilder: (context, index) {
                    final ing = _ingredients[index];
                    return ListTile(
                      title: Text(ing.name),
                      subtitle: Text(ing.quantity),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _ingredients.removeAt(index));
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // --- MODO DE PREPARO ---
              TextFormField(
                controller: _preparationController,
                decoration: const InputDecoration(
                  labelText: 'Modo de Preparo',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: 8,
                validator: (value) =>
                value!.isEmpty ? 'Campo obrigatório' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}