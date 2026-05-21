import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/extension/ext_string_alert.dart';
import 'package:spin_craze/features/wallet_module/model/wallet_models.dart';
import 'package:spin_craze/features/wallet_module/provider/wallet_provider.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:spin_craze/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class WalletBottomSheet extends StatelessWidget {
  final WalletItem item;
  const WalletBottomSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isWhite = item.color.toARGB32() == 0xFFFFFFFF;
    final _ = isWhite; // color check preserved for future use

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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.themeColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
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
                    const SizedBox(height: 5),
                    item.icon,
                    const SizedBox(height: 20),

                    Text(
                      "Withdraw to ${item.title}",
                      style: context.textTheme.titleLarge?.copyWith(
                        fontSize: AppSize.sp22,
                        fontWeight: FontWeight.w500,
                        color: context.themeTextColors.primary.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      context,
                      item.formData.title,
                      Padding(
                        padding: EdgeInsets.only(bottom: 3),
                        child: item.formData.icon,
                      ),
                      controller: provider.btcWalletAddressController,
                      regex: item.formData.regex,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      context,
                      "Amount (Coins) ",
                      Padding(
                        padding: EdgeInsets.only(bottom: 3),
                        child: Icon(
                          Icons.monetization_on_sharp,
                          size: 24,
                          color: item.color,
                        ),
                      ),
                      controller: provider.amountController,
                      onChanged: provider.onAmountChanged,
                      suffix: true,
                      isAmount: true,
                    ),

                    if (provider.amountController.text.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
                            ),
                            alignment: AlignmentGeometry.centerStart,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: context.themeColors.error.withValues(
                                  alpha: 0.5,
                                ),
                                width: 0.3,
                              ),
                            ),
                            child: Text(
                              "Value: \$${provider.convertedValue}",
                              style: context.textTheme.titleSmall?.copyWith(
                                fontSize: AppSize.sp14,
                                fontWeight: FontWeight.normal,
                                color: context.themeColors.warning,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    /// Note
                    _buildTextField(
                      context,
                      "Additional Note (Optional)",
                      Padding(
                        padding: EdgeInsets.only(bottom: 3),
                        child: Icon(Icons.note, size: 24, color: Colors.grey),
                      ),
                      controller: provider.noteController,
                      isOptional: true,
                    ),

                    const SizedBox(height: 30),

                    /// Button
                    AppButton(
                      label: context.l10n.confirmWithdrawal,
                      variant: AppButtonVariant.gradient,
                      isLoading: provider.isLoading,
                      isDisabled: provider.isLoading,
                      onPressed: () async {
                        if (!provider.formKey.currentState!.validate()) {
                          return;
                        }
                        AnalyticsManager.instance.logEvent(
                          name: 'withdraw_submit_attempt',
                          parameters: {'method': item.title},
                        );
                        final success = await provider.createWithdraw(context);
                        if (!context.mounted) return;

                        if (success) {
                          AnalyticsManager.instance.logEvent(
                            name: 'withdraw_submit_success',
                            parameters: {'method': item.title},
                          );
                          provider.resetWithdrawForm();
                          context.l10n.withdrawRequestSent.showSuccessAlert();
                          context.pop();
                        } else {
                          AnalyticsManager.instance.logEvent(
                            name: 'withdraw_submit_failed',
                            parameters: {
                              'method': item.title,
                              'error': provider.error ?? 'unknown',
                            },
                          );
                          (provider.error ?? context.l10n.error)
                              .showErrorAlert();
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

Widget _buildTextField(
  BuildContext context,
  String hint,
  Widget icon, {
  TextEditingController? controller,
  Function(String)? onChanged,
  bool suffix = false,
  String? regex,
  bool isOptional = false,
  bool isAmount = false,
}) {
  final minAmount = RemoteConfigService.instance.minWithdrawAmount;

  return TextFormField(
    controller: controller,
    onChanged: onChanged,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    keyboardType: isAmount
        ? const TextInputType.numberWithOptions(decimal: false)
        : TextInputType.text,
    validator: (value) {
      final trimmed = value?.trim() ?? '';

      if (trimmed.isEmpty) {
        return isOptional ? null : context.l10n.fieldRequired;
      }

      if (isAmount) {
        final amount = int.tryParse(trimmed);
        if (amount == null) {
          return context.l10n.enterValidNumber;
        }
        if (amount < minAmount) {
          return "Minimum is $minAmount coins";
        }
        return null;
      }

      if (regex != null) {
        final regExp = RegExp(regex);
        if (!regExp.hasMatch(trimmed)) {
          return context.l10n.invalidInput;
        }
      }

      return null;
    },
    textAlignVertical: TextAlignVertical.center,
    cursorColor: context.themeColors.primary,
    style: context.textTheme.titleSmall?.copyWith(
      fontSize: AppSize.sp18,
      fontWeight: FontWeight.normal,
      color: context.themeTextColors.primary.withValues(alpha: 0.7),
    ),
    decoration: InputDecoration(
      labelText: hint,
      labelStyle: TextStyle(color: context.themeTextColors.secondary),
      floatingLabelStyle: TextStyle(color: context.themeColors.primary),
      prefixIcon: icon,
      suffixText: suffix ? "Min: $minAmount" : null,
      suffixStyle: context.textTheme.titleMedium?.copyWith(
        fontSize: AppSize.sp16,
        fontWeight: FontWeight.normal,
        color: context.themeTextColors.primary.withValues(alpha: 0.7),
      ),
      filled: true,
      fillColor: context.themeColors.background,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.themeColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.themeColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.themeColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.themeColors.error, width: 2),
      ),
      errorStyle: TextStyle(color: context.themeColors.error, fontSize: 12),
    ),
  );
}
