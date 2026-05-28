import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/features/wallet_module/model/sc_wallet_models.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/regex_helper.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:flutter/material.dart';

class ScWalletProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _db = Injector.instance<AppDB>();

  List<ScWalletCategory>? _categoriesCache;

  /// Built once per provider instance — the lists are large and rebuilding
  /// them on every `notifyListeners` made the tab-switch noticeably laggy.
  List<ScWalletCategory> getWalletCategories(BuildContext context) =>
      _categoriesCache ??= _buildCategories();

  List<ScWalletCategory> _buildCategories() => [
    ScWalletCategory(
      title: 'Cash',
      items: [
        ScWalletItem(
          "PayPal",
          Icon(Icons.paypal, size: AppSize.w24, color: Color(0xFF2559ca)),
          Color(0xFF2559ca),
          ScFormData(
            "Enter PayPal Email",
            Icon(Icons.payment, size: AppSize.w24, color: Color(0xFF2559ca)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Wise",
          Icon(
            Icons.flag_outlined,
            size: AppSize.w24,
            color: Color(0xFF00aeff),
          ),
          Color(0xFF00aeff),
          ScFormData(
            "Email / IBAN",
            Icon(
              Icons.account_balance_sharp,
              size: 24,
              color: Color(0xFF00aeff),
            ),
            RegexHelper.email_or_iban,
          ),
        ),
        ScWalletItem(
          "Payoneer",
          Icon(
            Icons.repeat_on_sharp,
            size: AppSize.w24,
            color: Color(0xFFff4000),
          ),
          Color(0xFFff4000),
          ScFormData(
            "Payoneer Email",
            Icon(Icons.email_sharp, size: 24, color: Color(0xFFff4000)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Skrill",
          Icon(
            Icons.local_play_sharp,
            size: AppSize.w24,
            color: Color(0xFFb82986),
          ),
          Color(0xFFb82986),
          ScFormData(
            "Skrill Email",
            Icon(Icons.email_sharp, size: 24, color: Color(0xFFb82986)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Apple Pay",
          Icon(Icons.apple, size: AppSize.w24, color: Color(0xFF0E1A2B)),
          Color(0xFF0E1A2B),
          ScFormData(
            "Apple ID",
            Icon(Icons.phone_android_sharp, size: 24, color: Color(0xFF0E1A2B)),
            RegexHelper.email_or_phone,
          ),
        ),
        ScWalletItem(
          "Google Wallet",
          Assets.cashWithdrawIcons.scIcGooglewallet.image(width: AppSize.w24),
          Color(0xFF3a7af2),
          ScFormData(
            "Google Pay Number",
            Icon(Icons.email_sharp, size: 24, color: Color(0xFF3a7af2)),
            RegexHelper.email_or_phone,
          ),
        ),
        ScWalletItem(
          "Samsung Wallet",
          Icon(
            Icons.phone_android,
            size: AppSize.w24,
            color: Color(0xFF43a546),
          ),
          Color(0xFF43a546),
          ScFormData(
            "Samsung Pay ID",
            Icon(Icons.email_sharp, size: 24, color: Color(0xFF43a546)),
            RegexHelper.alphanumeric,
          ),
        ),
        ScWalletItem(
          "Wells Fargo",
          Icon(
            Icons.account_balance_outlined,
            size: AppSize.w24,
            color: Color(0xFFf68819),
          ),
          Color(0xFFf68819),
          ScFormData(
            "Account Number",
            Icon(
              Icons.account_balance_sharp,
              size: 24,
              color: Color(0xFFf68819),
            ),
            RegexHelper.iban_or_account,
          ),
        ),

        // Europe / Asia wallets
        ScWalletItem(
          "Alipay",
          Assets.cashWithdrawIcons.scIcAlipay.svg(width: AppSize.w24),
          Color(0xFF166bff),
          ScFormData(
            "Alipay ID",
            Icon(Icons.qr_code, size: 24, color: Color(0xFF166bff)),
            RegexHelper.wallet_id,
          ),
        ),
        ScWalletItem(
          "WeChat Pay",
          Icon(Icons.wechat, size: AppSize.w24, color: Color(0xFF009e5f)),
          Color(0xFF009e5f),
          ScFormData(
            "WeChat ID",
            Icon(Icons.message, size: 24, color: Color(0xFF009e5f)),
            RegexHelper.wallet_id,
          ),
        ),
        ScWalletItem(
          "UPI",
          Icon(Icons.qr_code_2, size: AppSize.w24, color: Color(0xFFFF7900)),
          Color(0xFFFF7900),
          ScFormData(
            "UPI ID (vpa)",
            Icon(Icons.alternate_email, size: 24, color: Color(0xFFFF7900)),
            RegexHelper.upi,
          ),
        ),
        ScWalletItem(
          "PhonePe Number",
          Icon(
            Icons.local_parking_outlined,
            size: AppSize.w24,
            color: Color(0xFF6F2C91),
          ),
          Color(0xFF6F2C91),
          ScFormData(
            "PhonePe Number",
            Icon(Icons.call, size: 24, color: Color(0xFF6F2C91)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "Paytm",
          Icon(Icons.credit_card, size: AppSize.w24, color: Color(0xFF00AEEF)),
          Color(0xFF00AEEF),
          ScFormData(
            "Paytm Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00AEEF)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "GCash",
          Icon(Icons.wallet, size: AppSize.w24, color: Color(0xFF0066FF)),
          Color(0xFF0066FF),
          ScFormData(
            "GCash Number",
            Icon(Icons.call, size: 24, color: Color(0xFF0066FF)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "GrabPay",
          Icon(
            Icons.local_taxi_rounded,
            size: AppSize.w24,
            color: Color(0xFF00A651),
          ),
          Color(0xFF00A651),
          ScFormData(
            "Grab Registered Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00A651)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "KakaoPay",
          Icon(Icons.chat_bubble, size: AppSize.w24, color: Color(0xFFFFCC00)),
          Color(0xFFFFCC00),
          ScFormData(
            "Kakao ID",
            Icon(Icons.chat_bubble, size: 24, color: Color(0xFFFFCC00)),
            RegexHelper.wallet_id,
          ),
        ),
        ScWalletItem(
          "PayPay",
          Icon(
            Icons.local_parking_outlined,
            size: AppSize.w24,
            color: Color(0xFFE30613),
          ),
          Color(0xFFE30613),
          ScFormData(
            "PayPay ID",
            Icon(Icons.qr_code, size: 24, color: Color(0xFFE30613)),
            RegexHelper.wallet_id,
          ),
        ),
        ScWalletItem(
          "Easypaisa",
          Icon(
            Icons.account_balance_wallet_rounded,
            size: AppSize.w24,
            color: Color(0xFF00B14F),
          ),
          Color(0xFF00B14F),
          ScFormData(
            "Easypaisa Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00B14F)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "SadaPay",
          Icon(Icons.credit_card, size: AppSize.w24, color: Colors.indigo),
          Colors.indigo,
          ScFormData(
            "SadaPay Account",
            Icon(Icons.call, size: 24, color: Colors.indigo),
            RegexHelper.phone_or_id,
          ),
        ),
        ScWalletItem(
          "bKash",
          Icon(
            Icons.money_outlined,
            size: AppSize.w24,
            color: Color(0xFFf54293),
          ),
          Color(0xFFf54293),
          ScFormData(
            "bKash Number",
            Icon(Icons.call, size: 24, color: Color(0xFFf54293)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "CallFin",
          Icon(
            Icons.phone_android,
            size: AppSize.w24,
            color: Color(0xFF00A86B),
          ),
          Color(0xFF00A86B),
          ScFormData(
            "CallFin Number",
            Icon(Icons.email_sharp, size: 24, color: Color(0xFF00A86B)),
            RegexHelper.phone_or_id,
          ),
        ),
        ScWalletItem(
          "Revolut",
          Assets.cashWithdrawIcons.scIcRevolut.image(width: AppSize.w24),
          Color(0xFF0066FF),
          ScFormData(
            "Ravtag / IBAN",
            Icon(Icons.tag, size: 24, color: Color(0xFF0066FF)),
            RegexHelper.email_or_iban,
          ),
        ),
        ScWalletItem(
          "Monzo",
          Assets.cashWithdrawIcons.scIcMonzo.image(width: AppSize.w24),
          Color(0xFF1A2E5A),
          ScFormData(
            "Account / Sort Code",
            Icon(
              Icons.account_balance_sharp,
              size: 24,
              color: Color(0xFF1A2E5A),
            ),
            RegexHelper.sort_code_account,
          ),
        ),
        ScWalletItem(
          "N26",
          Assets.cashWithdrawIcons.scIcN26.image(width: AppSize.w24),
          Color(0xFF00C1B2),
          ScFormData(
            "IBAN",
            Icon(
              Icons.account_balance_sharp,
              size: 24,
              color: Color(0xFF00C1B2),
            ),
            RegexHelper.iban,
          ),
        ),
        ScWalletItem(
          "Bunq",
          Icon(Icons.savings, size: AppSize.w24, color: Color(0xFFeb7a8d)),
          Color(0xFFeb7a8d),
          ScFormData(
            "IBAN / Email",
            Icon(Icons.mail, size: 24, color: Color(0xFFeb7a8d)),
            RegexHelper.email_or_iban,
          ),
        ),
        ScWalletItem(
          "Starling Bank",
          Assets.cashWithdrawIcons.scIcStarlingbank.svg(width: AppSize.w24),
          Color(0xFF00b9aa),
          ScFormData(
            "Account Number",
            Icon(Icons.tag, size: 24, color: Color(0xFF00b9aa)),
            RegexHelper.sort_code_account,
          ),
        ),
        ScWalletItem(
          "iDEAL",
          Assets.cashWithdrawIcons.scIcIdeal.svg(width: AppSize.w24),
          Color(0xFFFFFFFF),
          ScFormData(
            "IBAN",
            Icon(
              Icons.account_balance_sharp,
              size: 24,
              color: Color(0xFFFFFFFF),
            ),
            RegexHelper.iban,
          ),
        ),
        ScWalletItem(
          "Tikkie",
          Assets.cashWithdrawIcons.scIcTikkie.svg(width: AppSize.w24),
          Color(0xFFff5f00),
          ScFormData(
            "Tikkie Link/Number",
            Icon(Icons.link, size: 24, color: Color(0xFFff5f00)),
            RegexHelper.link,
          ),
        ),
        ScWalletItem(
          "Vipps",
          Assets.cashWithdrawIcons.scIcVipps.svg(width: AppSize.w24),
          Color(0xFFff5020),
          ScFormData(
            "Vipps Number",
            Icon(Icons.call, size: 24, color: Color(0xFFff5f00)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "MobilePay",
          Assets.cashWithdrawIcons.scIcMobilepay.svg(width: AppSize.w24),
          Color(0xFF00509b),
          ScFormData(
            "MobilePay Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00509b)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "Swish",
          Assets.cashWithdrawIcons.scIcSwish.svg(width: AppSize.w24),
          Color(0xFF02ab81),
          ScFormData(
            "Swish Number",
            Icon(Icons.call, size: 24, color: Color(0xFF02ab81)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "BLIK",
          Assets.cashWithdrawIcons.scIcBlik.svg(width: AppSize.w24),
          Color(0xFFfc342a),
          ScFormData(
            "BLIK Code",
            Icon(Icons.tag, size: 24, color: Color(0xFFfc342a)),
            RegexHelper.code,
          ),
        ),
        ScWalletItem(
          "Lydia",
          Assets.cashWithdrawIcons.scIcLydia.svg(width: AppSize.w24),
          Color(0xFF612670),
          ScFormData(
            "Lydia Number",
            Icon(Icons.call, size: 24, color: Color(0xFF612670)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "PayLib",
          Assets.cashWithdrawIcons.scIcPaylib.svg(width: AppSize.w24),
          Color(0xFF3c4985),
          ScFormData(
            "PayLib Number",
            Icon(Icons.call, size: 24, color: Color(0xFF3c4985)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "Twint",
          Assets.cashWithdrawIcons.scIcTwint.svg(width: AppSize.w24),
          Color(0xFF652786),
          ScFormData(
            "Twint Number",
            Icon(Icons.call, size: 24, color: Color(0xFF652786)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "Satispay",
          Assets.cashWithdrawIcons.scIcSatispay.svg(width: AppSize.w24),
          Color(0xFFff5035),
          ScFormData(
            "Satispay Number",
            Icon(Icons.call, size: 24, color: Color(0xFFff5035)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "iyzico",
          Assets.cashWithdrawIcons.scIcIyzico.svg(width: AppSize.w24),
          Color(0xFF2882ff),
          ScFormData(
            "Account ID",
            Icon(Icons.account_circle, size: 24, color: Color(0xFF2882ff)),
            RegexHelper.flexible_id,
          ),
        ),

        // Africa / Middle East
        ScWalletItem(
          "M-Pesa",
          Assets.cashWithdrawIcons.scIcMpesa.svg(width: AppSize.w24),
          Color(0xFF009c46),
          ScFormData(
            "M-Pesa Number",
            Icon(Icons.call, size: 24, color: Color(0xFF009c46)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "OPay",
          Assets.cashWithdrawIcons.scIcOpay.svg(width: AppSize.w24),
          Color(0xFF1DC45A),
          ScFormData(
            "OPay Number",
            Icon(Icons.call, size: 24, color: Color(0xFF1DC45A)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "Orange Money",
          Assets.cashWithdrawIcons.scIcOrangemoney.svg(width: AppSize.w24),
          Color(0xFFFF7900),
          ScFormData(
            "Orange Money Number",
            Icon(Icons.call, size: 24, color: Color(0xFFFF7900)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "MTN Mobile",
          Assets.cashWithdrawIcons.scIcMynmobile.svg(width: AppSize.w24),
          Color(0xFFFFCC00),
          ScFormData(
            "MTN Mobile Number",
            Icon(Icons.cell_tower, size: 24, color: Color(0xFFFFCC00)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "Chipper Cash",
          Assets.cashWithdrawIcons.scIcChippercash.svg(width: AppSize.w24),
          Color(0xFF0066FF),
          ScFormData(
            "Chipper Tag",
            Icon(Icons.alternate_email, size: 24, color: Color(0xFF0066FF)),
            RegexHelper.wallet_id,
          ),
        ),
        ScWalletItem(
          "Moniepoint",
          Icon(Icons.dialpad, size: 24, color: Color(0xFFFFCC00)),
          Color(0xFFFFCC00),
          ScFormData(
            "Account Number",
            Icon(Icons.tag, size: 24, color: Color(0xFFFFCC00)),
            RegexHelper.numberOnly,
          ),
        ),

        // India / Africa banks
        ScWalletItem(
          "Baxi",
          Assets.cashWithdrawIcons.scIcBaxi.svg(width: AppSize.w24),
          Color(0xFF007BFF),
          ScFormData(
            "Baxi Account",
            Icon(Icons.tag, size: 24, color: Color(0xFF007BFF)),
            RegexHelper.numberOnly,
          ),
        ),
        ScWalletItem(
          "Capitec Pay",
          Assets.cashWithdrawIcons.scIcCapitecpay.svg(width: AppSize.w24),
          Color(0xFF00B14F),
          ScFormData(
            "ID / Phone",
            Icon(
              Icons.account_circle_outlined,
              size: 24,
              color: Color(0xFF00B14F),
            ),
            RegexHelper.phone_or_id,
          ),
        ),
        ScWalletItem(
          "SnapScan",
          Assets.cashWithdrawIcons.scIcSnapscan.svg(width: AppSize.w24),
          Color(0xFF0033A0),
          ScFormData(
            "SnapScan ID",
            Icon(Icons.qr_code, size: 24, color: Color(0xFF0033A0)),
            RegexHelper.wallet_id,
          ),
        ),
        ScWalletItem(
          "NatsWallet",
          Assets.cashWithdrawIcons.scIcNasswallet.svg(width: AppSize.w24),
          Color(0xFFF5A623),
          ScFormData(
            "Card/Account",
            Icon(
              Icons.compare_arrows_outlined,
              size: 24,
              color: Color(0xFFF5A623),
            ),
            RegexHelper.iban_or_account,
          ),
        ),
        ScWalletItem(
          "Onafriq",
          Assets.cashWithdrawIcons.scIcOnafriq.svg(width: AppSize.w24),
          Color(0xFFE53935),
          ScFormData(
            "User ID",
            Icon(
              Icons.account_circle_outlined,
              size: 24,
              color: Color(0xFFE53935),
            ),
            RegexHelper.flexible_id,
          ),
        ),

        // Middle East
        ScWalletItem(
          "STC Pay",
          Assets.cashWithdrawIcons.scIcStcpay.svg(width: AppSize.w24),
          Color(0xFF6A1B9A),
          ScFormData(
            "STC Pay Number",
            Icon(Icons.call, size: 24, color: Color(0xFF6A1B9A)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "Vodafone Cash",
          Assets.cashWithdrawIcons.scIcVodafonecash.svg(width: AppSize.w24),
          Color(0xFFE60000),
          ScFormData(
            "Vodafone Number",
            Icon(Icons.call, size: 24, color: Color(0xFFE60000)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "Careem Pay",
          Assets.cashWithdrawIcons.scIcCareempay.svg(width: AppSize.w24),
          Color(0xFF00C853),
          ScFormData(
            "Careem Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00C853)),
            RegexHelper.phone,
          ),
        ),

        // Egypt
        ScWalletItem(
          "InstaPay",
          Assets.cashWithdrawIcons.scIcInstapay.svg(width: AppSize.w24),
          Color(0xFF0070BA),
          ScFormData(
            "InstaPay Address",
            Icon(Icons.alternate_email, size: 24, color: Color(0xFF0070BA)),
            RegexHelper.payment_id,
          ),
        ),
        ScWalletItem(
          "myfawry",
          Assets.cashWithdrawIcons.scIcMyfawry.svg(width: AppSize.w24),
          Color(0xFFF9B233),
          ScFormData(
            "Fawry Number",
            Icon(Icons.call, size: 24, color: Color(0xFFF9B233)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "BenefitPay",
          Assets.cashWithdrawIcons.scIcBenefitpay.svg(width: AppSize.w24),
          Color(0xFF00A3E0),
          ScFormData(
            "BenefitPay Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00A3E0)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "Meeza",
          Assets.cashWithdrawIcons.scIcMeeza.svg(width: AppSize.w24),
          Color(0xFF009639),
          ScFormData(
            "Meeza Card/Wallet",
            Icon(Icons.credit_card, size: 24, color: Color(0xFF009639)),
            RegexHelper.iban_or_account,
          ),
        ),
        ScWalletItem(
          "valU",
          Assets.cashWithdrawIcons.scIcValu.svg(width: AppSize.w24),
          Color(0xFF0088FF),
          ScFormData(
            "valU Account",
            Icon(Icons.call, size: 24, color: Color(0xFF0088FF)),
            RegexHelper.phone_or_id,
          ),
        ),

        // LATAM
        ScWalletItem(
          "Nubank",
          Assets.cashWithdrawIcons.scIcNubank.svg(width: AppSize.w24),
          Color(0xFF8A05BE),
          ScFormData(
            "Pix Key / Account",
            Icon(Icons.add_box_sharp, size: 24, color: Color(0xFF8A05BE)),
            RegexHelper.pix_key,
          ),
        ),
        ScWalletItem(
          "PicPay",
          Assets.cashWithdrawIcons.scIcPicpay.svg(width: AppSize.w24),
          Color(0xFF21C25E),
          ScFormData(
            "PicPay Username / Pix",
            Icon(Icons.alternate_email, size: 24, color: Color(0xFF21C25E)),
            RegexHelper.pix_key,
          ),
        ),
        ScWalletItem(
          "Mercado Pago",
          Assets.cashWithdrawIcons.scIcMercadopago.svg(width: AppSize.w24),
          Color(0xFF009EE3),
          ScFormData(
            "Email / CVU",
            Icon(Icons.mail, size: 24, color: Color(0xFF009EE3)),
            RegexHelper.email_or_iban,
          ),
        ),
        ScWalletItem(
          "Nequi",
          Assets.cashWithdrawIcons.scIcNequi.svg(width: AppSize.w24),
          Color(0xFF6A00FF),
          ScFormData(
            "Nequi Number",
            Icon(Icons.call, size: 24, color: Color(0xFF6A00FF)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "Daviplata",
          Assets.cashWithdrawIcons.scIcDaviplata.svg(width: AppSize.w24),
          Color(0xFFE30613),
          ScFormData(
            "Daviplata Number",
            Icon(Icons.call, size: 24, color: Color(0xFFE30613)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "Yape",
          Assets.cashWithdrawIcons.scIcYape.svg(width: AppSize.w24),
          Color(0xFF6A1B9A),
          ScFormData(
            "Yape Number",
            Icon(Icons.call, size: 24, color: Color(0xFF6A1B9A)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "Plin",
          Assets.cashWithdrawIcons.scIcPlin.svg(width: AppSize.w24),
          Color(0xFF00AEEF),
          ScFormData(
            "Plin Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00AEEF)),
            RegexHelper.phone,
          ),
        ),
        ScWalletItem(
          "RappiPay",
          Assets.cashWithdrawIcons.scIcRappipay.svg(width: AppSize.w24),
          Color(0xFFFF441F),
          ScFormData(
            "Rappi Account",
            Icon(Icons.call, size: 24, color: Color(0xFFFF441F)),
            RegexHelper.phone_or_id,
          ),
        ),

        // South America / Global
        ScWalletItem(
          "MACH",
          Assets.cashWithdrawIcons.scIcMach.svg(width: AppSize.w24),
          Color(0xFFFFD400),
          ScFormData(
            "MACH Account",
            Icon(Icons.account_circle, size: 24, color: Color(0xFFFFD400)),
            RegexHelper.flexible_id,
          ),
        ),
        ScWalletItem(
          "Prex",
          Assets.cashWithdrawIcons.scIcPrex.svg(width: AppSize.w24),
          Color(0xFF00AEEF),
          ScFormData(
            "Prex Account",
            Icon(Icons.tag, size: 24, color: Color(0xFF00AEEF)),
            RegexHelper.flexible_id,
          ),
        ),

        // Australia / NZ
        ScWalletItem(
          "PayID",
          Assets.cashWithdrawIcons.scIcPayid.svg(width: AppSize.w24),
          Color(0xFF6C2BD9),
          ScFormData(
            "PayID (Email/Phone)",
            Icon(Icons.abc, size: 24, color: Color(0xFF6C2BD9)),
            RegexHelper.email_or_phone,
          ),
        ),
        ScWalletItem(
          "CommBank",
          Assets.cashWithdrawIcons.scIcCommbank.svg(width: AppSize.w24),
          Color(0xFFFFCC00),
          ScFormData(
            "BSB & Account",
            Icon(Icons.tag, size: 24, color: Color(0xFFFFCC00)),
            RegexHelper.bsb_account,
          ),
        ),
        ScWalletItem(
          "Westpac",
          Assets.cashWithdrawIcons.scIcWestpac.svg(width: AppSize.w24),
          Color(0xFFD50000),
          ScFormData(
            "BSB & Account",
            Icon(Icons.tag, size: 24, color: Color(0xFFD50000)),
            RegexHelper.bsb_account,
          ),
        ),
        ScWalletItem(
          "ANZ",
          Assets.cashWithdrawIcons.scIcAnz.svg(width: AppSize.w24),
          Color(0xFF0072CE),
          ScFormData(
            "BSB & Account",
            Icon(Icons.tag, size: 24, color: Color(0xFF0072CE)),
            RegexHelper.bsb_account,
          ),
        ),
        ScWalletItem(
          "NAB",
          Assets.cashWithdrawIcons.scIcNab.svg(width: AppSize.w24),
          Color(0xFFC8102E),
          ScFormData(
            "BSB & Account",
            Icon(Icons.tag, size: 24, color: Color(0xFFC8102E)),
            RegexHelper.bsb_account,
          ),
        ),
        ScWalletItem(
          "Up",
          Assets.cashWithdrawIcons.scIcUp.svg(width: AppSize.w24),
          Color(0xFFFF6F00),
          ScFormData(
            "Upname / PayID",
            Icon(Icons.alternate_email, size: 24, color: Color(0xFFFF6F00)),
            RegexHelper.email_or_phone,
          ),
        ),

        // Buy now pay later
        ScWalletItem(
          "Afterpay",
          Assets.cashWithdrawIcons.scIcAfterpay.svg(width: AppSize.w24),
          Color(0xFF00D084),
          ScFormData(
            "Account Email",
            Icon(Icons.mail, size: 24, color: Color(0xFF00D084)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Zip",
          Assets.cashWithdrawIcons.scIcZip.svg(width: AppSize.w24),
          Color(0xFF00C853),
          ScFormData(
            "Zip ID",
            Icon(Icons.account_circle, size: 24, color: Color(0xFF00C853)),
            RegexHelper.flexible_id,
          ),
        ),

        // Banks
        ScWalletItem(
          "Kiwibank",
          Assets.cashWithdrawIcons.scIcKiwibank.svg(width: AppSize.w24),
          Color(0xFF78BE20),
          ScFormData(
            "Account Number",
            Icon(Icons.tag, size: 24, color: Color(0xFF78BE20)),
            RegexHelper.numberOnly,
          ),
        ),
        ScWalletItem(
          "Scotiabank",
          Assets.cashWithdrawIcons.scIcScotiabank.svg(width: AppSize.w24),
          Color(0xFFE31837),
          ScFormData(
            "Base ID / Account",
            Icon(Icons.account_circle, size: 24, color: Color(0xFFE31837)),
            RegexHelper.flexible_id,
          ),
        ),
      ],
    ),

    ScWalletCategory(
      title: 'Crypto',
      items: [
        ScWalletItem(
          "Bitcoin",
          Assets.cryptoWithdrawIcons.scIcBitcoin.svg(width: AppSize.w24),
          Color(0xFFF7931A),
          ScFormData(
            "BTC Wallet Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFFF7931A)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "Ethereum",
          Assets.cryptoWithdrawIcons.scIcEthereum.svg(width: AppSize.w24),
          Color(0xFF627EEA),
          ScFormData(
            "ETH Wallet Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF627EEA)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "USDT",
          Assets.cryptoWithdrawIcons.scIcUsdt.svg(width: AppSize.w24),
          Color(0xFF26A17B),
          ScFormData(
            "TRC20 / BEP20",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF26A17B)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "USDC",
          Assets.cryptoWithdrawIcons.scIcUsdc.svg(width: AppSize.w24),
          Color(0xFF2775CA),
          ScFormData(
            "ERC20 / SPL Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF2775CA)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "Binance Pay",
          Assets.cryptoWithdrawIcons.scIcBinancepay.svg(width: AppSize.w24),
          Color(0xFFF3BA2F),
          ScFormData(
            "Binance ID / Email",
            Icon(Icons.person_outline, size: 24, color: Color(0xFFF3BA2F)),
            RegexHelper.email_or_phone,
          ),
        ),
        ScWalletItem(
          "BNB",
          Assets.cryptoWithdrawIcons.scIcBnb.svg(width: AppSize.w24),
          Color(0xFFF3BA2F),
          ScFormData(
            "BEP20 Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFFF3BA2F)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "Litecoin",
          Assets.cryptoWithdrawIcons.scIcLitecoin.svg(width: AppSize.w24),
          Color(0xFF345D9D),
          ScFormData(
            "LTC Wallet Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF345D9D)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "Tron (TRX)",
          Assets.cryptoWithdrawIcons.scIcTron.svg(width: AppSize.w24),
          Color(0xFFFF060A),
          ScFormData(
            "TRX Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFFFF060A)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "Dogecoin",
          Assets.cryptoWithdrawIcons.scIcDogecoin.svg(width: AppSize.w24),
          Color(0xFFC2A633),
          ScFormData(
            "DOGE Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFFC2A633)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "Shiba Inu",
          Assets.cryptoWithdrawIcons.scIcShibainu.svg(width: AppSize.w24),
          Color(0xFFF28C28),
          ScFormData(
            "SHIB (BEP20) Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFFF28C28)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "Solana",
          Assets.cryptoWithdrawIcons.scIcSolana.svg(width: AppSize.w24),
          Color(0xFF9945FF),
          ScFormData(
            "SOL Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF9945FF)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "Ripple (XRP)",
          Assets.cryptoWithdrawIcons.scIcRipple.svg(width: AppSize.w24),
          Color(0xFF23292F),
          ScFormData(
            "XRP Address & Tag",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF23292F)),
            RegexHelper.crypto_with_tag,
          ),
        ),
        ScWalletItem(
          "Polygon (MATIC)",
          Assets.cryptoWithdrawIcons.scIcPolygon.svg(width: AppSize.w24),
          Color(0xFF8247E5),
          ScFormData(
            "Polygon Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF8247E5)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "Dash",
          Assets.cryptoWithdrawIcons.scIcDash.svg(width: AppSize.w24),
          Color(0xFF008CE7),
          ScFormData(
            "Dash Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF008CE7)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "Bitcoin Cash",
          Assets.cryptoWithdrawIcons.scIcBitcoincash.svg(width: AppSize.w24),
          Color(0xFF8DC351),
          ScFormData(
            "BCH Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF8DC351)),
            RegexHelper.crypto,
          ),
        ),
        ScWalletItem(
          "Perfect Money",
          Icon(Icons.local_parking, size: 24, color: Color(0xFF900600)),
          Color(0xFF900600),
          ScFormData(
            "Perfect Money Account (U...)",
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 24,
              color: Color(0xFF900600),
            ),
            RegexHelper.flexible_id,
          ),
        ),
      ],
    ),

    ScWalletCategory(
      title: 'Gift Cards',
      items: [
        ScWalletItem(
          "Google Play",
          Icon(Icons.play_arrow, size: 24, color: Color(0xFF34A853)),
          Color(0xFF34A853),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF34A853)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Apple Gift Card",
          Icon(Icons.apple, size: 24, color: Color(0xFF0E1A2B)),
          Color(0xFF0E1A2B),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF0E1A2B)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Steam Wallet",
          Assets.giftWithdrawIcons.scIcSteamwallet.svg(width: AppSize.w24),
          Color(0xFF34A853),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF34A853)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "PlayStation",
          Assets.giftWithdrawIcons.scIcPlaystation.svg(width: AppSize.w24),
          Color(0xFFFFFFFF),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFFFFFF)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Xbox Live",
          Assets.giftWithdrawIcons.scIcXboxlive.svg(width: AppSize.w24),
          Color(0xFF1B2838),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF1B2838)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Nintendo eShop",
          Assets.giftWithdrawIcons.scIcNintendoEshop.svg(width: AppSize.w24),
          Color(0xFF00D1B2),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF00D1B2)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Razer Gold",
          Assets.giftWithdrawIcons.scIcRazergold.svg(width: AppSize.w24),
          Color(0xFF44D62C),
          ScFormData(
            "Razer ID / Email",
            Icon(Icons.email, size: 24, color: Color(0xFF44D62C)),
            RegexHelper.email_or_phone,
          ),
        ),
        ScWalletItem(
          "Amazon",
          Assets.giftWithdrawIcons.scIcAmazon.svg(width: AppSize.w24),
          Color(0xFFFF9900),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFF9900)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "eBay",
          Assets.giftWithdrawIcons.scIcEbay.svg(width: AppSize.w24),
          Color(0xFFE53238),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFE53238)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Walmart",
          Assets.giftWithdrawIcons.scIcWalmart.svg(width: AppSize.w24),
          Color(0xFF0071CE),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF0071CE)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Target",
          Assets.giftWithdrawIcons.scIcTarget.svg(width: AppSize.w24),
          Color(0xFFCC0000),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFCC0000)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Shien",
          Assets.giftWithdrawIcons.scIcShien.svg(width: AppSize.w24),
          Color(0xFFFFFFFF),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFFFFFF)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Sephora",
          Assets.giftWithdrawIcons.scIcSephora.svg(width: AppSize.w24),
          Color(0xFFFFFFFF),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFFFFFF)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Nike",
          Assets.giftWithdrawIcons.scIcNike.svg(width: AppSize.w24),
          Color(0xFFFFFFFF),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFFFFFF)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Netflix",
          Assets.giftWithdrawIcons.scIcNetflix.svg(width: AppSize.w24),
          Color(0xFFE50914),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFE50914)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Spotify",
          Assets.giftWithdrawIcons.scIcSpotify.svg(width: AppSize.w24),
          Color(0xFF1DB954),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF1DB954)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Disney+",
          Assets.giftWithdrawIcons.scIcDisney.svg(width: AppSize.w24),
          Color(0xFF113CCF),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF113CCF)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Twitch",
          Assets.giftWithdrawIcons.scIcTwitch.svg(width: AppSize.w24),
          Color(0xFF9146FF),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF9146FF)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Starbucks",
          Assets.giftWithdrawIcons.scIcStarbucks.svg(width: AppSize.w24),
          Color(0xFF00704A),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF00704A)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Uber / Eats",
          Assets.giftWithdrawIcons.scIcUbereats.svg(width: AppSize.w24),
          Color(0xFFFFFFFF),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFFFFFF)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "DoorDash",
          Assets.giftWithdrawIcons.scIcDoordash.svg(width: AppSize.w24),
          Color(0xFFFF3008),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFF3008)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Visa Prepaid",
          Assets.giftWithdrawIcons.scIcVisaprepaid.svg(width: AppSize.w24),
          Color(0xFF1A1F71),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF1A1F71)),
            RegexHelper.email,
          ),
        ),
        ScWalletItem(
          "Mastercard",
          Assets.giftWithdrawIcons.scIcMastercard.svg(width: AppSize.w24),
          Color(0xFFF79E1B),
          ScFormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFF79E1B)),
            RegexHelper.email,
          ),
        ),
      ],
    ),

    ScWalletCategory(
      title: 'Game Credits',
      items: [
        ScWalletItem(
          "Free Fire",
          Assets.gameWithdrawIcons.scIcFreefire.svg(width: AppSize.w24),
          Color(0xFFF5A623),
          ScFormData(
            "Player ID (UID)",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFFF79E1B),
            ),
            RegexHelper.uid,
          ),
        ),
        ScWalletItem(
          "PUBG Mobile",
          Assets.gameWithdrawIcons.scIcPubgmobile.svg(width: AppSize.w24),
          Color(0xFFF2A900),
          ScFormData(
            "Character ID",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFFF79E1B),
            ),
            RegexHelper.uid,
          ),
        ),
        ScWalletItem(
          "CoD Mobile",
          Assets.gameWithdrawIcons.scIcCodmobile.svg(width: AppSize.w24),
          Color(0xFFC4C4C4),
          ScFormData(
            "Player ID (UID)",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFFC4C4C4),
            ),
            RegexHelper.uid,
          ),
        ),
        ScWalletItem(
          "Fortnite",
          Assets.gameWithdrawIcons.scIcFortnite.svg(width: AppSize.w24),
          Color(0xFF9146FF),
          ScFormData(
            "Epic Games Username",
            Icon(Icons.person, size: 24, color: Color(0xFF9146FF)),
            RegexHelper.ea_id,
          ),
        ),
        ScWalletItem(
          "Apex Legends",
          Assets.gameWithdrawIcons.scIcApexLegends.svg(width: AppSize.w24),
          Color(0xFFFF2D2D),
          ScFormData(
            "EA ID / Username",
            Icon(Icons.person, size: 24, color: Color(0xFFFF2D2D)),
            RegexHelper.ea_id,
          ),
        ),
        ScWalletItem(
          "Mobile Legends",
          Assets.gameWithdrawIcons.scIcMobilelegends.svg(width: AppSize.w24),
          Color(0xFF00BFFF),
          ScFormData(
            "User ID & Zone ID",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFF00BFFF),
            ),
            RegexHelper.uid_zone,
          ),
        ),
        ScWalletItem(
          "League of Legends",
          Assets.gameWithdrawIcons.scIcLeagueoflegends.svg(width: AppSize.w24),
          Color(0xFFC89B3C),
          ScFormData(
            "Riot ID (Name#Tag)",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFFC89B3C),
            ),
            RegexHelper.riot_id,
          ),
        ),
        ScWalletItem(
          "Brawl Stars",
          Assets.gameWithdrawIcons.scIcBrawlstars.svg(width: AppSize.w24),
          Color(0xFFFFD700),
          ScFormData(
            "Player Tag (#...)",
            Icon(Icons.tag, size: 24, color: Color(0xFFFFD700)),
            RegexHelper.game_tag,
          ),
        ),
        ScWalletItem(
          "Valorant",
          Assets.gameWithdrawIcons.scIcValorant.svg(width: AppSize.w24),
          Color(0xFFFF4655),
          ScFormData(
            "Riot ID (Name#Tag)",
            Icon(Icons.person, size: 24, color: Color(0xFFFF4655)),
            RegexHelper.riot_id,
          ),
        ),
        ScWalletItem(
          "Genshin Impact",
          Assets.gameWithdrawIcons.scIcGenshinimpact.svg(width: AppSize.w24),
          Color(0xFFF28C28),
          ScFormData(
            "User ID & Server",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFFF28C28),
            ),
            RegexHelper.uid_zone,
          ),
        ),
        ScWalletItem(
          "Robux",
          Assets.gameWithdrawIcons.scIcRobux.svg(width: AppSize.w24),
          Color(0xFF00A2FF),
          ScFormData(
            "Roblox Username",
            Icon(Icons.person, size: 24, color: Color(0xFF00A2FF)),
            RegexHelper.ea_id,
          ),
        ),
        ScWalletItem(
          "Minecraft",
          Assets.gameWithdrawIcons.scIcMinecraft.svg(width: AppSize.w24),
          Color(0xFF5C8A3E),
          ScFormData(
            "Xbox Gamertag / Email",
            Icon(Icons.mail, size: 24, color: Color(0xFF5C8A3E)),
            RegexHelper.email_or_phone,
          ),
        ),
        ScWalletItem(
          "Clash of Clans",
          Assets.gameWithdrawIcons.scIcClashofclans.svg(width: AppSize.w24),
          Color(0xFFD4AF37),
          ScFormData(
            "Player Tag (#...)",
            Icon(Icons.tag, size: 24, color: Color(0xFFFFD700)),
            RegexHelper.game_tag,
          ),
        ),
        ScWalletItem(
          "EA FC",
          Assets.gameWithdrawIcons.scIcEafc.svg(width: AppSize.w24),
          Color(0xFF444444),
          ScFormData(
            "EA ID / PSN / Xbox",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFF444444),
            ),
            RegexHelper.ea_id,
          ),
        ),
      ],
    ),
  ];
  int selectedIndex = 0;

  String? _withdrawType = "Cash";
  String? _withdrawSubType;

  String? get withdrawType => _withdrawType;
  String? get withdrawSubType => _withdrawSubType;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final PageController pageController = PageController();

  void setWithdrawType(String value) {
    _withdrawType = value;
    notifyListeners();
  }

  void setWithdrawSubType(String value) {
    _withdrawSubType = value;
    notifyListeners();
  }

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void setSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  final TextEditingController btcWalletAddressController =
      TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String convertedValue = "0.0000";

  void onAmountChanged(String value) {
    final amount = int.tryParse(value) ?? 0;

    final result = amount / RemoteConfigService.instance.coinToDollarDivider;

    convertedValue = result.toStringAsFixed(4);

    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    btcWalletAddressController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void resetWithdrawForm() {
    btcWalletAddressController.clear();
    amountController.clear();
    noteController.clear();

    _withdrawSubType = null;

    convertedValue = "0.0000";

    notifyListeners();
  }

  bool showWithdrawSheet = false;

  void toggleSheet(bool value) {
    showWithdrawSheet = value;
    notifyListeners();
  }

  Future<bool> createWithdraw(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _db.userModel!;

      final amount = double.tryParse((amountController.text.trim()).toString());

      if (withdrawSubType == null || withdrawSubType!.isEmpty) {
        _error = 'Please select withdraw sub type';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (withdrawType == null || withdrawType!.isEmpty) {
        _error = 'Please select withdraw type';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (btcWalletAddressController.text.trim().isEmpty) {
        _error = 'Please enter wallet address';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (amount == null) {
        _error = 'Please enter valid amount';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final minAmount = RemoteConfigService.instance.minWithdrawAmount;
      if (amount < minAmount) {
        _error = 'Minimum withdrawal is $minAmount coins';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (amount > user.coin) {
        _error = 'Insufficient coins';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final pendingSnap = await _firestore
          .collection('withdraw')
          .where('user_id', isEqualTo: user.userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (pendingSnap.docs.isNotEmpty) {
        _error =
            'You already have a pending withdrawal. Wait for approval before requesting another.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final docRef = _firestore.collection('withdraw').doc();

      await docRef.set({
        'user_id': user.userId,
        'email': btcWalletAddressController.text.trim(),
        'withdraw_type': withdrawType,
        'withdraw_sub_type': withdrawSubType,
        'amount': amount,
        'note': noteController.text.trim(),
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'reason': '',
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Withdraw failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get Withdraw List (Stream).
  /// Note: server-side ordering is intentionally avoided so the query
  /// doesn't require a composite Firestore index — sorting is done
  /// client-side by [_ScWalletHistoryContent].
  Stream<QuerySnapshot> getWithdrawStream() {
    final userId = _db.userModel!.userId;

    return _firestore
        .collection('withdraw')
        .where('user_id', isEqualTo: userId)
        .snapshots();
  }

  /// Stream that emits true while the current user has a pending withdrawal.
  Stream<bool> pendingWithdrawStream() {
    final userId = _db.userModel?.userId;
    if (userId == null) return Stream.value(false);
    return _firestore
        .collection('withdraw')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty);
  }
}
