/// How a guardian responded to an SOS.
enum AckResponse {
  onMyWay('On my way'),
  callingPolice('Calling police'),
  cantHelp("Can't help right now");

  const AckResponse(this.label);
  final String label;
}

/// A guardian's acknowledgment of an SOS event — visible to the person in
/// distress and to the other guardians so help isn't duplicated or dropped.
class Ack {
  final String id;
  final String guardianName;
  final AckResponse response;
  final DateTime at;

  const Ack({
    required this.id,
    required this.guardianName,
    required this.response,
    required this.at,
  });

  Map<String, dynamic> toMap() => {
        'guardianName': guardianName,
        'response': response.name,
        'at': at.toIso8601String(),
      };

  factory Ack.fromMap(String id, Map<String, dynamic> map) {
    return Ack(
      id: id,
      guardianName: map['guardianName'] as String? ?? 'A guardian',
      response: AckResponse.values.firstWhere(
        (r) => r.name == map['response'],
        orElse: () => AckResponse.onMyWay,
      ),
      at: DateTime.tryParse(map['at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
