// ------------------------------------------------------------------------------
// File: auth_provider.dart
// Purpose: Centralized Identity and Security Session Governance.
// Rationale: Orchestrates the comprehensive authentication lifecycle (SMS/OTP, 
//   backend REST synchronization, and multi-tenant session injection). 
//   Manages reactive user state and cloud media upload pipelines.
// ------------------------------------------------------------------------------
import 'dart:typed_data'; // Infrastructure: Byte manipulation for Web blobs
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:frontend/features/auth/domain/entities/owner.dart'; // Domain: User data model
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart'; // Data: Auth connection engine
import 'package:frontend/core/error/exceptions.dart'; // Infrastructure: Custom error handling
import 'package:frontend/core/network/api_client.dart'; // Infrastructure: Network client for header injection
import 'package:frontend/core/services/phone_auth_service.dart'; // Service: Firebase SMS verification bridge
import 'package:image_picker/image_picker.dart'; // Media: Local file selection
import 'package:cloudinary_public/cloudinary_public.dart'; // Cloud: Decentralized image storage API
import 'package:frontend/core/config/cloudinary_config.dart'; // Config: Cloud storage credentials
import 'package:shared_preferences/shared_preferences.dart'; // Logic: Local persistence
import 'dart:convert'; // Utility: JSON serialization

class AuthProvider extends ChangeNotifier {
  // --- Services & Dependencies ---
  final AuthRepositoryImpl _repository = AuthRepositoryImpl(); // Logic: Backend API adapter
  final PhoneAuthService _phoneAuthService = PhoneAuthService(); // Logic: Firebase OTP bridge
  
  // --- Persistence Registry ---
  static const String _storageKeyOwner = 'current_owner_data'; // Registry: Key for local disk

  // --- Reactive State ---
  Owner? _currentOwner; // Identity: The currently authenticated shop manager
  bool _isLoading = false; // Status: Global busy-flag for blocking UI during network events
  String? _error; // User Feedback: Human-readable error message for SnackBars
  String? _technicalDetails; // Diagnostics: Raw technical logs (e.g., HTTP 401) for the diagnostic dialog
  bool _isLoggedIn = false; // Auth State: Quick-flag for conditional routing (Login vs Home)

  // --- Phone Auth (Firebase) Session State ---
  String? _verificationId; // Session: Firebase-generated token for SMS verification
  int? _resendToken; // Token: Used to throttle and link OTP resend attempts

  // --- Public Getters ---
  Owner? get currentOwner => _currentOwner;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get technicalDetails => _technicalDetails;
  bool get isLoggedIn => _isLoggedIn;
  String? get verificationId => _verificationId;

