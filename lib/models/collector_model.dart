class CollectorModel {
  final String id;
  final String name;
  final String username;
  final String phone;
  final String address;

  CollectorModel({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    required this.address,
  });

  factory CollectorModel.fromMap(
      String id, Map<String, dynamic> data) {
    return CollectorModel(
      id: id,
      name: data['name'],
      username: data['username'],
      phone: data['phone'],
      address: data['address'],
    );
  }
}
