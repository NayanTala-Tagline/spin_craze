import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdRepository {
  static void showConsentUMP() {
    final params = ConsentRequestParameters(
      // consentDebugSettings: ConsentDebugSettings(
      //   debugGeography: DebugGeography.debugGeographyEea,
      //   testIdentifiers: ['B2C541AE77176D762F0E634477AB3520']
      // ),
    );
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          loadForm();
        }
      },
      (FormError error) {
        // Handle the error
      },
    );
  }

  static void loadForm() {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        var status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show((FormError? formError) {
            loadForm();
          });
        }
      },
      (formError) {
        // Handle the error
      },
    );
  }
}
