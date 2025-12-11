
import 'package:flutter/material.dart';

class Goal {
  final String? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final int color;
  final int icon;
  final String notes;
  final DateTime? lastUpdated;
  final double? lastAddedAmount;

  Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.color,
    required this.icon,
    this.notes = '',
    this.lastUpdated,
    this.lastAddedAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'color': color,
      'icon': icon,
      'notes': notes,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'lastAddedAmount': lastAddedAmount,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id']?.toString(), // Handle potential int id from SQLite converted to String
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      savedAmount: (map['savedAmount'] as num?)?.toDouble() ?? 0.0,
      color: map['color'] is int ? map['color'] : (int.tryParse(map['color'].toString()) ?? 0xFF00C4B4),
      icon: map['icon'] is int ? map['icon'] : (int.tryParse(map['icon'].toString()) ?? 57353), // Default to some icon
      notes: map['notes'] ?? '',
      lastUpdated: map['lastUpdated'] != null ? DateTime.tryParse(map['lastUpdated']) : null,
      lastAddedAmount: (map['lastAddedAmount'] as num?)?.toDouble(),
    );
  }

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    int? color,
    int? icon,
    String? notes,
    DateTime? lastUpdated,
    double? lastAddedAmount,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      notes: notes ?? this.notes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastAddedAmount: lastAddedAmount ?? this.lastAddedAmount,
    );
  }
}
