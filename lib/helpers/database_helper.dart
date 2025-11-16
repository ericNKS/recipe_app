import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:recipe_app/models/recipe_model.dart';
import 'package:recipe_app/models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'recipe_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de Usuários
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Tabela de Receitas
    await db.execute('''
      CREATE TABLE recipes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        name TEXT NOT NULL,
        imagePath TEXT,
        preparationSteps TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Ingredientes
    await db.execute('''
      CREATE TABLE ingredients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId INTEGER NOT NULL,
        name TEXT NOT NULL,
        quantity TEXT NOT NULL,
        FOREIGN KEY (recipeId) REFERENCES recipes(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Funções de Usuário ---

  Future<User?> registerUser(String username, String password) async {
    final db = await database;
    try {
      final id = await db.insert(
        'users',
        {'username': username, 'password': password},
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      return User(id: id, username: username);
    } catch (e) {
      // Retorna null se o usuário já existir (conflito)
      return null;
    }
  }

  Future<User?> loginUser(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePassword(int userId, String newPassword) async {
    final db = await database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // --- Funções de Receita ---

  Future<int> addRecipe(Recipe recipe) async {
    final db = await database;
    // Insere a receita e pega o ID
    final recipeId = await db.insert(
      'recipes',
      recipe.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insere os ingredientes
    for (var ingredient in recipe.ingredients) {
      await db.insert(
        'ingredients',
        ingredient.toMap(recipeId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return recipeId;
  }

  Future<List<Recipe>> getRecipes(int userId) async {
    final db = await database;

    // Pega todas as receitas do usuário
    final List<Map<String, dynamic>> recipeMaps = await db.query(
      'recipes',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );

    if (recipeMaps.isEmpty) {
      return [];
    }

    List<Recipe> recipes = [];
    // Para cada receita, pega seus ingredientes
    for (var recipeMap in recipeMaps) {
      final List<Map<String, dynamic>> ingredientMaps = await db.query(
        'ingredients',
        where: 'recipeId = ?',
        whereArgs: [recipeMap['id']],
      );

      List<Ingredient> ingredients = ingredientMaps.isNotEmpty
          ? ingredientMaps.map((map) => Ingredient.fromMap(map)).toList()
          : [];

      recipes.add(Recipe.fromMap(recipeMap, ingredients));
    }
    return recipes;
  }

  Future<int> updateRecipe(Recipe recipe) async {
    final db = await database;

    await db.update(
      'recipes',
      recipe.toMap(), // Reutiliza o toMap
      where: 'id = ?',
      whereArgs: [recipe.id],
    );

    await db.delete(
      'ingredients',
      where: 'recipeId = ?',
      whereArgs: [recipe.id],
    );

    for (var ingredient in recipe.ingredients) {
      await db.insert(
        'ingredients',
        ingredient.toMap(recipe.id!),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    return recipe.id!;
  }
}