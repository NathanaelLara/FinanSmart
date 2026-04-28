class AppValidators {
  const AppValidators._();

  static String? requiredField(String? value, {String fieldName = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredField(value, fieldName: 'Correo');
    if (requiredError != null) {
      return requiredError;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Ingresa un correo valido';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = requiredField(value, fieldName: 'Contrasena');
    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < 6) {
      return 'Debe tener al menos 6 caracteres';
    }
    return null;
  }
}
