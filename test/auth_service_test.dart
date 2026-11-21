import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    auth = AuthService();
    await auth.load();
  });

  group('validation', () {
    test('email validation', () {
      expect(AuthService.validateEmail(''), isNotNull);
      expect(AuthService.validateEmail('not-an-email'), isNotNull);
      expect(AuthService.validateEmail('mara@studio.example'), isNull);
    });

    test('password validation', () {
      expect(AuthService.validatePassword('short'), isNotNull);
      expect(AuthService.validatePassword('long enough'), isNull);
    });
  });

  group('signup + verify + sign in', () {
    test('create generates a 6-digit demo code and does not sign in', () async {
      await auth.createAccount(
        name: 'Mara',
        email: 'mara@studio.example',
        password: 'correct horse',
      );
      expect(auth.signedIn, isFalse);
      expect(auth.pendingEmail, 'mara@studio.example');
      expect(auth.pendingCode, isNotNull);
      expect(auth.pendingCode!.length, 6);
      expect(int.tryParse(auth.pendingCode!), isNotNull);
    });

    test('wrong code is rejected, right code signs in', () async {
      await auth.createAccount(
        name: 'Mara',
        email: 'mara@studio.example',
        password: 'correct horse',
      );
      final code = auth.pendingCode!;
      final wrongCode = code == '000000' ? '000001' : '000000';
      expect(
        () => auth.verify(wrongCode),
        throwsA(isA<AuthException>()),
      );
      final account = await auth.verify(code);
      expect(account.email, 'mara@studio.example');
      expect(account.verified, isTrue);
      expect(auth.signedIn, isTrue);
      expect(auth.displayName, 'Mara');
    });

    test('duplicate email is rejected', () async {
      await auth.createAccount(
        name: 'Mara',
        email: 'mara@studio.example',
        password: 'correct horse',
      );
      expect(
        () => auth.createAccount(
          name: 'Mara 2',
          email: 'mara@studio.example',
          password: 'another password',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('sign in checks the password', () async {
      await auth.createAccount(
        name: 'Mara',
        email: 'mara@studio.example',
        password: 'correct horse',
      );
      await auth.verify(auth.pendingCode!);
      await auth.signOut();
      expect(auth.signedIn, isFalse);

      expect(
        () => auth.signIn(
          email: 'mara@studio.example',
          password: 'wrong password',
        ),
        throwsA(isA<AuthException>()),
      );
      final account = await auth.signIn(
        email: 'mara@studio.example',
        password: 'correct horse',
      );
      expect(account.name, 'Mara');
    });

    test('unknown email cannot sign in', () async {
      expect(
        () => auth.signIn(
          email: 'nobody@studio.example',
          password: 'whatever123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('session persists across instances', () async {
      await auth.createAccount(
        name: 'Mara',
        email: 'mara@studio.example',
        password: 'correct horse',
      );
      await auth.verify(auth.pendingCode!);

      final second = AuthService();
      await second.load();
      expect(second.signedIn, isTrue);
      expect(second.displayEmail, 'mara@studio.example');
    });

    test('guest mode is separate from signing in', () async {
      await auth.continueAsGuest();
      expect(auth.isGuest, isTrue);
      expect(auth.signedIn, isFalse);
      expect(auth.displayName, 'Guest');
    });

    test('delete removes the account and the session', () async {
      await auth.createAccount(
        name: 'Mara',
        email: 'mara@studio.example',
        password: 'correct horse',
      );
      await auth.verify(auth.pendingCode!);
      await auth.deleteCurrentAccount();
      expect(auth.signedIn, isFalse);
      expect(
        () => auth.signIn(
          email: 'mara@studio.example',
          password: 'correct horse',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
