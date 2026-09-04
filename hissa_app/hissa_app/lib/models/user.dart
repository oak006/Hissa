/// The demo user. Populated by the fake KYC flow; nothing here is persisted.
class DemoUser {
  final String nameAr;
  final String nameEn;
  final String phone;
  final bool verified;
  final String riskProfileKey;

  const DemoUser({
    this.nameAr = 'نور',
    this.nameEn = 'Nour',
    this.phone = '+20 10 1234 5678',
    this.verified = true,
    this.riskProfileKey = 'risk_balanced',
  });

  String name(bool isAr) => isAr ? nameAr : nameEn;

  DemoUser copyWith({String? phone, bool? verified, String? riskProfileKey}) =>
      DemoUser(
        nameAr: nameAr,
        nameEn: nameEn,
        phone: phone ?? this.phone,
        verified: verified ?? this.verified,
        riskProfileKey: riskProfileKey ?? this.riskProfileKey,
      );
}
