class RegexHelper {
  static const email = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const phone = r'^[0-9]{8,15}$';
  static const upi = r'^[\w.\-]{2,}@[a-zA-Z]{2,}$';
  static const iban = r'^[A-Z]{2}[0-9A-Z]{13,32}$';
  static const crypto = r'^[a-zA-Z0-9]{25,100}$';
  static const username = r'^[a-zA-Z0-9._@#]{3,}$';
  static const numberOnly = r'^[0-9]+$';
  static const alphanumeric = r'^[a-zA-Z0-9\s\-_.@#:/?=&]+$';
  static const email_or_iban = r'^([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}|[A-Z]{2}[0-9A-Z]{13,32})$';
  static const email_or_phone = r'^([0-9]{8,15}|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})$';
  static const iban_or_account = r'^[A-Z0-9]{6,34}$';
  static const crypto_with_tag = r'^[a-zA-Z0-9]{25,100}(:[a-zA-Z0-9]{1,20})?$';
  static const bank_account = r'^[A-Z0-9\- ]{6,34}$';
  static const sort_code_account = r'^(\d{6}[- ]?\d{8}|\d{8,20})$';
  static const payment_id = r'^[a-zA-Z0-9._@\-:/]{3,64}$';
  static const wallet_id = r'^[a-zA-Z0-9._\-@]{3,50}$';
  static const link = r'^(https?:\/\/)?[a-zA-Z0-9\-._~:/?#[\]@!$&()*+,;=%]{3,}$';
  static const code = r'^[A-Z0-9\-]{4,20}$';
  static const flexible_id = r'^[a-zA-Z0-9\-_.@#:/]{3,100}$';

  static const phone_or_id = r'^([0-9]{8,15}|[a-zA-Z0-9._\-@]{3,50})$';
  static const bsb_account = r'^\d{3}-?\d{3}\s?\d{6,10}$';
  static const pix_key = r'^([0-9]{11,14}|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}|[a-zA-Z0-9+/]{32,36}=*|\+?[0-9]{10,15})$';
  static const riot_id = r'^[a-zA-Z0-9 ._\-]{3,16}#[a-zA-Z0-9]{3,5}$';
  static const game_tag = r'^#?[A-Z0-9]{5,10}$';
  static const uid = r'^[0-9]{6,15}$';
  static const uid_zone = r'^[0-9]{6,15}(\s*\(\s*[0-9]+\s*\))?$';
  static const ea_id = r'^[a-zA-Z0-9._\- ]{3,30}$';
}
