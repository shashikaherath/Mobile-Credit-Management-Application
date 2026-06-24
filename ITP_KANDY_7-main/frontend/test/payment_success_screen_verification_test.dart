
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/sales/presentation/screens/payment_success_screen.dart';

void main() {
  testWidgets('PaymentSuccessScreen renders correctly after removing confetti', (WidgetTester tester) async {
    // Disable runtime fetching of fonts
    GoogleFonts.config.allowRuntimeFetching = false;

    final mockSaleDetails = {
      'totalAmount': 1500.50,
      'id': 'INV-12345',
      'paymentMethod': 'card',
      'items': [
        {'name': 'Item 1', 'price': 500.0},
        {'name': 'Item 2', 'price': 1000.50},
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentSuccessScreen(saleDetails: mockSaleDetails),
      ),
    );

    // Initial pump to start animations
    await tester.pump();
    // Pump more frames to allow FadeInDown/FadeInUp to show up
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Title
    expect(find.text('Payment Successful'), findsOneWidget);

    // Verify Total Amount
    expect(find.text('Rs. 1500.50'), findsOneWidget);

    // Verify Invoice ID
    expect(find.text('#INV-12345'), findsOneWidget);

    // Verify Payment Method
    expect(find.text('CARD'), findsOneWidget);

    // Verify Items Count
    expect(find.text('2 Items'), findsOneWidget);

    // Verify Status Badge
    expect(find.text('COMPLETED'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Back to Dashboard'), findsOneWidget);
    expect(find.text('Receipt'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    
    // Check for icons
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    expect(find.byIcon(Icons.share_rounded), findsOneWidget);

    // Stop animations to avoid pending timer error from animate_do's Pulse
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  });
}
