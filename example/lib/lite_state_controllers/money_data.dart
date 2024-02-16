import 'package:lite_state/lite_state.dart';

class MoneyData implements LSJsonEncodable {
  MoneyData({
    required this.currency,
    required this.amount,
  });

  String currency;
  double amount;

  @override
  Map encode() {
    return {
      'currency': currency,
      'amount': amount,
    };
  }

  @override
  String toString() {
    return '[$runtimeType currency: $currency, amount: $amount]';
  }

  static MoneyData decode(Map map) {
    return MoneyData(
      currency: map['currency'],
      amount: map['amount'],
    );
  }
}
