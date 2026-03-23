import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

const String apiKey = "d1ec0ea8b28e453b8d65195016909659"; // ✅ your key

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'What’s For Dinner?',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFF7E6),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ing1 = TextEditingController();
  final ing2 = TextEditingController();
  final ing3 = TextEditingController();

  String selectedDiet = "none";

  void searchMeals() {
    if (ing1.text.isEmpty ||
        ing2.text.isEmpty ||
        ing3.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter 3 ingredients")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          ingredients:
              "${ing1.text},${ing2.text},${ing3.text}",
          diet: selectedDiet,
        ),
      ),
    );
  }

  Widget dietChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedDiet == label,
      onSelected: (_) {
        setState(() {
          selectedDiet = label;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("What’s For Dinner?")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: ing1, decoration: const InputDecoration(labelText: "Ingredient 1")),
            TextField(controller: ing2, decoration: const InputDecoration(labelText: "Ingredient 2")),
            TextField(controller: ing3, decoration: const InputDecoration(labelText: "Ingredient 3")),

            const SizedBox(height: 20),

            Wrap(
              spacing: 10,
              children: [
                dietChip("vegetarian"),
                dietChip("vegan"),
                dietChip("gluten free"),
                dietChip("none"),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: searchMeals,
              child: const Text("Find Meals"),
            )
          ],
        ),
      ),
    );
  }
}

class ResultsScreen extends StatefulWidget {
  final String ingredients;
  final String diet;

  const ResultsScreen({
    super.key,
    required this.ingredients,
    required this.diet,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List recipes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    final url =
        "https://api.spoonacular.com/recipes/findByIngredients"
        "?ingredients=${widget.ingredients}"
        "&number=5"
        "&diet=${widget.diet == "none" ? "" : widget.diet}"
        "&apiKey=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

    "STATUS: ${response.statusCode}";
      ("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          recipes = data;
          loading = false;
        });
      } else {
        throw Exception("Failed to load recipes");
      }
    } catch (e) {
      ("ERROR: $e");
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Results")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : recipes.isEmpty
              ? const Center(child: Text("No recipes found 😢"))
              : ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final r = recipes[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: Image.network(
                          r["image"],
                          width: 60,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.image),
                        ),
                        title: Text(r["title"] ?? "No title"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(
                                id: r["id"],
                                title: r["title"],
                                image: r["image"],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class RecipeDetailScreen extends StatefulWidget {
  final int id;
  final String title;
  final String image;

  const RecipeDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.image,
  });

  @override
  State<RecipeDetailScreen> createState() =>
      _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map data = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    final url =
        "https://api.spoonacular.com/recipes/${widget.id}/information?apiKey=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          data = jsonDecode(response.body);
          loading = false;
        });
      } else {
        throw Exception("Failed to load details");
      }
    } catch (e) {
      ("ERROR: $e");
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    widget.image,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.image, size: 100),
                  ),

                  const SizedBox(height: 10),

                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Ingredients",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),

                  ...(data["extendedIngredients"] ?? [])
                      .map<Widget>((ing) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text("• ${ing["original"]}"),
                          )),

                  const SizedBox(height: 10),

                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Steps",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      data["instructions"] ??
                          "No instructions available",
                    ),
                  )
                ],
              ),
            ),
    );
  }
}