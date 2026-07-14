/// A family group. Mirrors the `families/{id}` document shared with the web app.
class Family {
  final String id;
  final String name;
  final String ownerUid;
  final String inviteCode;
  final List<String> memberNames; // tracked people (spending)
  final Map<String, dynamic> members; // uid -> {name,email} (app users)
  final List<String> categories; // custom category list (empty = use defaults)

  Family({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.inviteCode,
    required this.memberNames,
    required this.members,
    this.categories = const [],
  });

  factory Family.fromMap(String id, Map<String, dynamic> m) => Family(
        id: id,
        name: (m['name'] ?? 'Family') as String,
        ownerUid: (m['ownerUid'] ?? '') as String,
        inviteCode: (m['inviteCode'] ?? '') as String,
        memberNames: ((m['memberNames'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        members: (m['members'] as Map?)?.cast<String, dynamic>() ?? {},
        categories: ((m['categories'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}
