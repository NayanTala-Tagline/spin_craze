import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_string_alert.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/logger.dart';
import 'package:spin_craze/widgets/app_button.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:spin_craze/widgets/common_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spin_craze/extension/ext_localization.dart';

/// Lets a user submit a support ticket. Title + description are written to
/// the `support_tickets` collection in Firestore, keyed by an auto-generated
/// document id, with the device id and a server timestamp.
class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    AnalyticsManager.instance.logScreenView(
      screenName: 'support',
      screenClass: 'SupportPage',
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
      context.l10n.thanksMessageReceived.showSuccessAlert();
      context.pop();
    } catch (e) {
      AnalyticsManager.instance.logEvent(
        name: 'support_ticket_submit_failed',
        parameters: {'error': e.toString()},
      );
      'Failed to submit support ticket: $e'.logE;
      if (!mounted) return;
      context.l10n.couldNotSubmitTryAgain.showErrorAlert();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: CommonAppBar(title: context.l10n.support, showBack: true),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSize.w20,
              AppSize.h24,
              AppSize.w20,
              AppSize.h32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we help?',
                    style: context.textTheme.titleLarge?.copyWith(
                      color: context.themeTextColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: AppSize.sp22,
                    ),
                  ),
                  SizedBox(height: AppSize.h10),
                  Text(
                    'Tell us what went wrong or what you need a hand with. '
                    'Our team reviews every message.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.themeTextColors.secondary,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: AppSize.h24),
                  _FieldLabel(context.l10n.title),
                  SizedBox(height: AppSize.h8),
                  _SupportField(
                    controller: _titleController,
                    hint: context.l10n.shortSummary,
                    maxLines: 1,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return context.l10n.pleaseAddTitle;
                      if (value.length < 3) return context.l10n.titleTooShort;
                      return null;
                    },
                  ),
                  SizedBox(height: AppSize.h20),
                  _FieldLabel(context.l10n.description),
                  SizedBox(height: AppSize.h8),
                  _SupportField(
                    controller: _descController,
                    hint: context.l10n.descriptionHint,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty)
                        return context.l10n.pleaseAddDescription;
                      if (value.length < 10) {
                        return context.l10n.descriptionTooShort;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSize.h32),
                  AppButton(
                    label: context.l10n.submit,
                    variant: AppButtonVariant.gradient,
                    isLoading: _submitting,
                    borderRadius: AppSize.r100,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.labelMedium?.copyWith(
        color: context.themeTextColors.secondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SupportField extends StatelessWidget {
  const _SupportField({
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
    final colors = context.themeColors;
    final textColors = context.themeTextColors;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: textInputAction,
      validator: validator,
      style: context.textTheme.bodyMedium?.copyWith(color: textColors.primary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.textTheme.bodyMedium?.copyWith(
          color: textColors.secondary.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: colors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSize.w16,
          vertical: AppSize.h14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r12),
          borderSide: BorderSide(color: const Color(0xFF29B0E6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r12),
          borderSide: const BorderSide(color: Color(0xFFFF5183)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r12),
          borderSide: const BorderSide(color: Color(0xFFFF5183), width: 1.5),
        ),
      ),
    );
  }
}
