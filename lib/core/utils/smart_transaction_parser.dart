import '../../domain/entities/transaction.dart';

/// Parsed result from natural language input.
class ParsedTransactionInput {
  const ParsedTransactionInput({
    this.amountPaise,
    this.categoryId,
    this.merchant,
    this.description,
    this.type = TransactionType.expense,
  });

  final int? amountPaise;
  final String? categoryId;
  final String? merchant;
  final String? description;
  final TransactionType type;
}

/// Offline intelligent natural language parser for instant transaction entry.
///
/// Converts human inputs like:
/// - "Dinner 450 at Swiggy" -> {amount: 45000, category: 'cat_food', merchant: 'Swiggy', desc: 'Dinner'}
/// - "Uber to airport 680" -> {amount: 68000, category: 'cat_transport', merchant: 'Uber', desc: 'to airport'}
/// - "Salary from Client 85000" -> {amount: 8500000, category: 'cat_salary', type: income}
abstract final class SmartTransactionParser {
  static final _amountRegex = RegExp(r'(?:₹|rs\.?|inr)?\s*(\d+(?:[.,]\d{1,2})?)\s*(?:₹|rs\.?|inr)?', caseSensitive: false);
  static final _atMerchantRegex = RegExp(r'\b(?:at|via|to|from)\s+([A-Za-z0-9&.\-_]+)', caseSensitive: false);

  static const Map<String, List<String>> _categoryKeywords = {
    'cat_food': [
      'food', 'dinner', 'lunch', 'breakfast', 'snack', 'cafe', 'coffee', 'chai', 'tea',
      'swiggy', 'zomato', 'restaurant', 'mcdonald', 'kfc', 'starbucks', 'pizza', 'burger',
      'subway', 'dominos', 'eat', 'meal', 'biryani',
    ],
    'cat_groceries': [
      'grocery', 'groceries', 'supermarket', 'blinkit', 'zepto', 'instamart', 'bigbasket',
      'dmart', 'milk', 'vegetable', 'fruits', 'veggies', 'ration',
    ],
    'cat_transport': [
      'uber', 'ola', 'rapido', 'metro', 'cab', 'taxi', 'bus', 'auto', 'train', 'flight',
      'petrol', 'toll', 'parking', 'transport',
    ],
    'cat_fuel': [
      'fuel', 'petrol', 'diesel', 'cng', 'hp', 'indian oil', 'bharat petroleum', 'shell',
    ],
    'cat_shopping': [
      'amazon', 'flipkart', 'myntra', 'zara', 'clothes', 'shoes', 'shopping', 'nike',
      'h&m', 'mall', 'purchase',
    ],
    'cat_bills': [
      'bill', 'electricity', 'water', 'wifi', 'broadband', 'airtel', 'jio', 'recharge',
      'subscription', 'netflix', 'spotify', 'prime', 'icloud', 'utility',
    ],
    'cat_rent': [
      'rent', 'maintenance', 'landlord', 'flat', 'room',
    ],
    'cat_health': [
      'medicine', 'doctor', 'hospital', 'pharmacy', 'clinic', 'apollo', 'pharmeasy',
      '1mg', 'gym', 'fitness',
    ],
    'cat_entertainment': [
      'movie', 'cinema', 'pvr', 'inox', 'game', 'concert', 'party', 'outing',
    ],
    'cat_salary': [
      'salary', 'paycheck', 'payroll', 'bonus', 'stipend', 'wages',
    ],
    'cat_freelance': [
      'freelance', 'client', 'contract', 'consulting', 'gig', 'upwork', 'fiverr',
    ],
    'cat_investment': [
      'stocks', 'mutual fund', 'crypto', 'bitcoin', 'zerodha', 'groww', 'sip', 'dividend',
    ],
  };

  /// Parse natural text input into structured transaction fields.
  static ParsedTransactionInput parse(String text) {
    if (text.trim().isEmpty) {
      return const ParsedTransactionInput();
    }

    final lower = text.toLowerCase();

    // 1. Extract Amount
    int? parsedPaise;
    final amountMatch = _amountRegex.firstMatch(text);
    if (amountMatch != null) {
      final rawAmountStr = amountMatch.group(1)?.replaceAll(',', '');
      if (rawAmountStr != null) {
        final amountVal = double.tryParse(rawAmountStr);
        if (amountVal != null) {
          parsedPaise = (amountVal * 100).round();
        }
      }
    }

    // 2. Extract Merchant (Check known brands first, fallback to 'at/via/from' preposition)
    String? merchant;
    const knownMerchants = [
      'Swiggy', 'Zomato', 'Uber', 'Ola', 'Rapido', 'Blinkit', 'Zepto', 'Instamart',
      'Amazon', 'Flipkart', 'Myntra', 'Netflix', 'Spotify', 'Starbucks',
      'McDonalds', 'Dominos', 'Jio', 'Airtel', 'Zerodha', 'Groww', 'Google',
      'Apple', 'Microsoft', 'Decathlon', 'Zara', 'H&M', 'Nike',
    ];
    for (final m in knownMerchants) {
      if (lower.contains(m.toLowerCase())) {
        merchant = m;
        break;
      }
    }

    if (merchant == null) {
      final merchantMatch = _atMerchantRegex.firstMatch(text);
      if (merchantMatch != null) {
        merchant = merchantMatch.group(1)?.trim();
      }
    }


    // 3. Category Detection
    String? categoryId;
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          categoryId = entry.key;
          break;
        }
      }
      if (categoryId != null) break;
    }

    // 4. Determine Type (Income vs Expense)
    var type = TransactionType.expense;
    if (categoryId == 'cat_salary' ||
        categoryId == 'cat_freelance' ||
        lower.contains('received') ||
        lower.contains('refund') ||
        lower.contains('income')) {
      type = TransactionType.income;
    }

    // 5. Clean Description (strip extracted amount tokens)
    String cleanDesc = text;
    if (amountMatch != null) {
      cleanDesc = cleanDesc.replaceFirst(amountMatch.group(0)!, '').trim();
    }
    // Remove extra spaces
    cleanDesc = cleanDesc.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanDesc.isEmpty && merchant != null) {
      cleanDesc = merchant;
    }

    return ParsedTransactionInput(
      amountPaise: parsedPaise,
      categoryId: categoryId,
      merchant: merchant,
      description: cleanDesc.isNotEmpty ? cleanDesc : null,
      type: type,
    );
  }
}
