
import 'package:intl/intl.dart';

class ParsedTransaction {
  final double amount;
  final DateTime date;
  final String? description;

  ParsedTransaction({required this.amount, required this.date, this.description});
}

class SmsParser {
  // Pattern 1: Your 498###52401 has been Debited by NPR 1,180.00 on 10/12/2025 18:28:20
  // Pattern 2: 2,500.00 withdrawn from A/C ... on 08/12/2025 11:44
  
  static ParsedTransaction? parse(String text) {
    print("Parsing text: $text");
    
    // Normalize text: remove commas from numbers roughly to make regex easier? 
    // Actually better to handle commas in regex.
    
    // Regex for Amount: Matches "NPR 1,180.00", "Rs. 1,180.00", "1,180.00 withdrawn", "Debited by ... 1,180.00"
    // We look for patterns.
    
    double? amount;
    DateTime? date;
    
    // 1. Try finding Amount
    // Look for "Debited by [Currency?] [Amount]"
    final debitMatch = RegExp(r'Debited by (?:NPR|Rs\.?)\s*([\d,]+\.?\d*)', caseSensitive: false).firstMatch(text);
    if (debitMatch != null) {
      amount = _parseAmount(debitMatch.group(1)!);
    } else {
      // Look for "[Amount] withdrawn"
      final withdrawnMatch = RegExp(r'([\d,]+\.?\d*)\s*withdrawn from', caseSensitive: false).firstMatch(text);
      if (withdrawnMatch != null) {
        amount = _parseAmount(withdrawnMatch.group(1)!);
      }
    }
    
    // 2. Try finding Date
    // Look for "on [dd/mm/yyyy]"
    // Support dd/MM/yyyy
    final dateMatch = RegExp(r'on\s+(\d{2}/\d{2}/\d{4})', caseSensitive: false).firstMatch(text);
    if (dateMatch != null) {
       try {
         date = DateFormat('dd/MM/yyyy').parse(dateMatch.group(1)!);
       } catch (e) {
         print("Date Parse Error: $e");
       }
    }
    
    if (amount != null && date != null) {
      return ParsedTransaction(amount: amount, date: date);
    }
    
    return null;
  }
  
  static double _parseAmount(String raw) {
    // Remove commas
    final clean = raw.replaceAll(',', '');
    return double.tryParse(clean) ?? 0.0;
  }
}
