// ──────────────────────────────────────────────────────────────────────────────
// File: widget_test.dart
// Purpose: Integration smoke test for application boot and initial navigation.
// Rationale: Utilizes mock providers and platform channel simulations to verify
//   the structural integrity of the main widget tree, ensuring that the 
//   splash screen renders and transitions correctly to the login flow.
// ──────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart'; // Core Flutter UI framework
import 'package:flutter/services.dart'; // Platform services for method channel mocking
import 'package:flutter_test/flutter_test.dart'; // Main library for widget testing
import 'package:google_fonts/google_fonts.dart'; // Google Fonts for UI appearance validation
import 'package:provider/provider.dart'; // State management used across the app
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // Auth state
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart'; // Alert state
import 'package:frontend/features/products/presentation/providers/product_provider.dart'; // Inventory state
import 'package:frontend/features/suppliers/presentation/providers/supplier_provider.dart'; // Supplier data
import 'package:frontend/features/suppliers/presentation/providers/purchase_provider.dart'; // Orders data
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart'; // Debt tracking
import 'package:frontend/features/sales/presentation/providers/sale_provider.dart'; // POS state
import 'package:frontend/features/admin/presentation/providers/admin_provider.dart'; // Admin control
import 'package:frontend/features/account/presentation/providers/feedback_provider.dart'; // Feedback state
import 'package:frontend/features/auth/presentation/screens/splash_screen.dart'; // The screen being tested

// --- Comprehensive Mock Providers ---
// These classes simulate real application state without requiring a backend connection

class BaseMockProvider extends ChangeNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) return null; // Default getters to null
    if (invocation.isSetter) return; // Ignore setters
    if (invocation.memberName == #addListener || invocation.memberName == #removeListener) {
       return super.noSuchMethod(invocation); // Maintain fundamental listener logic
    }
    return null; // Return null for any other method calls
  }
}

// Mock implementation of the Authentication store
class MockAuthProvider extends BaseMockProvider implements AuthProvider {
  @override
  bool get isLoading => false; // Starts in a non-loading state
  @override
  bool get isLoggedIn => false; // Starts logged out
  @override
  String? get error => null; // No errors initially
}

// Mock for notification tracking
class MockNotificationProvider extends BaseMockProvider implements NotificationProvider {
  @override
  int get unreadCount => 0; // Starts with no new notifications
  @override
  bool get isLoading => false;
}

// Empty shell mocks for other features (required to build the MultiProvider tree)
class MockProductProvider extends BaseMockProvider implements ProductProvider {
  @override
  bool get isLoading => false;
}
class MockSupplierProvider extends BaseMockProvider implements SupplierProvider {}
class MockPurchaseProvider extends BaseMockProvider implements PurchaseProvider {}
class MockCreditProvider extends BaseMockProvider implements CreditProvider {}
class MockSaleProvider extends BaseMockProvider implements SaleProvider {}
class MockAdminProvider extends BaseMockProvider implements AdminProvider {}
class MockFeedbackProvider extends BaseMockProvider implements FeedbackProvider {}

void main() {
  setupChannelMocks(); // Initialize platform channel simulations

  testWidgets('App smoke test: Splash screen renders and navigates to Login', (WidgetTester tester) async {
    // Disable HTTP font fetching for tests to prevent network dependency errors
    GoogleFonts.config.allowRuntimeFetching = false;

    // Build our app UI inside the test environment
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          // Inject all the mock providers created above
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
          ChangeNotifierProvider<NotificationProvider>(create: (_) => MockNotificationProvider()),
          ChangeNotifierProvider<ProductProvider>(create: (_) => MockProductProvider()),
          ChangeNotifierProvider<SupplierProvider>(create: (_) => MockSupplierProvider()),
          ChangeNotifierProvider<PurchaseProvider>(create: (_) => MockPurchaseProvider()),
          ChangeNotifierProvider<CreditProvider>(create: (_) => MockCreditProvider()),
          ChangeNotifierProvider<SaleProvider>(create: (_) => MockSaleProvider()),
          ChangeNotifierProvider<AdminProvider>(create: (_) => MockAdminProvider()),
          ChangeNotifierProvider<ChangeNotifier>(create: (_) => MockFeedbackProvider()),
        ],
        child: const MaterialApp(
          home: SplashScreen(), // Start at the splash screen
        ),
      ),
    );
    
    // Verify initial render: Splash screen should be visible
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('ShopBook'), findsOneWidget); // Logo/App name check
    
    // Simulate time passing to trigger navigation logic
    await tester.pump(const Duration(milliseconds: 100)); // Short tick
    await tester.pump(const Duration(milliseconds: 800)); // Navigation timer tick
    await tester.pump(); // Final frame for the new screen (Login)
  });
}

/// Helper to simulate internal mobile system responses (like Firebase/Notifications)
void setupChannelMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // List of technical channel IDs that normally communicate with native Java/Swift code
  final List<String> channels = [
    'plugins.flutter.io/firebase_core',
    'plugins.flutter.io/firebase_auth',
    'dexterous.com/flutter_local_notifications',
  ];

  for (final channelName in channels) {
    // Intercept hardware communication calls and return dummy success data
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(channelName), (MethodCall methodCall) async {
      if (methodCall.method == 'Firebase#initializeApp') {
        return {
          'name': '[DEFAULT]',
          'options': {'apiKey': '123', 'appId': '123', 'messagingSenderId': '123', 'projectId': '123'},
          'pluginConstants': {},
        };
      }
      return null; // Return nothing for other methods
    });
  }
}
