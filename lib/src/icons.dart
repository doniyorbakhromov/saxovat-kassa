import "package:flutter/material.dart";

/// Mahsulotlar uchun tayyor belgilar to'plami.
/// Kalit ma'lumotlar bazasida saqlanadi, IconData esa shu yerda beriladi.
const Map<String, IconData> kItemIcons = <String, IconData>{
  "pivo": Icons.sports_bar_rounded,
  "kokteyl": Icons.local_bar_rounded,
  "vino": Icons.wine_bar_rounded,
  "aroq": Icons.liquor_rounded,
  "gazli": Icons.local_drink_rounded,
  "suv": Icons.water_drop_rounded,
  "kofe": Icons.local_cafe_rounded,
  "choy": Icons.emoji_food_beverage_rounded,
  "energetik": Icons.bolt_rounded,
  "gazak": Icons.tapas_rounded,
  "baliq": Icons.set_meal_rounded,
  "kartoshka": Icons.fastfood_rounded,
  "fastfud": Icons.lunch_dining_rounded,
  "pizza": Icons.local_pizza_rounded,
  "kabob": Icons.kebab_dining_rounded,
  "taom": Icons.restaurant_rounded,
  "sho'rva": Icons.ramen_dining_rounded,
  "salat": Icons.rice_bowl_rounded,
  "non": Icons.bakery_dining_rounded,
  "shirinlik": Icons.cake_rounded,
  "muzqaymoq": Icons.icecream_rounded,
  "meva": Icons.local_florist_rounded,
  "sigaret": Icons.smoking_rooms_rounded,
  "kalyan": Icons.air_rounded,
  "boshqa": Icons.restaurant_menu_rounded,
};

List<String> get kIconKeys => kItemIcons.keys.toList();

IconData iconFor(String key) =>
    kItemIcons[key] ?? Icons.restaurant_menu_rounded;
