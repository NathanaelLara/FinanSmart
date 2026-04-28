import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../shared/models/transaction_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authRepository);

  final AuthRepository _authRepository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<void> restoreSession() async {
    try {
      _currentUser = await _authRepository.restoreSession();
      _errorMessage = null;
      notifyListeners();
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapFirebaseError(error);
      notifyListeners();
    } catch (_) {
      _errorMessage = 'No se pudo restaurar la sesion. Intenta nuevamente.';
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      _currentUser = await _authRepository.signIn(
        email: email,
        password: password,
      );
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapFirebaseError(error);
      return false;
    } catch (_) {
      _errorMessage = 'No fue posible iniciar sesion en este momento.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    _setLoading(true);
    try {
      _currentUser = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapFirebaseError(error);
      return false;
    } catch (_) {
      _errorMessage = 'No fue posible crear la cuenta en este momento.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authRepository.logout();
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  void updatePreferredCurrency(CurrencyType currency) {
    if (_currentUser == null) {
      return;
    }
    _currentUser = _currentUser!.copyWith(preferredCurrency: currency);
    _authRepository.updatePreferredCurrency(currency);
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
        return 'La contrasena ingresada es incorrecta.';
      case 'invalid-credential':
        return 'Las credenciales no son validas o ya no son vigentes.';
      case 'email-already-in-use':
        return 'Ese correo ya esta registrado.';
      case 'invalid-email':
        return 'El correo electronico no es valido.';
      case 'weak-password':
        return 'La contrasena es demasiado debil. Usa al menos 6 caracteres.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Ocurrio un error de autenticacion. Intenta nuevamente.';
    }
  }
}
