class ValidationHelper {
  
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email é obrigatório';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Digite um email válido';
    }
    
    return null;
  }
  
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Senha é obrigatória';
    }
    
    if (password.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    
    if (password.length > 128) {
      return 'Senha muito longa';
    }
    
    return null;
  }
  
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Nome é obrigatório';
    }
    
    if (name.length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    
    if (name.length > 50) {
      return 'Nome muito longo';
    }
    
    final nameRegex = RegExp(r'^[a-zA-ZÀ-ÿ\s]+$');
    if (!nameRegex.hasMatch(name)) {
      return 'Nome deve conter apenas letras e espaços';
    }
    
    return null;
  }
  
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    
    if (password != confirmPassword) {
      return 'Senhas não coincidem';
    }
    
    return null;
  }
  
  static bool isValidQRCode(String? qrCode) {
    if (qrCode == null || qrCode.isEmpty) return false;
    
    // Check if it matches expected QR code pattern for the app
    final qrRegex = RegExp(r'^(bacia[1-3]_\d{3}_qr|https://ecoar-beira\.app/marker/.+)$');
    return qrRegex.hasMatch(qrCode);
  }
  
  static bool isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    
    return latitude >= -90 && latitude <= 90 && 
           longitude >= -180 && longitude <= 180;
  }
  
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null; // Phone is optional
    }
    
    // Mozambique phone number format
    final phoneRegex = RegExp(r'^\+?258[0-9]{9}$|^[0-9]{9}$');
    if (!phoneRegex.hasMatch(phone.replaceAll(' ', ''))) {
      return 'Número de telefone inválido';
    }
    
    return null;
  }
}