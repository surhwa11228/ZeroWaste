class User {
  final String email;
  final String password;
  final String name;
  final String phoneNumber;
  final String verificationCode;
  final String region;
  final String birthDate;

  User({
    required this.email,
    required this.password,
    required this.name,
    required this.phoneNumber,
    required this.verificationCode,
    required this.region,
    required this.birthDate,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'name': name,
    'phoneNumber': phoneNumber,
    'verificationCode': verificationCode,
    'region': region,
    'birthDate': birthDate,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    email: json['email'],
    password: json['password'],
    name: json['name'],
    phoneNumber: json['phoneNumber'],
    verificationCode: json['verificationCode'],
    region: json['region'],
    birthDate: json['birthDate'],
  );
}
