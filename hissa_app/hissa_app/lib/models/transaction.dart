enum TxType { deposit, convert, buy, sell, dividend }

enum TxStatus { completed, pending }

class Txn {
  final String id;
  final TxType type;
  final DateTime at;
  final String? ticker;
  final double? fraction;
  final double? amountEgp;
  final double? amountUsd;
  final TxStatus status;

  const Txn({
    required this.id,
    required this.type,
    required this.at,
    this.ticker,
    this.fraction,
    this.amountEgp,
    this.amountUsd,
    this.status = TxStatus.completed,
  });

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
    id: j['id'] as String,
    type: TxType.values.firstWhere(
      (t) => t.name == j['type'],
      orElse: () => TxType.deposit,
    ),
    at: DateTime.parse(j['at'] as String),
    ticker: j['ticker'] as String?,
    fraction: (j['fraction'] as num?)?.toDouble(),
    amountEgp: (j['amount_egp'] as num?)?.toDouble(),
    amountUsd: (j['amount_usd'] as num?)?.toDouble(),
    status: TxStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => TxStatus.completed,
    ),
  );

  String get labelKey => switch (type) {
    TxType.deposit => 'tx_deposit',
    TxType.convert => 'tx_convert',
    TxType.buy => 'tx_buy',
    TxType.sell => 'tx_sell',
    TxType.dividend => 'tx_dividend',
  };

  /// Money in is positive, money out is negative — drives the sign and colour.
  bool get isCredit =>
      type == TxType.deposit || type == TxType.sell || type == TxType.dividend;
}
