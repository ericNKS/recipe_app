class Ingredient {
  final String name;
  final String quantity;

  Ingredient({required this.name, required this.quantity});

  // Converte de Map (do DB) para Objeto
  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'],
      quantity: map['quantity'],
    );
  }

  // Converte de Objeto para Map (para o DB)
  Map<String, dynamic> toMap(int recipeId) {
    return {
      'recipeId': recipeId,
      'name': name,
      'quantity': quantity,
    };
  }
}

class Recipe {
  final int? id;
  final int userId;
  final String name;
  final String? imagePath;
  final String preparationSteps;
  final List<Ingredient> ingredients;

  Recipe({
    this.id,
    required this.userId,
    required this.name,
    this.imagePath,
    required this.preparationSteps,
    required this.ingredients,
  });

  // Converte de Objeto para Map (para o DB)
  // Nota: Isso não inclui os ingredientes, pois eles são salvos em outra tabela.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'imagePath': imagePath,
      'preparationSteps': preparationSteps,
    };
  }

  // Converte de Map (do DB) para Objeto
  factory Recipe.fromMap(Map<String, dynamic> map, List<Ingredient> ingredients) {
    return Recipe(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      imagePath: map['imagePath'],
      preparationSteps: map['preparationSteps'],
      ingredients: ingredients,
    );
  }
}