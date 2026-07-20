class ApiConstants {
  // Android emülatör için 10.0.2.2, gerçek cihaz için bilgisayarının IP adresi kullanılır
  static const String baseUrl = "http://10.0.2.2:8000";

  static const String register = "$baseUrl/auth/register";
  static const String login = "$baseUrl/auth/login";
  static const String transactions = "$baseUrl/transactions/";
  static const String portfolioSummary = "$baseUrl/transactions/summary/portfolio";
}