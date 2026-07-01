import 'package:flutter/material.dart';

class CategoryUiInfo {
  final IconData icon;
  final Color color;

  const CategoryUiInfo(this.icon, this.color);
}

class CategoryUiMapper {
  CategoryUiMapper._();

  static CategoryUiInfo getUiInfo(String category) {
    switch (category) {
      case 'Supermarkets & Food':
        return const CategoryUiInfo(Icons.local_grocery_store_rounded, Colors.green);
      case 'Restaurants & Bars':
        return const CategoryUiInfo(Icons.restaurant_rounded, Colors.orange);
      case 'Fast Food':
        return const CategoryUiInfo(Icons.fastfood_rounded, Colors.deepOrange);
      case 'Transport':
        return const CategoryUiInfo(Icons.directions_bus_rounded, Colors.blue);
      case 'Gas Stations':
        return const CategoryUiInfo(Icons.local_gas_station_rounded, Colors.blueGrey);
      case 'Electronics':
        return const CategoryUiInfo(Icons.computer_rounded, Colors.indigo);
      case 'Clothing & Accessories':
        return const CategoryUiInfo(Icons.checkroom_rounded, Colors.purple);
      case 'Pharmacies & Health':
        return const CategoryUiInfo(Icons.local_pharmacy_rounded, Colors.redAccent);
      case 'Hotels & Travel':
        return const CategoryUiInfo(Icons.flight_rounded, Colors.lightBlue);
      case 'Entertainment':
        return const CategoryUiInfo(Icons.movie_rounded, Colors.pink);
      case 'Stationery & Office':
        return const CategoryUiInfo(Icons.push_pin_rounded, Colors.amber);
      case 'Utilities & Telecom':
        return const CategoryUiInfo(Icons.wifi_rounded, Colors.cyan);
      case 'Auto & Vehicles':
        return const CategoryUiInfo(Icons.directions_car_rounded, Colors.teal);
      case 'Beauty & Personal Care':
        return const CategoryUiInfo(Icons.spa_rounded, Colors.pinkAccent);
      case 'Home & Garden':
        return const CategoryUiInfo(Icons.home_rounded, Colors.brown);
      case 'Education':
        return const CategoryUiInfo(Icons.school_rounded, Colors.deepPurple);
      case 'Finance & Insurance':
        return const CategoryUiInfo(Icons.account_balance_rounded, Colors.greenAccent);
      case 'Government & Taxes':
        return const CategoryUiInfo(Icons.gavel_rounded, Colors.blueGrey);
      case 'Charity & Social':
        return const CategoryUiInfo(Icons.volunteer_activism_rounded, Colors.red);
      case 'Other':
      default:
        return const CategoryUiInfo(Icons.category_rounded, Colors.grey);
    }
  }
}
