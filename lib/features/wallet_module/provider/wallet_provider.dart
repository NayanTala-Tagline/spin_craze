import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/features/wallet_module/model/wallet_models.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/regex_helper.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:flutter/material.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class WalletProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _db = Injector.instance<AppDB>();
  List<WalletCategory> getWalletCategories(BuildContext context) => [
    WalletCategory(
      title: context.l10n.cash,
      items: [
        WalletItem(
          "PayPal",
          Icon(Icons.paypal, size: AppSize.w24, color: Color(0xFF2559ca)),
          Color(0xFF2559ca),
          FormData(
            "Enter PayPal Email",
            Icon(Icons.payment, size: AppSize.w24, color: Color(0xFF2559ca)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Wise",
          Icon(
            Icons.flag_outlined,
            size: AppSize.w24,
            color: Color(0xFF00aeff),
          ),
          Color(0xFF00aeff),
          FormData(
            "Email / IBAN",
            Icon(
              Icons.account_balance_sharp,
              size: 24,
              color: Color(0xFF00aeff),
            ),
            RegexHelper.email_or_iban,
          ),
        ),
        WalletItem(
          "Payoneer",
          Icon(
            Icons.repeat_on_sharp,
            size: AppSize.w24,
            color: Color(0xFFff4000),
          ),
          Color(0xFFff4000),
          FormData(
            "Payoneer Email",
            Icon(Icons.email_sharp, size: 24, color: Color(0xFFff4000)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Skrill",
          Icon(
            Icons.local_play_sharp,
            size: AppSize.w24,
            color: Color(0xFFb82986),
          ),
          Color(0xFFb82986),
          FormData(
            "Skrill Email",
            Icon(Icons.email_sharp, size: 24, color: Color(0xFFb82986)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Apple Pay",
          Icon(Icons.apple, size: AppSize.w24, color: Color(0xFFFFFFFF)),
          Color(0xFFFFFFFF),
          FormData(
            "Apple ID",
            Icon(Icons.phone_android_sharp, size: 24, color: Color(0xFFFFFFFF)),
            RegexHelper.email_or_phone,
          ),
        ),
        WalletItem(
          "Google Wallet",
          Assets.cashWithdrawIcons.icGooglewallet.image(width: AppSize.w24),
          Color(0xFF3a7af2),
          FormData(
            "Google Pay Number",
            Icon(Icons.email_sharp, size: 24, color: Color(0xFF3a7af2)),
            RegexHelper.email_or_phone,
          ),
        ),
        WalletItem(
          "Samsung Wallet",
          Icon(
            Icons.phone_android,
            size: AppSize.w24,
            color: Color(0xFF43a546),
          ),
          Color(0xFF43a546),
          FormData(
            "Samsung Pay ID",
            Icon(Icons.email_sharp, size: 24, color: Color(0xFF43a546)),
            RegexHelper.alphanumeric,
          ),
        ),
        WalletItem(
          "Wells Fargo",
          Icon(
            Icons.account_balance_outlined,
            size: AppSize.w24,
            color: Color(0xFFf68819),
          ),
          Color(0xFFf68819),
          FormData(
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
        WalletItem(
          "Alipay",
          Assets.cashWithdrawIcons.icAlipay.svg(width: AppSize.w24),
          Color(0xFF166bff),
          FormData(
            "Alipay ID",
            Icon(Icons.qr_code, size: 24, color: Color(0xFF166bff)),
            RegexHelper.wallet_id,
          ),
        ),
        WalletItem(
          "WeChat Pay",
          Icon(Icons.wechat, size: AppSize.w24, color: Color(0xFF009e5f)),
          Color(0xFF009e5f),
          FormData(
            "WeChat ID",
            Icon(Icons.message, size: 24, color: Color(0xFF009e5f)),
            RegexHelper.wallet_id,
          ),
        ),
        WalletItem(
          "UPI",
          Icon(Icons.qr_code_2, size: AppSize.w24, color: Color(0xFFFF7900)),
          Color(0xFFFF7900),
          FormData(
            "UPI ID (vpa)",
            Icon(Icons.alternate_email, size: 24, color: Color(0xFFFF7900)),
            RegexHelper.upi,
          ),
        ),
        WalletItem(
          "PhonePe Number",
          Icon(
            Icons.local_parking_outlined,
            size: AppSize.w24,
            color: Color(0xFF6F2C91),
          ),
          Color(0xFF6F2C91),
          FormData(
            "PhonePe Number",
            Icon(Icons.call, size: 24, color: Color(0xFF6F2C91)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "Paytm",
          Icon(Icons.credit_card, size: AppSize.w24, color: Color(0xFF00AEEF)),
          Color(0xFF00AEEF),
          FormData(
            "Paytm Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00AEEF)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "GCash",
          Icon(Icons.wallet, size: AppSize.w24, color: Color(0xFF0066FF)),
          Color(0xFF0066FF),
          FormData(
            "GCash Number",
            Icon(Icons.call, size: 24, color: Color(0xFF0066FF)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "GrabPay",
          Icon(
            Icons.local_taxi_rounded,
            size: AppSize.w24,
            color: Color(0xFF00A651),
          ),
          Color(0xFF00A651),
          FormData(
            "Grab Registered Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00A651)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "KakaoPay",
          Icon(Icons.chat_bubble, size: AppSize.w24, color: Color(0xFFFFCC00)),
          Color(0xFFFFCC00),
          FormData(
            "Kakao ID",
            Icon(Icons.chat_bubble, size: 24, color: Color(0xFFFFCC00)),
            RegexHelper.wallet_id,
          ),
        ),
        WalletItem(
          "PayPay",
          Icon(
            Icons.local_parking_outlined,
            size: AppSize.w24,
            color: Color(0xFFE30613),
          ),
          Color(0xFFE30613),
          FormData(
            "PayPay ID",
            Icon(Icons.qr_code, size: 24, color: Color(0xFFE30613)),
            RegexHelper.wallet_id,
          ),
        ),
        WalletItem(
          "Easypaisa",
          Icon(
            Icons.account_balance_wallet_rounded,
            size: AppSize.w24,
            color: Color(0xFF00B14F),
          ),
          Color(0xFF00B14F),
          FormData(
            "Easypaisa Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00B14F)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "SadaPay",
          Icon(Icons.credit_card, size: AppSize.w24, color: Colors.indigo),
          Colors.indigo,
          FormData(
            "SadaPay Account",
            Icon(Icons.call, size: 24, color: Colors.indigo),
            RegexHelper.phone_or_id,
          ),
        ),
        WalletItem(
          "bKash",
          Icon(
            Icons.money_outlined,
            size: AppSize.w24,
            color: Color(0xFFf54293),
          ),
          Color(0xFFf54293),
          FormData(
            "bKash Number",
            Icon(Icons.call, size: 24, color: Color(0xFFf54293)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "CallFin",
          Icon(
            Icons.phone_android,
            size: AppSize.w24,
            color: Color(0xFF00A86B),
          ),
          Color(0xFF00A86B),
          FormData(
            "CallFin Number",
            Icon(Icons.email_sharp, size: 24, color: Color(0xFF00A86B)),
            RegexHelper.phone_or_id,
          ),
        ),
        WalletItem(
          "Revolut",
          Assets.cashWithdrawIcons.icRevolut.image(width: AppSize.w24),
          Color(0xFF0066FF),
          FormData(
            "Ravtag / IBAN",
            Icon(Icons.tag, size: 24, color: Color(0xFF0066FF)),
            RegexHelper.email_or_iban,
          ),
        ),
        WalletItem(
          "Monzo",
          Assets.cashWithdrawIcons.icMonzo.image(width: AppSize.w24),
          Color(0xFF1A2E5A),
          FormData(
            "Account / Sort Code",
            Icon(
              Icons.account_balance_sharp,
              size: 24,
              color: Color(0xFF1A2E5A),
            ),
            RegexHelper.sort_code_account,
          ),
        ),
        WalletItem(
          "N26",
          Assets.cashWithdrawIcons.icN26.image(width: AppSize.w24),
          Color(0xFF00C1B2),
          FormData(
            "IBAN",
            Icon(
              Icons.account_balance_sharp,
              size: 24,
              color: Color(0xFF00C1B2),
            ),
            RegexHelper.iban,
          ),
        ),
        WalletItem(
          "Bunq",
          Icon(Icons.savings, size: AppSize.w24, color: Color(0xFFeb7a8d)),
          Color(0xFFeb7a8d),
          FormData(
            "IBAN / Email",
            Icon(Icons.mail, size: 24, color: Color(0xFFeb7a8d)),
            RegexHelper.email_or_iban,
          ),
        ),
        WalletItem(
          "Starling Bank",
          Assets.cashWithdrawIcons.icStarlingbank.svg(width: AppSize.w24),
          Color(0xFF00b9aa),
          FormData(
            "Account Number",
            Icon(Icons.tag, size: 24, color: Color(0xFF00b9aa)),
            RegexHelper.sort_code_account,
          ),
        ),
        WalletItem(
          "iDEAL",
          Assets.cashWithdrawIcons.icIdeal.svg(width: AppSize.w24),
          Color(0xFFFFFFFF),
          FormData(
            "IBAN",
            Icon(
              Icons.account_balance_sharp,
              size: 24,
              color: Color(0xFFFFFFFF),
            ),
            RegexHelper.iban,
          ),
        ),
        WalletItem(
          "Tikkie",
          Assets.cashWithdrawIcons.icTikkie.svg(width: AppSize.w24),
          Color(0xFFff5f00),
          FormData(
            "Tikkie Link/Number",
            Icon(Icons.link, size: 24, color: Color(0xFFff5f00)),
            RegexHelper.link,
          ),
        ),
        WalletItem(
          "Vipps",
          Assets.cashWithdrawIcons.icVipps.svg(width: AppSize.w24),
          Color(0xFFff5020),
          FormData(
            "Vipps Number",
            Icon(Icons.call, size: 24, color: Color(0xFFff5f00)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "MobilePay",
          Assets.cashWithdrawIcons.icMobilepay.svg(width: AppSize.w24),
          Color(0xFF00509b),
          FormData(
            "MobilePay Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00509b)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "Swish",
          Assets.cashWithdrawIcons.icSwish.svg(width: AppSize.w24),
          Color(0xFF02ab81),
          FormData(
            "Swish Number",
            Icon(Icons.call, size: 24, color: Color(0xFF02ab81)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "BLIK",
          Assets.cashWithdrawIcons.icBlik.svg(width: AppSize.w24),
          Color(0xFFfc342a),
          FormData(
            "BLIK Code",
            Icon(Icons.tag, size: 24, color: Color(0xFFfc342a)),
            RegexHelper.code,
          ),
        ),
        WalletItem(
          "Lydia",
          Assets.cashWithdrawIcons.icLydia.svg(width: AppSize.w24),
          Color(0xFF612670),
          FormData(
            "Lydia Number",
            Icon(Icons.call, size: 24, color: Color(0xFF612670)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "PayLib",
          Assets.cashWithdrawIcons.icPaylib.svg(width: AppSize.w24),
          Color(0xFF3c4985),
          FormData(
            "PayLib Number",
            Icon(Icons.call, size: 24, color: Color(0xFF3c4985)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "Twint",
          Assets.cashWithdrawIcons.icTwint.svg(width: AppSize.w24),
          Color(0xFF652786),
          FormData(
            "Twint Number",
            Icon(Icons.call, size: 24, color: Color(0xFF652786)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "Satispay",
          Assets.cashWithdrawIcons.icSatispay.svg(width: AppSize.w24),
          Color(0xFFff5035),
          FormData(
            "Satispay Number",
            Icon(Icons.call, size: 24, color: Color(0xFFff5035)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "iyzico",
          Assets.cashWithdrawIcons.icIyzico.svg(width: AppSize.w24),
          Color(0xFF2882ff),
          FormData(
            "Account ID",
            Icon(Icons.account_circle, size: 24, color: Color(0xFF2882ff)),
            RegexHelper.flexible_id,
          ),
        ),

        // Africa / Middle East
        WalletItem(
          "M-Pesa",
          Assets.cashWithdrawIcons.icMpesa.svg(width: AppSize.w24),
          Color(0xFF009c46),
          FormData(
            "M-Pesa Number",
            Icon(Icons.call, size: 24, color: Color(0xFF009c46)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "OPay",
          Assets.cashWithdrawIcons.icOpay.svg(width: AppSize.w24),
          Color(0xFF1DC45A),
          FormData(
            "OPay Number",
            Icon(Icons.call, size: 24, color: Color(0xFF1DC45A)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "Orange Money",
          Assets.cashWithdrawIcons.icOrangemoney.svg(width: AppSize.w24),
          Color(0xFFFF7900),
          FormData(
            "Orange Money Number",
            Icon(Icons.call, size: 24, color: Color(0xFFFF7900)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "MTN Mobile",
          Assets.cashWithdrawIcons.icMynmobile.svg(width: AppSize.w24),
          Color(0xFFFFCC00),
          FormData(
            "MTN Mobile Number",
            Icon(Icons.cell_tower, size: 24, color: Color(0xFFFFCC00)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "Chipper Cash",
          Assets.cashWithdrawIcons.icChippercash.svg(width: AppSize.w24),
          Color(0xFF0066FF),
          FormData(
            "Chipper Tag",
            Icon(Icons.alternate_email, size: 24, color: Color(0xFF0066FF)),
            RegexHelper.wallet_id,
          ),
        ),
        WalletItem(
          "Moniepoint",
          Icon(Icons.dialpad, size: 24, color: Color(0xFFFFCC00)),
          Color(0xFFFFCC00),
          FormData(
            "Account Number",
            Icon(Icons.tag, size: 24, color: Color(0xFFFFCC00)),
            RegexHelper.numberOnly,
          ),
        ),

        // India / Africa banks
        WalletItem(
          "Baxi",
          Assets.cashWithdrawIcons.icBaxi.svg(width: AppSize.w24),
          Color(0xFF007BFF),
          FormData(
            "Baxi Account",
            Icon(Icons.tag, size: 24, color: Color(0xFF007BFF)),
            RegexHelper.numberOnly,
          ),
        ),
        WalletItem(
          "Capitec Pay",
          Assets.cashWithdrawIcons.icCapitecpay.svg(width: AppSize.w24),
          Color(0xFF00B14F),
          FormData(
            "ID / Phone",
            Icon(
              Icons.account_circle_outlined,
              size: 24,
              color: Color(0xFF00B14F),
            ),
            RegexHelper.phone_or_id,
          ),
        ),
        WalletItem(
          "SnapScan",
          Assets.cashWithdrawIcons.icSnapscan.svg(width: AppSize.w24),
          Color(0xFF0033A0),
          FormData(
            "SnapScan ID",
            Icon(Icons.qr_code, size: 24, color: Color(0xFF0033A0)),
            RegexHelper.wallet_id,
          ),
        ),
        WalletItem(
          "NatsWallet",
          Assets.cashWithdrawIcons.icNasswallet.svg(width: AppSize.w24),
          Color(0xFFF5A623),
          FormData(
            "Card/Account",
            Icon(
              Icons.compare_arrows_outlined,
              size: 24,
              color: Color(0xFFF5A623),
            ),
            RegexHelper.iban_or_account,
          ),
        ),
        WalletItem(
          "Onafriq",
          Assets.cashWithdrawIcons.icOnafriq.svg(width: AppSize.w24),
          Color(0xFFE53935),
          FormData(
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
        WalletItem(
          "STC Pay",
          Assets.cashWithdrawIcons.icStcpay.svg(width: AppSize.w24),
          Color(0xFF6A1B9A),
          FormData(
            "STC Pay Number",
            Icon(Icons.call, size: 24, color: Color(0xFF6A1B9A)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "Vodafone Cash",
          Assets.cashWithdrawIcons.icVodafonecash.svg(width: AppSize.w24),
          Color(0xFFE60000),
          FormData(
            "Vodafone Number",
            Icon(Icons.call, size: 24, color: Color(0xFFE60000)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "Careem Pay",
          Assets.cashWithdrawIcons.icCareempay.svg(width: AppSize.w24),
          Color(0xFF00C853),
          FormData(
            "Careem Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00C853)),
            RegexHelper.phone,
          ),
        ),

        // Egypt
        WalletItem(
          "InstaPay",
          Assets.cashWithdrawIcons.icInstapay.svg(width: AppSize.w24),
          Color(0xFF0070BA),
          FormData(
            "InstaPay Address",
            Icon(Icons.alternate_email, size: 24, color: Color(0xFF0070BA)),
            RegexHelper.payment_id,
          ),
        ),
        WalletItem(
          "myfawry",
          Assets.cashWithdrawIcons.icMyfawry.svg(width: AppSize.w24),
          Color(0xFFF9B233),
          FormData(
            "Fawry Number",
            Icon(Icons.call, size: 24, color: Color(0xFFF9B233)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "BenefitPay",
          Assets.cashWithdrawIcons.icBenefitpay.svg(width: AppSize.w24),
          Color(0xFF00A3E0),
          FormData(
            "BenefitPay Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00A3E0)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "Meeza",
          Assets.cashWithdrawIcons.icMeeza.svg(width: AppSize.w24),
          Color(0xFF009639),
          FormData(
            "Meeza Card/Wallet",
            Icon(Icons.credit_card, size: 24, color: Color(0xFF009639)),
            RegexHelper.iban_or_account,
          ),
        ),
        WalletItem(
          "valU",
          Assets.cashWithdrawIcons.icValu.svg(width: AppSize.w24),
          Color(0xFF0088FF),
          FormData(
            "valU Account",
            Icon(Icons.call, size: 24, color: Color(0xFF0088FF)),
            RegexHelper.phone_or_id,
          ),
        ),

        // LATAM
        WalletItem(
          "Nubank",
          Assets.cashWithdrawIcons.icNubank.svg(width: AppSize.w24),
          Color(0xFF8A05BE),
          FormData(
            "Pix Key / Account",
            Icon(Icons.add_box_sharp, size: 24, color: Color(0xFF8A05BE)),
            RegexHelper.pix_key,
          ),
        ),
        WalletItem(
          "PicPay",
          Assets.cashWithdrawIcons.icPicpay.svg(width: AppSize.w24),
          Color(0xFF21C25E),
          FormData(
            "PicPay Username / Pix",
            Icon(Icons.alternate_email, size: 24, color: Color(0xFF21C25E)),
            RegexHelper.pix_key,
          ),
        ),
        WalletItem(
          "Mercado Pago",
          Assets.cashWithdrawIcons.icMercadopago.svg(width: AppSize.w24),
          Color(0xFF009EE3),
          FormData(
            "Email / CVU",
            Icon(Icons.mail, size: 24, color: Color(0xFF009EE3)),
            RegexHelper.email_or_iban,
          ),
        ),
        WalletItem(
          "Nequi",
          Assets.cashWithdrawIcons.icNequi.svg(width: AppSize.w24),
          Color(0xFF6A00FF),
          FormData(
            "Nequi Number",
            Icon(Icons.call, size: 24, color: Color(0xFF6A00FF)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "Daviplata",
          Assets.cashWithdrawIcons.icDaviplata.svg(width: AppSize.w24),
          Color(0xFFE30613),
          FormData(
            "Daviplata Number",
            Icon(Icons.call, size: 24, color: Color(0xFFE30613)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "Yape",
          Assets.cashWithdrawIcons.icYape.svg(width: AppSize.w24),
          Color(0xFF6A1B9A),
          FormData(
            "Yape Number",
            Icon(Icons.call, size: 24, color: Color(0xFF6A1B9A)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "Plin",
          Assets.cashWithdrawIcons.icPlin.svg(width: AppSize.w24),
          Color(0xFF00AEEF),
          FormData(
            "Plin Number",
            Icon(Icons.call, size: 24, color: Color(0xFF00AEEF)),
            RegexHelper.phone,
          ),
        ),
        WalletItem(
          "RappiPay",
          Assets.cashWithdrawIcons.icRappipay.svg(width: AppSize.w24),
          Color(0xFFFF441F),
          FormData(
            "Rappi Account",
            Icon(Icons.call, size: 24, color: Color(0xFFFF441F)),
            RegexHelper.phone_or_id,
          ),
        ),

        // South America / Global
        WalletItem(
          "MACH",
          Assets.cashWithdrawIcons.icMach.svg(width: AppSize.w24),
          Color(0xFFFFD400),
          FormData(
            "MACH Account",
            Icon(Icons.account_circle, size: 24, color: Color(0xFFFFD400)),
            RegexHelper.flexible_id,
          ),
        ),
        WalletItem(
          "Prex",
          Assets.cashWithdrawIcons.icPrex.svg(width: AppSize.w24),
          Color(0xFF00AEEF),
          FormData(
            "Prex Account",
            Icon(Icons.tag, size: 24, color: Color(0xFF00AEEF)),
            RegexHelper.flexible_id,
          ),
        ),

        // Australia / NZ
        WalletItem(
          "PayID",
          Assets.cashWithdrawIcons.icPayid.svg(width: AppSize.w24),
          Color(0xFF6C2BD9),
          FormData(
            "PayID (Email/Phone)",
            Icon(Icons.abc, size: 24, color: Color(0xFF6C2BD9)),
            RegexHelper.email_or_phone,
          ),
        ),
        WalletItem(
          "CommBank",
          Assets.cashWithdrawIcons.icCommbank.svg(width: AppSize.w24),
          Color(0xFFFFCC00),
          FormData(
            "BSB & Account",
            Icon(Icons.tag, size: 24, color: Color(0xFFFFCC00)),
            RegexHelper.bsb_account,
          ),
        ),
        WalletItem(
          "Westpac",
          Assets.cashWithdrawIcons.icWestpac.svg(width: AppSize.w24),
          Color(0xFFD50000),
          FormData(
            "BSB & Account",
            Icon(Icons.tag, size: 24, color: Color(0xFFD50000)),
            RegexHelper.bsb_account,
          ),
        ),
        WalletItem(
          "ANZ",
          Assets.cashWithdrawIcons.icAnz.svg(width: AppSize.w24),
          Color(0xFF0072CE),
          FormData(
            "BSB & Account",
            Icon(Icons.tag, size: 24, color: Color(0xFF0072CE)),
            RegexHelper.bsb_account,
          ),
        ),
        WalletItem(
          "NAB",
          Assets.cashWithdrawIcons.icNab.svg(width: AppSize.w24),
          Color(0xFFC8102E),
          FormData(
            "BSB & Account",
            Icon(Icons.tag, size: 24, color: Color(0xFFC8102E)),
            RegexHelper.bsb_account,
          ),
        ),
        WalletItem(
          "Up",
          Assets.cashWithdrawIcons.icUp.svg(width: AppSize.w24),
          Color(0xFFFF6F00),
          FormData(
            "Upname / PayID",
            Icon(Icons.alternate_email, size: 24, color: Color(0xFFFF6F00)),
            RegexHelper.email_or_phone,
          ),
        ),

        // Buy now pay later
        WalletItem(
          "Afterpay",
          Assets.cashWithdrawIcons.icAfterpay.svg(width: AppSize.w24),
          Color(0xFF00D084),
          FormData(
            "Account Email",
            Icon(Icons.mail, size: 24, color: Color(0xFF00D084)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Zip",
          Assets.cashWithdrawIcons.icZip.svg(width: AppSize.w24),
          Color(0xFF00C853),
          FormData(
            "Zip ID",
            Icon(Icons.account_circle, size: 24, color: Color(0xFF00C853)),
            RegexHelper.flexible_id,
          ),
        ),

        // Banks
        WalletItem(
          "Kiwibank",
          Assets.cashWithdrawIcons.icKiwibank.svg(width: AppSize.w24),
          Color(0xFF78BE20),
          FormData(
            "Account Number",
            Icon(Icons.tag, size: 24, color: Color(0xFF78BE20)),
            RegexHelper.numberOnly,
          ),
        ),
        WalletItem(
          "Scotiabank",
          Assets.cashWithdrawIcons.icScotiabank.svg(width: AppSize.w24),
          Color(0xFFE31837),
          FormData(
            "Base ID / Account",
            Icon(Icons.account_circle, size: 24, color: Color(0xFFE31837)),
            RegexHelper.flexible_id,
          ),
        ),
      ],
    ),

    WalletCategory(
      title: context.l10n.crypto,
      items: [
        WalletItem(
          "Bitcoin",
          Assets.cryptoWithdrawIcons.icBitcoin.svg(width: AppSize.w24),
          Color(0xFFF7931A),
          FormData(
            "BTC Wallet Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFFF7931A)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "Ethereum",
          Assets.cryptoWithdrawIcons.icEthereum.svg(width: AppSize.w24),
          Color(0xFF627EEA),
          FormData(
            "ETH Wallet Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF627EEA)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "USDT",
          Assets.cryptoWithdrawIcons.icUsdt.svg(width: AppSize.w24),
          Color(0xFF26A17B),
          FormData(
            "TRC20 / BEP20",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF26A17B)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "USDC",
          Assets.cryptoWithdrawIcons.icUsdc.svg(width: AppSize.w24),
          Color(0xFF2775CA),
          FormData(
            "ERC20 / SPL Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF2775CA)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "Binance Pay",
          Assets.cryptoWithdrawIcons.icBinancepay.svg(width: AppSize.w24),
          Color(0xFFF3BA2F),
          FormData(
            "Binance ID / Email",
            Icon(Icons.person_outline, size: 24, color: Color(0xFFF3BA2F)),
            RegexHelper.email_or_phone,
          ),
        ),
        WalletItem(
          "BNB",
          Assets.cryptoWithdrawIcons.icBnb.svg(width: AppSize.w24),
          Color(0xFFF3BA2F),
          FormData(
            "BEP20 Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFFF3BA2F)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "Litecoin",
          Assets.cryptoWithdrawIcons.icLitecoin.svg(width: AppSize.w24),
          Color(0xFF345D9D),
          FormData(
            "LTC Wallet Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF345D9D)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "Tron (TRX)",
          Assets.cryptoWithdrawIcons.icTron.svg(width: AppSize.w24),
          Color(0xFFFF060A),
          FormData(
            "TRX Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFFFF060A)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "Dogecoin",
          Assets.cryptoWithdrawIcons.icDogecoin.svg(width: AppSize.w24),
          Color(0xFFC2A633),
          FormData(
            "DOGE Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFFC2A633)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "Shiba Inu",
          Assets.cryptoWithdrawIcons.icShibainu.svg(width: AppSize.w24),
          Color(0xFFF28C28),
          FormData(
            "SHIB (BEP20) Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFFF28C28)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "Solana",
          Assets.cryptoWithdrawIcons.icSolana.svg(width: AppSize.w24),
          Color(0xFF9945FF),
          FormData(
            "SOL Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF9945FF)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "Ripple (XRP)",
          Assets.cryptoWithdrawIcons.icRipple.svg(width: AppSize.w24),
          Color(0xFF23292F),
          FormData(
            "XRP Address & Tag",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF23292F)),
            RegexHelper.crypto_with_tag,
          ),
        ),
        WalletItem(
          "Polygon (MATIC)",
          Assets.cryptoWithdrawIcons.icPolygon.svg(width: AppSize.w24),
          Color(0xFF8247E5),
          FormData(
            "Polygon Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF8247E5)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "Dash",
          Assets.cryptoWithdrawIcons.icDash.svg(width: AppSize.w24),
          Color(0xFF008CE7),
          FormData(
            "Dash Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF008CE7)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "Bitcoin Cash",
          Assets.cryptoWithdrawIcons.icBitcoincash.svg(width: AppSize.w24),
          Color(0xFF8DC351),
          FormData(
            "BCH Address",
            Icon(Icons.wallet_sharp, size: 24, color: Color(0xFF8DC351)),
            RegexHelper.crypto,
          ),
        ),
        WalletItem(
          "Perfect Money",
          Icon(Icons.local_parking, size: 24, color: Color(0xFF900600)),
          Color(0xFF900600),
          FormData(
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

    WalletCategory(
      title: context.l10n.giftCards,
      items: [
        WalletItem(
          "Google Play",
          Icon(Icons.play_arrow, size: 24, color: Color(0xFF34A853)),
          Color(0xFF34A853),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF34A853)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Apple Gift Card",
          Icon(Icons.apple, size: 24, color: Color(0xFFFFFFFF)),
          Color(0xFFFFFFFF),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFFFFFF)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Steam Wallet",
          Assets.giftWithdrawIcons.icSteamwallet.svg(width: AppSize.w24),
          Color(0xFF34A853),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF34A853)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "PlayStation",
          Assets.giftWithdrawIcons.icPlaystation.svg(width: AppSize.w24),
          Color(0xFFFFFFFF),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFFFFFF)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Xbox Live",
          Assets.giftWithdrawIcons.icXboxlive.svg(width: AppSize.w24),
          Color(0xFF1B2838),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF1B2838)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Nintendo eShop",
          Assets.giftWithdrawIcons.icNintendoEshop.svg(width: AppSize.w24),
          Color(0xFF00D1B2),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF00D1B2)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Razer Gold",
          Assets.giftWithdrawIcons.icRazergold.svg(width: AppSize.w24),
          Color(0xFF44D62C),
          FormData(
            "Razer ID / Email",
            Icon(Icons.email, size: 24, color: Color(0xFF44D62C)),
            RegexHelper.email_or_phone,
          ),
        ),
        WalletItem(
          "Amazon",
          Assets.giftWithdrawIcons.icAmazon.svg(width: AppSize.w24),
          Color(0xFFFF9900),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFF9900)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "eBay",
          Assets.giftWithdrawIcons.icEbay.svg(width: AppSize.w24),
          Color(0xFFE53238),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFE53238)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Walmart",
          Assets.giftWithdrawIcons.icWalmart.svg(width: AppSize.w24),
          Color(0xFF0071CE),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF0071CE)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Target",
          Assets.giftWithdrawIcons.icTarget.svg(width: AppSize.w24),
          Color(0xFFCC0000),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFCC0000)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Shien",
          Assets.giftWithdrawIcons.icShien.svg(width: AppSize.w24),
          Color(0xFFFFFFFF),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFFFFFF)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Sephora",
          Assets.giftWithdrawIcons.icSephora.svg(width: AppSize.w24),
          Color(0xFFFFFFFF),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFFFFFF)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Nike",
          Assets.giftWithdrawIcons.icNike.svg(width: AppSize.w24),
          Color(0xFFFFFFFF),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFFFFFF)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Netflix",
          Assets.giftWithdrawIcons.icNetflix.svg(width: AppSize.w24),
          Color(0xFFE50914),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFE50914)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Spotify",
          Assets.giftWithdrawIcons.icSpotify.svg(width: AppSize.w24),
          Color(0xFF1DB954),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF1DB954)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Disney+",
          Assets.giftWithdrawIcons.icDisney.svg(width: AppSize.w24),
          Color(0xFF113CCF),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF113CCF)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Twitch",
          Assets.giftWithdrawIcons.icTwitch.svg(width: AppSize.w24),
          Color(0xFF9146FF),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF9146FF)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Starbucks",
          Assets.giftWithdrawIcons.icStarbucks.svg(width: AppSize.w24),
          Color(0xFF00704A),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF00704A)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Uber / Eats",
          Assets.giftWithdrawIcons.icUbereats.svg(width: AppSize.w24),
          Color(0xFFFFFFFF),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFFFFFF)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "DoorDash",
          Assets.giftWithdrawIcons.icDoordash.svg(width: AppSize.w24),
          Color(0xFFFF3008),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFFF3008)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Visa Prepaid",
          Assets.giftWithdrawIcons.icVisaprepaid.svg(width: AppSize.w24),
          Color(0xFF1A1F71),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFF1A1F71)),
            RegexHelper.email,
          ),
        ),
        WalletItem(
          "Mastercard",
          Assets.giftWithdrawIcons.icMastercard.svg(width: AppSize.w24),
          Color(0xFFF79E1B),
          FormData(
            "Email to send code",
            Icon(Icons.email, size: 24, color: Color(0xFFF79E1B)),
            RegexHelper.email,
          ),
        ),
      ],
    ),

    WalletCategory(
      title: context.l10n.gameCredits,
      items: [
        WalletItem(
          "Free Fire",
          Assets.gameWithdrawIcons.icFreefire.svg(width: AppSize.w24),
          Color(0xFFF5A623),
          FormData(
            "Player ID (UID)",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFFF79E1B),
            ),
            RegexHelper.uid,
          ),
        ),
        WalletItem(
          "PUBG Mobile",
          Assets.gameWithdrawIcons.icPubgmobile.svg(width: AppSize.w24),
          Color(0xFFF2A900),
          FormData(
            "Character ID",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFFF79E1B),
            ),
            RegexHelper.uid,
          ),
        ),
        WalletItem(
          "CoD Mobile",
          Assets.gameWithdrawIcons.icCodmobile.svg(width: AppSize.w24),
          Color(0xFFC4C4C4),
          FormData(
            "Player ID (UID)",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFFC4C4C4),
            ),
            RegexHelper.uid,
          ),
        ),
        WalletItem(
          "Fortnite",
          Assets.gameWithdrawIcons.icFortnite.svg(width: AppSize.w24),
          Color(0xFF9146FF),
          FormData(
            "Epic Games Username",
            Icon(Icons.person, size: 24, color: Color(0xFF9146FF)),
            RegexHelper.ea_id,
          ),
        ),
        WalletItem(
          "Apex Legends",
          Assets.gameWithdrawIcons.icApexLegends.svg(width: AppSize.w24),
          Color(0xFFFF2D2D),
          FormData(
            "EA ID / Username",
            Icon(Icons.person, size: 24, color: Color(0xFFFF2D2D)),
            RegexHelper.ea_id,
          ),
        ),
        WalletItem(
          "Mobile Legends",
          Assets.gameWithdrawIcons.icMobilelegends.svg(width: AppSize.w24),
          Color(0xFF00BFFF),
          FormData(
            "User ID & Zone ID",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFF00BFFF),
            ),
            RegexHelper.uid_zone,
          ),
        ),
        WalletItem(
          "League of Legends",
          Assets.gameWithdrawIcons.icLeagueoflegends.svg(width: AppSize.w24),
          Color(0xFFC89B3C),
          FormData(
            "Riot ID (Name#Tag)",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFFC89B3C),
            ),
            RegexHelper.riot_id,
          ),
        ),
        WalletItem(
          "Brawl Stars",
          Assets.gameWithdrawIcons.icBrawlstars.svg(width: AppSize.w24),
          Color(0xFFFFD700),
          FormData(
            "Player Tag (#...)",
            Icon(Icons.tag, size: 24, color: Color(0xFFFFD700)),
            RegexHelper.game_tag,
          ),
        ),
        WalletItem(
          "Valorant",
          Assets.gameWithdrawIcons.icValorant.svg(width: AppSize.w24),
          Color(0xFFFF4655),
          FormData(
            "Riot ID (Name#Tag)",
            Icon(Icons.person, size: 24, color: Color(0xFFFF4655)),
            RegexHelper.riot_id,
          ),
        ),
        WalletItem(
          "Genshin Impact",
          Assets.gameWithdrawIcons.icGenshinimpact.svg(width: AppSize.w24),
          Color(0xFFF28C28),
          FormData(
            "User ID & Server",
            Icon(
              Icons.videogame_asset_rounded,
              size: 24,
              color: Color(0xFFF28C28),
            ),
            RegexHelper.uid_zone,
          ),
        ),
        WalletItem(
          "Robux",
          Assets.gameWithdrawIcons.icRobux.svg(width: AppSize.w24),
          Color(0xFF00A2FF),
          FormData(
            "Roblox Username",
            Icon(Icons.person, size: 24, color: Color(0xFF00A2FF)),
            RegexHelper.ea_id,
          ),
        ),
        WalletItem(
          "Minecraft",
          Assets.gameWithdrawIcons.icMinecraft.svg(width: AppSize.w24),
          Color(0xFF5C8A3E),
          FormData(
            "Xbox Gamertag / Email",
            Icon(Icons.mail, size: 24, color: Color(0xFF5C8A3E)),
            RegexHelper.email_or_phone,
          ),
        ),
        WalletItem(
          "Clash of Clans",
          Assets.gameWithdrawIcons.icClashofclans.svg(width: AppSize.w24),
          Color(0xFFD4AF37),
          FormData(
            "Player Tag (#...)",
            Icon(Icons.tag, size: 24, color: Color(0xFFFFD700)),
            RegexHelper.game_tag,
          ),
        ),
        WalletItem(
          "EA FC",
          Assets.gameWithdrawIcons.icEafc.svg(width: AppSize.w24),
          Color(0xFF444444),
          FormData(
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
        _error = context.l10n.pleaseEnterWalletAddress;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (amount == null) {
        _error = context.l10n.pleaseEnterValidAmount;
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

  /// Get Withdraw List (Stream)
  Stream<QuerySnapshot> getWithdrawStream() {
    final userId = _db.userModel!.userId;

    return _firestore
        .collection('withdraw')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
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