  /*
   * Logic: Outbound SMS Verification.
   * Rationale: Triggers the Firebase phone verification flow to prove the user's identity.
   */
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String code) onVerificationCompleted,
    required Function(String error) onVerificationFailed,
    required VoidCallback onCodeSent,
  }) async {
    _isLoading = true; // Strategy: Block UI interaction during the handshake
    _error = null;
    notifyListeners();

    try {
      debugPrint('📱 [OTP] Initiating SMS verification for: $phoneNumber');
      await _phoneAuthService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          debugPrint('✅ [OTP] Code sent successfully. Verification ID received.');
          _verificationId = verificationId; // Persistence: Store the ID for the 'verify' step
          _resendToken = resendToken; // Recovery: Store for 'resend' attempts
          _isLoading = false;
          notifyListeners();
          onCodeSent(); // Navigation: Tell UI to show the OTP entry field
        },
        onVerificationFailed: (e) {
          debugPrint('❌ [OTP] Verification FAILED: code=${e.code}, message=${e.message}');
          debugPrint('❌ [OTP] Full error: $e');

          // Logic: Map technical Firebase restrictions to actionable user instructions.
          if (e.code == 'billing-not-enabled') {
            _error = 'SMS service restricted.';
          } else {
            _error = e.message ?? 'Verification failed';
          }

          _isLoading = false;
          notifyListeners();
          onVerificationFailed(_error!); // Notify: UI should show an alert
        },
        onVerificationCompleted: (credential) async {
          debugPrint('✅ [OTP] Auto-verification completed.');
          // Automatic: Triggered if Android detects the SMS code automatically.
          if (credential.smsCode != null) {
            onVerificationCompleted(credential.smsCode!);
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          debugPrint('⏰ [OTP] Auto-retrieval timeout. Manual entry required.');
          _verificationId = verificationId; // Persistence: Ensure we can still verify manually after timeout
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('❌ [OTP] Exception during sendOtp: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      onVerificationFailed(_error!);
    }
  }

  /*
   * Logic: Throttled OTP Resend.
   * Rationale: Uses the 'forceResendingToken' to link the new SMS request to the previous session.
   */
  Future<void> resendOtp({
    required String phoneNumber,
    required Function(String) onVerificationFailed,
    required VoidCallback onCodeSent,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _phoneAuthService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onVerificationCompleted: (credential) async {
          _isLoading = false;
          notifyListeners();
        },
        onVerificationFailed: (e) {
          _isLoading = false;
          _error = e.message ?? 'Verification failed';
          notifyListeners();
          onVerificationFailed(_error!);
        },
        onCodeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isLoading = false;
          notifyListeners();
          onCodeSent();
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
        forceResendingToken: _resendToken, // Optimization: Reduces SMS latency and links attempts
      );
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      onVerificationFailed(_error!);
    }
  }

  /*
   * Logic: Inbound SMS Validation.
   * Rationale: Confirms that the code provided by the user matches the Firebase verification session.
   */
  Future<bool> verifyOtp(String smsCode) async {
    if (_verificationId == null) return false; // Guard: No active session
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _phoneAuthService.getCredential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      
      // Strategy: Sign in locally to Firebase to validate the token.
      await _phoneAuthService.signInWithCredential(credential);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Invalid OTP code. Please try again.'; // User UX: Simple, actionable error
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Backend-Driven OTP Request.
   * Rationale: Triggers the Node.js backend to generate a PIN and send via Email or Preview in Terminal.
   */
  Future<void> requestBackendOtp({
    required String target,
    required String method,
    required VoidCallback onCodeSent,
    required Function(String error) onFailed,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🛡️ [BACKEND OTP] Requesting code for: $target via $method');
      final response = await ApiClient.post('/otp/request', {
        'target': target,
        'method': method,
      });

      if (response['success'] == true) {
        _isLoading = false;
        notifyListeners();
        onCodeSent();
      } else {
        throw Exception(response['message'] ?? 'Failed to request code');
      }
    } catch (e) {
      debugPrint('❌ [BACKEND OTP] Error: $e');
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      onFailed(_error!);
    }
  }

  /*
   * Logic: Backend-Driven OTP Verification.
   * Rationale: Validates the PIN against the backend session.
   */
  Future<bool> verifyBackendOtp({
    required String target,
    required String pin,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🛡️ [BACKEND OTP] Verifying code for: $target');
      final response = await ApiClient.post('/otp/verify', {
        'target': target,
        'pin': pin,
      });

      if (response['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Invalid code';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ [BACKEND OTP] Verification Error: $e');
      _error = e.toString().contains('401') ? 'Invalid or expired code.' : 'Verification failed.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Session Initialization.
   * Rationale: Authenticates with the Node.js backend and injects the Owner ID into the network layer.
   */
  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Logic: Repository returns an Owner entity and since we updated the backend return
      // structure, the 'token' field is now hydrated automatically via Owner.fromJson.
      _currentOwner = await _repository.login(identifier, password);
      
      if (_currentOwner != null) {
        // Trace: Update global singleton to ensure all future API calls are correctly scoped.
        ApiClient.ownerId = _currentOwner!.id;
        ApiClient.ownerName = _currentOwner!.name;
        await ApiClient.setToken(_currentOwner!.token); // Security: Inject the signed session token

        // Persistence: Commit the owner data to local disk to enable auto-login.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKeyOwner, jsonEncode(_currentOwner!.toJson()));
      }
      
      _isLoggedIn = true; // State: Unlock protected routes
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Transparency: Map technical exceptions to human messages and raw logs.
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Multi-tenant Account Creation.
   * Rationale: Registers a new business owner and immediately initializes their session.
   */
  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentOwner = await _repository.register(data);
      
      if (_currentOwner != null) {
        ApiClient.ownerId = _currentOwner!.id;
        ApiClient.ownerName = _currentOwner!.name;
        await ApiClient.setToken(_currentOwner!.token); // Security: Inject the signed session token

        // Persistence: Commit the owner data to local disk to enable auto-login.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKeyOwner, jsonEncode(_currentOwner!.toJson()));
      }
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Identity Availability Check.
   * Rationale: Proactively checks if unique fields (Email/Phone) are already registered before OTP is sent.
   */
  Future<bool> checkAvailability({String? phone, String? email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final Map<String, dynamic> body = {};
      if (phone != null) body['phone'] = phone;
      if (email != null) body['email'] = email;

      final response = await ApiClient.post('/auth/check-availability', body);

      // Validation: Check business-rule status returned by the backend.
      if (response['success'] == true && response['available'] == false) {
        _error = response['message']; // e.g. "Account already exists"
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Session Termination.
   * Rationale: Wipes all sensitive credentials from memory, clears disk storage, and resets the route guard.
   */
  Future<void> logout() async {
    _currentOwner = null;
    _isLoggedIn = false;
    _verificationId = null; // Security: Clear active SMS session ID
    _resendToken = null; // Security: Clear resend link token
    
    // Safety: Clear global singleton identifiers to prevent cross-account API leakage.
    ApiClient.ownerId = null;
    ApiClient.ownerName = null;
    await ApiClient.setToken(null); // Security: Wipe active session token

    // Persistence: Purge the saved session from disk.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKeyOwner);
    } catch (e) {
      debugPrint('❌ [AuthProvider] Cleanup error: $e');
    }

    notifyListeners();
  }

  /**
   * Logic: Foundation Restoration.
   * Rationale: Attempts to recover a previously saved session from local storage 
   *   to enable immediate auto-login without user interaction.
   */
  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ownerData = prefs.getString(_storageKeyOwner);

      if (ownerData != null && ownerData.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(ownerData);
        _currentOwner = Owner.fromJson(data);
        
        if (_currentOwner != null) {
          // Re-inject the session context into the network layer.
          ApiClient.ownerId = _currentOwner!.id;
          ApiClient.ownerName = _currentOwner!.name;
          await ApiClient.setToken(_currentOwner!.token); // Security: Restore cryptographic session
          _isLoggedIn = true;
        }
      }
    } catch (e) {
      debugPrint('❌ [AuthProvider] Session restoration failed: $e');
      // Strategy: Silently fail and force the user to re-login if data is corrupt.
    }
    notifyListeners();
  }

  /*
   * Logic: Cloud-to-Local Synchronization.
   * Rationale: Refreshes the local session state with the latest data from the backend.
   *   Useful if an admin has modified the user's profile or status.
   */
  Future<void> refreshProfile() async {
    if (_currentOwner == null) return;
    
    try {
      // Step: Fetch the latest owner data from the repository.
      final freshOwner = await _repository.getProfile(_currentOwner!.id);
      
      if (freshOwner != null) {
        // Trace: Update the in-memory identity.
        _currentOwner = freshOwner;
        
        // Persistence: Update the local disk cache with the fresh data.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKeyOwner, jsonEncode(_currentOwner!.toJson()));
        
        notifyListeners();
      }
    } catch (e) {
      // Silence: We don't want to block the UI with a popup if a background refresh fails.
      debugPrint('❌ [AuthProvider] Profile refresh failed: $e');
    }
  }

  /*
   * Logic: Profile Metadata Update.
   * Rationale: Handles generic profile modifications (Name, ShopName, etc.) via the PUT endpoint.
   */
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_currentOwner == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentOwner = await _repository.updateProfile(_currentOwner!.id, data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Security Credential Rotation.
   * Rationale: Synchronizes the password change flow, requiring server-side 'Old Password' verification.
   */
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentOwner == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.changePassword(
        _currentOwner!.id,
        oldPassword,
        newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: External Password Reset.
   * Rationale: Overwrites the password for a specific identifier (Email/Phone) without requiring a session.
   */
  Future<bool> resetPassword(String identifier, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.resetPassword(identifier, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /*
   * Logic: Binary Media Persistence.
   * Rationale: Uploads a local image file to Cloudinary.
   */
  Future<String?> _uploadImage(XFile imageFile) async {
    if (CloudinaryConfig.cloudName.isEmpty || CloudinaryConfig.uploadPreset.isEmpty) {
      debugPrint('Cloudinary config Error: Missing keys.');
      return null;
    }

    try {
      final cloudinary = CloudinaryPublic(
        CloudinaryConfig.cloudName,
        CloudinaryConfig.uploadPreset,
        cache: false,
      );

      final bytes = await imageFile.readAsBytes();

      // Transmission: Send to Cloudinary. For Web blobs, ensure a valid identifier.
      String fileName = imageFile.name;
      if (fileName.isEmpty || fileName == 'blob' || !fileName.contains('.')) {
        fileName = 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      final CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          ByteData.view(bytes.buffer),
          identifier: fileName,
          folder: 'profile_pics',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      debugPrint('❌ Cloudinary Upload Error: $e');
      _error = 'Storage upload failed: $e';
      return null;
    }
  }

  /*
   * Logic: Atomic Profile Image Update.
   * Rationale: Chains 'Cloud Upload' and 'DB Update' together to ensure visual consistency.
   */
  Future<bool> updateProfilePicture(XFile imageFile) async {
    if (_currentOwner == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step A: Push to Cloud
      final url = await _uploadImage(imageFile);
      if (url == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Step B: Link to identity record in MongoDB.
      return await updateProfile({'profilePic': url});
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Profile Image Revocation.
   * Rationale: Resets the profile image link to null/empty in the backend.
   */
  Future<bool> removeProfilePicture() async {
    if (_currentOwner == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step: Reset the profile picture link to an empty string in the cloud DB.
      final success = await updateProfile({'profilePic': ''});
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Permanent Account Purge.
   * Rationale: Executes a DELETE request for the user's primary ID.
   */
  Future<bool> deleteAccount() async {
    if (_currentOwner == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.delete('/auth/profile/${_currentOwner!.id}');
      
      if (response['success'] == true) {
        logout(); // Immediate Action: Wipe local logs on successful cloud purge.
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['error'] ?? 'Profile purge failed.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Trace: Handle specific security rejections (403 Forbidden).
      _error = e.toString().contains('403') 
          ? 'Permission denied (403)' 
          : 'Purge failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /*
   * UI Utility: Error Reset.
   * Rationale: Clears stale warnings from the UI before a new user action.
   */
  void clearError() {
    _error = null;
    notifyListeners();
  }
}


