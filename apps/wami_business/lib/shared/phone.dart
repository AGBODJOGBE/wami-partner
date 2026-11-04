/// Numéros béninois : 8 chiffres (ancien plan) ou 10 chiffres commençant par 01.
String normalizePhone(String raw) => raw.replaceAll(RegExp(r'\D'), '');

bool isValidBeninPhone(String digits) => digits.length == 8 || (digits.length == 10 && digits.startsWith('01'));
