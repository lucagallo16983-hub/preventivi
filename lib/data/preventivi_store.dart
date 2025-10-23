import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lavorazioni_store.dart';

class RigaPreventivo {
  final Lavorazione lavorazione; // snapshot tipo+prezzo
  final double mq;

  const RigaPreventivo({required this.lavorazione, required this.mq});

  double get subtotale => lavorazione.prezzo * mq;

  Map<String, dynamic> toMap() => {
    'tipo': lavorazione.tipo,
    'prezzo': lavorazione.prezzo,
    'mq': mq,
  };

  static RigaPreventivo fromMap(Map<String, dynamic> map) {
    final num? prezzoNum = map['prezzo'] as num?;
    final num? mqNum = map['mq'] as num?;
    return RigaPreventivo(
      lavorazione: Lavorazione(
        id: '',
        tipo: (map['tipo'] ?? '') as String,
        prezzo: (prezzoNum ?? 0).toDouble(),
      ),
      mq: (mqNum ?? 0).toDouble(),
    );
  }
}

class Preventivo {
  final String id; // opzionale per compatibilità
  final String titolo; // <-- NUOVO: nome/titolo del preventivo
  final List<RigaPreventivo> righe;
  final DateTime createdAt;

  const Preventivo({
    this.id = '', // default
    this.titolo = '', // <-- default
    required this.righe,
    required this.createdAt,
  });

  double get totale => righe.fold<double>(0, (p, r) => p + r.subtotale);

  Map<String, dynamic> toMap() => {
    'createdAt': Timestamp.fromDate(createdAt),
    'righe': righe.map((r) => r.toMap()).toList(),
    'titolo': titolo, // <-- NUOVO
  };

  static Preventivo fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final Timestamp? ts = data['createdAt'] as Timestamp?;
    final List<dynamic> righeRaw =
        (data['righe'] as List<dynamic>?) ?? const [];
    return Preventivo(
      id: doc.id,
      titolo: (data['titolo'] as String?) ?? '', // <-- NUOVO
      righe: righeRaw
          .whereType<Map<String, dynamic>>()
          .map(RigaPreventivo.fromMap)
          .toList(),
      createdAt: (ts ?? Timestamp.now()).toDate(),
    );
  }
}

class PreventiviStore {
  PreventiviStore._() {
    _bind();
  }
  static final PreventiviStore instance = PreventiviStore._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final List<Preventivo> items = <Preventivo>[];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  void _bind() {
    _sub?.cancel();
    _sub = _db
        .collection('preventivi')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((qs) {
          items
            ..clear()
            ..addAll(qs.docs.map(Preventivo.fromDoc));
        });
  }

  Future<String> add(Preventivo p) async {
    final ref = await _db.collection('preventivi').add(p.toMap());
    return ref.id;
  }

  Future<void> delete(String id) async {
    await _db.collection('preventivi').doc(id).delete();
  }

  void dispose() {
    _sub?.cancel();
  }
}
