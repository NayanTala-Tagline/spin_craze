import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/features/auth_module/provider/auth_provider.dart';
import 'package:spin_craze/gen/assets.gen.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/app_button.dart';
import 'package:spin_craze/widgets/common_background.dart';
import 'package:spin_craze/widgets/glow_container.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'login',
      screenClass: 'LoginScreen',
    );
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const _LoginBody(),
    );
  }
}

class _LoginBody extends StatelessWidget {
  const _LoginBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final textColors = context.themeTextColors;

    return CommonBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSize.w24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // App icon
                GlowContainer(
                  accent: Colors.white,
                  borderRadius: AppSize.r24,
                  child: Container(
                    width: AppSize.w100,
                    height: AppSize.w100,
                    decoration: BoxDecoration(
                      gradient: colors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSize.r24),
                      border: Border.all(
                        color: colors.secondary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(child: Assets.images.logo.image()),
                  ),
                ),

                SizedBox(height: AppSize.h24),

                // App name
                Text(
                  context.l10n.appTitle,
                  style: context.textTheme.headlineLarge?.copyWith(
                    fontSize: AppSize.sp32,
                    fontWeight: FontWeight.w700,
                    color: textColors.primary,
                    letterSpacing: 2,
                  ),
                ),

                SizedBox(height: AppSize.h8),

                // Subtitle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _subtitleChip(context, context.l10n.watch),
                    _diamond(context),
                    _subtitleChip(context, context.l10n.earn),
                    _diamond(context),
                    _subtitleChip(context, context.l10n.play),
                  ],
                ),

                const Spacer(flex: 2),

                // Welcome card
                GlowContainer(
                  accent: colors.primary,
                  borderRadius: AppSize.r20,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSize.w24),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppSize.r20),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          context.l10n.welcome,
                          style: context.textTheme.titleLarge?.copyWith(
                            fontSize: AppSize.sp22,
                            fontWeight: FontWeight.w700,
                            color: textColors.primary,
                          ),
                        ),

                        SizedBox(height: AppSize.h6),

                        Text(
                          context.l10n.signInToAccessWallet,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontSize: AppSize.sp14,
                            color: textColors.secondary,
                          ),
                        ),

                        SizedBox(height: AppSize.h24),

                        // Google button
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) => GlowContainer(
                            accent: colors.primary,
                            borderRadius: AppSize.r16,
                            child: AppButton(
                              label: context.l10n.continueWithGoogle,
                              variant: AppButtonVariant.outline,
                              isLoading: auth.isGoogleLoading,
                              leading: auth.isGoogleLoading
                                  ? null
                                  : Assets.images.googleLogo.image(
                                      height: AppSize.sp18,
                                      width: AppSize.sp18,
                                    ),
                              isDisabled: auth.isGuestLoading,
                              onPressed: auth.isGuestLoading
                                  ? null
                                  : () => _handleGoogle(context, auth),
                            ),
                          ),
                        ),

                        SizedBox(height: AppSize.h12),

                        // Guest button
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) => GlowContainer(
                            accent: colors.primary,
                            borderRadius: AppSize.r16,
                            child: AppButton(
                              label: context.l10n.continueAsGuest,
                              variant: AppButtonVariant.outline,
                              isLoading: auth.isGuestLoading,
                              leading: auth.isGuestLoading
                                  ? null
                                  : Icon(
                                      Icons.person_outline_rounded,
                                      size: AppSize.w20,
                                      color: colors.primary,
                                    ),
                              isDisabled: auth.isGoogleLoading,
                              onPressed: auth.isGoogleLoading
                                  ? null
                                  : () => _handleGuest(context, auth),
                            ),
                          ),
                        ),

                        // Error message
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (auth.errorMessage == null) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: EdgeInsets.only(top: AppSize.h12),
                              child: Text(
                                auth.errorMessage!,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colors.error,
                                  fontSize: AppSize.sp12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Terms & Privacy Policy
                Padding(
                  padding: EdgeInsets.only(bottom: AppSize.h16),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: AppSize.sp12,
                        color: textColors.secondary,
                      ),
                      children: [
                        TextSpan(text: '${context.l10n.byContinuingAgree} '),
                        TextSpan(
                          text: context.l10n.terms,
                          style: TextStyle(
                            color: colors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: colors.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl(
                              RemoteConfigService.instance.termsAndConditions,
                            ),
                        ),
                        const TextSpan(text: ' & '),
                        TextSpan(
                          text: context.l10n.privacyPolicy,
                          style: TextStyle(
                            color: colors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: colors.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchUrl(
                              RemoteConfigService.instance.privacyPolicyUrl,
                            ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _subtitleChip(BuildContext context, String text) {
    return Text(
      text,
      style: context.textTheme.bodySmall?.copyWith(
        fontSize: AppSize.sp12,
        letterSpacing: 2,
        color: context.themeTextColors.secondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _diamond(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.w6),
      child: Icon(
        Icons.diamond_outlined,
        size: AppSize.w10,
        color: context.themeColors.secondary,
      ),
    );
  }

  Future<void> _handleGoogle(BuildContext context, AuthProvider auth) async {
    AnalyticsManager.instance.logEvent(
      name: 'login_attempt',
      parameters: {'method': 'google'},
    );
    final success = await auth.signInWithGoogle();
    if (success) {
      AnalyticsManager.instance.logEvent(
        name: 'login_success',
        parameters: {'method': 'google'},
      );
      if (context.mounted) context.goNamed(AppRoutes.home);
    } else {
      AnalyticsManager.instance.logEvent(
        name: 'login_failed',
        parameters: {
          'method': 'google',
          'error': auth.errorMessage ?? 'unknown',
        },
      );
    }
  }

  Future<void> _handleGuest(BuildContext context, AuthProvider auth) async {
    AnalyticsManager.instance.logEvent(
      name: 'login_attempt',
      parameters: {'method': 'guest'},
    );
    final success = await auth.continueAsGuest();
    if (success) {
      AnalyticsManager.instance.logEvent(
        name: 'login_success',
        parameters: {'method': 'guest'},
      );
      if (context.mounted) context.goNamed(AppRoutes.home);
    } else {
      AnalyticsManager.instance.logEvent(
        name: 'login_failed',
        parameters: {
          'method': 'guest',
          'error': auth.errorMessage ?? 'unknown',
        },
      );
    }
  }

  void _launchUrl(String url) async {
    AnalyticsManager.instance.logEvent(
      name: 'login_policy_link_tap',
      parameters: {'url': url},
    );
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
