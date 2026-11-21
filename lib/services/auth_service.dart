import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

/// A local account. v0.1 stores accounts on-device only — there is no
/// backend yet, so the password hash never leaves the device and the
/// verification code is a local demo code (shown on the verify screen,
/// clearly labelled). The sync sketch (server/) is where real auth lands.
class Account {
  /// Creates an [Account].
  const Account({
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
    this.verified = false,
  });

  /// The name.
  final String name;
  /// The email.
  final String email;
  /// The SHA-256 hash of the password.
  final String passwordHash;
  /// The salt for the password hash.
  final String salt;
  /// When this account was created.
  final DateTime createdAt;
  /// Whether the account is verified.
  final bool verified;

  /// Returns a copy of this with the given values replaced.
  Account copyWith({bool? verified}) => Account(
        name: name,
        email: email,
        passwordHash: passwordHash,
        salt: salt,
        createdAt: createdAt,
        verified: verified ?? this.verified,
      );

  /// Converts this to JSON.
  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'salt': salt,
        'createdAt': createdAt.toIso8601String(),
        'verified': verified,
      };

  /// Creates an [Account] from JSON.
  factory Account.fromJson(Map<String, dynamic> json) => Account(
        name: json['name'] as String,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String,
        salt: json['salt'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        verified: json['verified'] as bool? ?? false,
      );
}

/// Session modes: no session yet, browsing the demo as a guest, or signed
/// in as an account.
enum SessionMode {
  /// No session yet.
  none,

  /// Browsing the demo as a guest.
  guest,

  /// Signed in as an account.
  signedIn,
}

/// Local account store + session. Throws [AuthException] with a human
/// message on every failure path; the UI shows the message as-is.
class AuthException implements Exception {
  /// Creates an [AuthException].
  const AuthException(this.message);

  /// The message.
  final String message;

  @override
  String toString() => message;
}

/// Local account store and session.
class AuthService {
  /// Creates an [AuthService].
  AuthService({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  List<Account> _accounts = [];
  Account? _current;
  SessionMode _mode = SessionMode.none;

  /// The 6-digit code generated for the pending verification, if any.
  /// v0.1 demo: no email is sent; the verify screen shows this code with a
  /// demo label so the flow is completable.
  String? pendingCode;
  String? _pendingEmail;

  bool _loaded = false;

  /// The signed-in account, if any.
  Account? get currentAccount => _current;
  /// The session mode.
  SessionMode get mode => _mode;
  /// Whether a user is signed in.
  bool get signedIn => _mode == SessionMode.signedIn && _current != null;
  /// Whether the session is a guest session.
  bool get isGuest => _mode == SessionMode.guest;
  /// The name to show in the UI.
  String get displayName =>
      _current?.name ?? (_mode == SessionMode.guest ? 'Guest' : '');
  /// The email to show in the UI.
  String get displayEmail => _current?.email ?? '';

  /// Loads accounts and the saved session. Safe to call twice.
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StoreKeys.auth);
    if (raw != null && raw.isNotEmpty) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        _accounts = (json['accounts'] as List<dynamic>? ?? [])
            .map((e) => Account.fromJson(e as Map<String, dynamic>))
            .toList();
        final sessionEmail = json['sessionEmail'] as String?;
        final guest = json['guest'] as bool? ?? false;
        if (sessionEmail != null) {
          for (final a in _accounts) {
            if (a.email == sessionEmail) _current = a;
          }
          if (_current != null) _mode = SessionMode.signedIn;
        } else if (guest) {
          _mode = SessionMode.guest;
        }
      } on FormatException {
        _accounts = [];
      }
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StoreKeys.auth,
      jsonEncode({
        'accounts': _accounts.map((a) => a.toJson()).toList(),
        'sessionEmail': _current?.email,
        'guest': _mode == SessionMode.guest,
      }),
    );
  }

  /// Validates an email address. Returns an error message or null.
  static String? validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return 'Enter an email address.';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
    if (!ok) return 'That email address does not look right.';
    return null;
  }

  /// Validates a password (8+ characters). Returns an error or null.
  static String? validatePassword(String password) {
    if (password.length < 8) return 'Use 8 characters or more.';
    return null;
  }

  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  String _newSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _newCode() =>
      List<int>.generate(6, (_) => _random.nextInt(10)).join();

  /// Creates an account and starts verification. The account is NOT signed
  /// in until [verify] succeeds.
  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedName.isEmpty) {
      throw const AuthException('Enter your name.');
    }
    final emailError = validateEmail(trimmedEmail);
    if (emailError != null) throw AuthException(emailError);
    final passwordError = validatePassword(password);
    if (passwordError != null) throw AuthException(passwordError);
    if (_accounts.any((a) => a.email == trimmedEmail)) {
      throw const AuthException(
        'An account with that email already exists — sign in instead.',
      );
    }
    final salt = _newSalt();
    final account = Account(
      name: trimmedName,
      email: trimmedEmail,
      passwordHash: _hash(salt, password),
      salt: salt,
      createdAt: DateTime.now(),
    );
    _accounts.add(account);
    _pendingEmail = trimmedEmail;
    pendingCode = _newCode();
    await _persist();
  }

  /// The email awaiting verification (null when no signup is pending).
  String? get pendingEmail => _pendingEmail;

  /// Generates a fresh verification code for the pending signup.
  Future<void> resendCode() async {
    if (_pendingEmail == null) {
      throw const AuthException('No verification is pending.');
    }
    pendingCode = _newCode();
  }

  /// Verifies the pending signup with [code] and signs in.
  Future<Account> verify(String code) async {
    final email = _pendingEmail;
    if (email == null || pendingCode == null) {
      throw const AuthException('No verification is pending.');
    }
    if (code.trim() != pendingCode) {
      throw const AuthException('That code does not match — try again.');
    }
    final index = _accounts.indexWhere((a) => a.email == email);
    if (index < 0) {
      throw const AuthException('That account is gone — create it again.');
    }
    final verified = _accounts[index].copyWith(verified: true);
    _accounts[index] = verified;
    _current = verified;
    _mode = SessionMode.signedIn;
    _pendingEmail = null;
    pendingCode = null;
    await _persist();
    return verified;
  }

  /// Signs in with email + password.
  Future<Account> signIn({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    Account? found;
    for (final a in _accounts) {
      if (a.email == trimmedEmail) found = a;
    }
    if (found == null) {
      throw const AuthException(
        'No account with that email — create one first.',
      );
    }
    if (_hash(found.salt, password) != found.passwordHash) {
      throw const AuthException('Wrong password — try again.');
    }
    if (!found.verified) {
      // Unverified account (app closed mid-signup): resume verification.
      _pendingEmail = found.email;
      pendingCode = _newCode();
      throw const AuthException(
        'That account is not verified yet — check your code.',
      );
    }
    _current = found;
    _mode = SessionMode.signedIn;
    await _persist();
    return found;
  }

  /// Browses the demo as a guest (view-only; no account is created).
  Future<void> continueAsGuest() async {
    _current = null;
    _mode = SessionMode.guest;
    await _persist();
  }

  /// Signs out. Local data stays on the device; the session is cleared.
  Future<void> signOut() async {
    _current = null;
    _mode = SessionMode.none;
    await _persist();
  }

  /// Deletes the signed-in account and its session. The caller removes
  /// the user's own projects; demo projects stay.
  Future<void> deleteCurrentAccount() async {
    final current = _current;
    if (current == null) {
      throw const AuthException('No account is signed in.');
    }
    _accounts.removeWhere((a) => a.email == current.email);
    _current = null;
    _mode = SessionMode.none;
    await _persist();
  }
}
