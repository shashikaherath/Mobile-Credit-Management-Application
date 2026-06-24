import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/shared/widgets/app_back_button.dart';
import 'package:provider/provider.dart';

// --- Reusable Mock Infrastructure ---
// Rationale: Adopted from widget_test.dart to ensure project-wide consistency.
class BaseMockProvider extends ChangeNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) return null; 
    if (invocation.isSetter) return; 
    if (invocation.memberName == #addListener || invocation.memberName == #removeListener) {
       return super.noSuchMethod(invocation); 
    }
    return null; 
  }
}

class MockAuthProvider extends BaseMockProvider implements AuthProvider {
  @override
  bool get isLoading => false;
  
  @override
  String? get error => null;
}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
  });

  Widget createTestWidget(Widget child) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: mockAuthProvider,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('OtpVerificationScreen should display AppBackButton', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(
      OtpVerificationScreen(
        target: 'test@example.com',
        onVerified: () {},
      ),
    ));

    // Verify AppBackButton is present
    expect(find.byType(AppBackButton), findsOneWidget);
  });

  testWidgets('AppBackButton should pop the navigator when tapped', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => createTestWidget(
                  OtpVerificationScreen(
                    target: '0712345678',
                    onVerified: () {},
                  ),
                ),
              ),
            );
          },
          child: const Text('Push OTP'),
        ),
      ),
    ));

    // Push the OTP screen
    await tester.tap(find.text('Push OTP'));
    await tester.pumpAndSettle();

    // Verify we are on OTP screen
    expect(find.byType(OtpVerificationScreen), findsOneWidget);

    // Tap back button
    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    // Verify we are back on the previous screen
    expect(find.byType(OtpVerificationScreen), findsNothing);
    expect(find.text('Push OTP'), findsOneWidget);
  });
}
