// lib/features/payment/presentation/widgets/payment_method_selector.dart
import 'package:flutter/material.dart';
import '../../domain/interfaces/payment_gateway.dart';

class PaymentMethodSelector extends StatelessWidget {
  final List<PaymentGateway> gateways;
  final String selectedGatewayId;
  final Function(String) onSelected;

  const PaymentMethodSelector({
    super.key,
    required this.gateways,
    required this.selectedGatewayId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: gateways.map((gateway) => _buildPaymentMethodItem(context, gateway)).toList(),
    );
  }

  Widget _buildPaymentMethodItem(BuildContext context, PaymentGateway gateway) {
    final isSelected = gateway.gatewayId == selectedGatewayId;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onSelected(gateway.gatewayId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Radio<String>(
                value: gateway.gatewayId,
                groupValue: selectedGatewayId,
                onChanged: (value) {
                  if (value != null) {
                    onSelected(value);
                  }
                },
              ),
              const SizedBox(width: 12),
              // Logo image or placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 40,
                  child: Image.asset(
                    gateway.iconAsset,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Text(
                            gateway.displayName.substring(0, 2),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gateway.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pay securely with ${gateway.displayName}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

