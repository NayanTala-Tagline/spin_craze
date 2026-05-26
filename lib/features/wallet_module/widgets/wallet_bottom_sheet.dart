import 'package:spin_craze/extension/ext_string_alert.dart';
import 'package:spin_craze/features/wallet_module/model/wallet_models.dart';
import 'package:spin_craze/features/wallet_module/provider/wallet_provider.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const Color _kPrimary = Color(0xFF1164FF);
const Color _kPrimaryDark = Color(0xFF0040E0);
const Color _kFieldBg = Color(0xFFF5F8FD);
const Color _kBorder = Color(0xFFD9E2F0);
const Color _kTextPrimary = Color(0xFF0E1A2B);
const Color _kTextMuted = Color(0xFF6B7A92);
const Color _kError = Color(0xFFE05252);

class WalletBottomSheet extends StatelessWidget {
  final WalletItem item;
  const WalletBottomSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.90,
            ),
            padding: EdgeInsets.fromLTRB(
              AppSize.w24,
              AppSize.h16,
              AppSize.w24,
              AppSize.h24,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSize.r24),
              ),
            ),
            child: Form(
              key: provider.formKey,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: AppSize.w40,
                      height: AppSize.h4,
                      decoration: BoxDecoration(
                        color: _kBorder,
                        borderRadius: BorderRadius.circular(AppSize.r100),
                      ),
                    ),
                    SizedBox(height: AppSize.h20),
                    Container(
                      width: AppSize.sp64,
                      height: AppSize.sp64,
                      padding: EdgeInsets.all(AppSize.w12),
                      decoration: BoxDecoration(
                        color: _kFieldBg,
                        borderRadius: BorderRadius.circular(AppSize.r16),
                        border: Border.all(color: _kBorder),
                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: item.icon,
                      ),
                    ),
                    SizedBox(height: AppSize.h16),
                    Text(
                      'Withdraw to ${item.title}',
                      style: TextStyle(
                        fontFamily: 'SFPro',
                        fontSize: AppSize.sp18,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    SizedBox(height: AppSize.h20),
                    _LightTextField(
                      hint: item.formData.title,
                      icon: item.formData.icon,
                      controller: provider.btcWalletAddressController,
                      regex: item.formData.regex,
                    ),
                    SizedBox(height: AppSize.h14),
                    _LightTextField(
                      hint: 'Amount (Coins)',
                      icon: Icon(
                        Icons.monetization_on_rounded,
                        size: AppSize.sp22,
                        color: _kPrimary,
                      ),
                      controller: provider.amountController,
                      onChanged: provider.onAmountChanged,
                      showSuffix: true,
                      isAmount: true,
                    ),
                    if (provider.amountController.text.isNotEmpty) ...[
                      SizedBox(height: AppSize.h10),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSize.w12,
                          vertical: AppSize.h10,
                        ),
                        decoration: BoxDecoration(
                          color: _kFieldBg,
                          borderRadius: BorderRadius.circular(AppSize.r12),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Text(
                          'Value: \$${provider.convertedValue}',
                          style: TextStyle(
                            fontFamily: 'SFPro',
                            fontSize: AppSize.sp13,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: AppSize.h14),
                    _LightTextField(
                      hint: 'Additional Note (Optional)',
                      icon: Icon(
                        Icons.sticky_note_2_rounded,
                        size: AppSize.sp22,
                        color: _kTextMuted,
                      ),
                      controller: provider.noteController,
                      isOptional: true,
                    ),
                    SizedBox(height: AppSize.h24),
                    _ConfirmButton(
                      isLoading: provider.isLoading,
                      onPressed: provider.isLoading
                          ? null
                          : () async {
                              if (!provider.formKey.currentState!.validate()) {
                                return;
                              }
                              AnalyticsManager.instance.logEvent(
                                name: 'withdraw_submit_attempt',
                                parameters: {'method': item.title},
                              );
                              final success = await provider.createWithdraw(
                                context,
                              );
                              if (!context.mounted) return;

                              if (success) {
                                AnalyticsManager.instance.logEvent(
                                  name: 'withdraw_submit_success',
                                  parameters: {'method': item.title},
                                );
                                provider.resetWithdrawForm();
                                'Withdraw request sent'.showSuccessAlert();
                                context.pop();
                              } else {
                                AnalyticsManager.instance.logEvent(
                                  name: 'withdraw_submit_failed',
                                  parameters: {
                                    'method': item.title,
                                    'error': provider.error ?? 'unknown',
                                  },
                                );
                                (provider.error ?? 'Error').showErrorAlert();
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LightTextField extends StatelessWidget {
  const _LightTextField({
    required this.hint,
    required this.icon,
    this.controller,
    this.onChanged,
    this.regex,
    this.isOptional = false,
    this.isAmount = false,
    this.showSuffix = false,
  });

  final String hint;
  final Widget icon;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? regex;
  final bool isOptional;
  final bool isAmount;
  final bool showSuffix;

  @override
  Widget build(BuildContext context) {
    final minAmount = RemoteConfigService.instance.minWithdrawAmount;
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: isAmount
          ? const TextInputType.numberWithOptions(decimal: false)
          : TextInputType.text,
      cursorColor: _kPrimary,
      style: TextStyle(
        fontFamily: 'SFPro',
        fontSize: AppSize.sp15,
        fontWeight: FontWeight.w600,
        color: _kTextPrimary,
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) return isOptional ? null : 'Field required';
        if (isAmount) {
          final amount = int.tryParse(trimmed);
          if (amount == null) return 'Enter a valid number';
          if (amount < minAmount) return 'Minimum is $minAmount coins';
          return null;
        }
        if (regex != null && !RegExp(regex!).hasMatch(trimmed)) {
          return 'Invalid input';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(
          fontFamily: 'SFPro',
          color: _kTextMuted,
          fontSize: AppSize.sp14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: 'SFPro',
          color: _kPrimary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSize.w12),
          child: SizedBox(
            width: AppSize.sp22,
            height: AppSize.sp22,
            child: FittedBox(fit: BoxFit.contain, child: icon),
          ),
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: AppSize.sp40,
          minHeight: AppSize.sp40,
        ),
        suffixText: showSuffix ? 'Min: $minAmount' : null,
        suffixStyle: TextStyle(
          fontFamily: 'SFPro',
          color: _kTextMuted,
          fontSize: AppSize.sp13,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: _kFieldBg,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSize.w14,
          vertical: AppSize.h14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r14),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r14),
          borderSide: const BorderSide(color: _kPrimary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r14),
          borderSide: const BorderSide(color: _kError, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSize.r14),
          borderSide: const BorderSide(color: _kError, width: 1.6),
        ),
        errorStyle: TextStyle(
          fontFamily: 'SFPro',
          color: _kError,
          fontSize: AppSize.sp12,
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSize.r100),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSize.r100),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          height: AppSize.h52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSize.r100),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_kPrimary, _kPrimaryDark],
            ),
            boxShadow: onPressed == null
                ? null
                : [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.3),
                      blurRadius: AppSize.r16,
                      offset: Offset(0, AppSize.h6),
                    ),
                  ],
          ),
          child: isLoading
              ? SizedBox(
                  width: AppSize.sp22,
                  height: AppSize.sp22,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'CONFIRM WITHDRAWAL',
                  style: TextStyle(
                    fontFamily: 'SFPro',
                    color: Colors.white,
                    fontSize: AppSize.sp14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
        ),
      ),
    );
  }
}

