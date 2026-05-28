import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/extension/ext_string_alert.dart';
import 'package:spin_craze/gen/fonts.gen.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/logger.dart';
import 'package:spin_craze/widgets/gradient_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
// Shared with the onboarding / language redesign. Kept local to this file so
// the rest of the app (still on the dark theme) is untouched.
const _bgGradient = LinearGradient(
  colors: [Color(0xFFF3F7FF), Color(0xFFE7EFFF)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);
const _ctaGradient = LinearGradient(
  colors: [Color(0xFF1B4FF5), Color(0xFF0034D9)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);
const _titleColor = Color(0xFF0A1A33);
const _bodyColor = Color(0xFF55617A);
const _accentBlue = Color(0xFF1B4FF5);
const _pillBorder = Color(0xFFB2D3FF);
const _fieldFill = Color(0xFFFFFFFF);
const _errorColor = Color(0xFFFF4D67);
const _statusBarStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

/// Lets a user submit a support ticket. Title + description are written to
/// the `support_tickets` collection in Firestore, keyed by an auto-generated
/// document id, with the device id and a server timestamp.
class ScSupportPage extends StatefulWidget {
  const ScSupportPage({super.key});

  @override
  State<ScSupportPage> createState() => _ScSupportPageState();
}

class _ScSupportPageState extends State<ScSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logScreenView(
      screenName: 'support',
      screenClass: 'ScSupportPage',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    AnalyticsManager.instance.logEvent(name: 'support_ticket_submit_attempt');
    setState(() => _submitting = true);
    try {
      final deviceId =
          Injector.instance.get<AppDB>().userModel?.deviceId ?? 'unknown';
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'deviceId': deviceId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      AnalyticsManager.instance.logEvent(
        name: 'support_ticket_submit_success',
        parameters: {'description_length': _descController.text.trim().length},
      );
      'Support ticket submitted'.logI;
      if (!mounted) return;
      context.l10n.thanksMsgReceived.showSuccessAlert();
      context.pop();
    } catch (e) {
      AnalyticsManager.instance.logEvent(
        name: 'support_ticket_submit_failed',
        parameters: {'error': e.toString()},
      );
      'Failed to submit support ticket: $e'.logE;
      if (!mounted) return;
      context.l10n.couldNotSubmit.showErrorAlert();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _statusBarStyle,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: _bgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScTopBar(
                  title: context.l10n.support,
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      AppSize.w24,
                      AppSize.h12,
                      AppSize.w24,
                      AppSize.h32,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.howCanWeHelp,
                            style: TextStyle(
                              fontFamily: FontFamily.sFPro,
                              fontWeight: FontWeight.w800,
                              fontSize: AppSize.sp24,
                              color: _titleColor,
                              letterSpacing: 0.1,
                            ),
                          ),
                          SizedBox(height: AppSize.h10),
                          Text(
                            context.l10n.supportDesc,
                            style: TextStyle(
                              fontFamily: FontFamily.sFPro,
                              fontWeight: FontWeight.w400,
                              fontSize: AppSize.sp14,
                              height: 1.5,
                              color: _bodyColor,
                            ),
                          ),
                          SizedBox(height: AppSize.h28),
                          _ScFieldLabel(l10n.titleLabel),
                          SizedBox(height: AppSize.h10),
                          _ScSupportField(
                            controller: _titleController,
                            hint: l10n.shortSummary,
                            maxLines: 1,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) {
                                return l10n.pleaseAddTitle;
                              }
                              if (value.length < 3) {
                                return l10n.titleTooShort;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppSize.h20),
                          _ScFieldLabel(l10n.descriptionLabel),
                          SizedBox(height: AppSize.h10),
                          _ScSupportField(
                            controller: _descController,
                            hint: l10n.describeIssue,
                            maxLines: 6,
                            textInputAction: TextInputAction.newline,
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) {
                                return l10n.pleaseAddDesc;
                              }
                              if (value.length < 10) {
                                return l10n.descTooShort;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppSize.h32),
                          GradientButton(
                            text: l10n.submit,
                            onPressed: _submit,
                            isLoading: _submitting,
                            height: AppSize.h54,
                            borderRadius: 30,
                            gradient: _ctaGradient,
                            textStyle: TextStyle(
                              fontFamily: FontFamily.sFPro,
                              fontWeight: FontWeight.w700,
                              fontSize: AppSize.sp17,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
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
}

// ─────────────────────────────────────────────────────────────────────────────

/// Settings-style header: navy back arrow + centered title, matching the
/// redesigned [ScLanguagePage] settings bar.
class _ScTopBar extends StatelessWidget {
  const _ScTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSize.w4,
        AppSize.h6,
        AppSize.w12,
        AppSize.h4,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: _titleColor,
              size: AppSize.sp22,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(right: AppSize.w36),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: FontFamily.sFPro,
                    fontWeight: FontWeight.w700,
                    fontSize: AppSize.sp18,
                    color: _titleColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScFieldLabel extends StatelessWidget {
  const _ScFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: FontFamily.sFPro,
        fontWeight: FontWeight.w600,
        fontSize: AppSize.sp14,
        color: _titleColor,
      ),
    );
  }
}

class _ScSupportField extends StatelessWidget {
  const _ScSupportField({
    required this.controller,
    required this.hint,
    required this.maxLines,
    required this.validator,
    required this.textInputAction,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSize.r18);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: textInputAction,
      validator: validator,
      cursorColor: _accentBlue,
      style: TextStyle(
        fontFamily: FontFamily.sFPro,
        fontSize: AppSize.sp15,
        color: _titleColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: FontFamily.sFPro,
          fontSize: AppSize.sp14,
          color: _bodyColor.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: _fieldFill,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSize.w18,
          vertical: AppSize.h16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: _pillBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: _accentBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: _errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: _errorColor, width: 1.8),
        ),
        errorStyle: TextStyle(
          fontFamily: FontFamily.sFPro,
          fontSize: AppSize.sp12,
          color: _errorColor,
        ),
      ),
    );
  }
}
