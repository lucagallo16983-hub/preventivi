import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class Lavorazione {
  final String id;
  final String tipo;
  final double prezzo;
  final String? dicitura;

  const Lavorazione({
    this.id = '',
    required this.tipo,
    required this.prezzo,
    this.dicitura,
  });

  Map<String, dynamic> toMap() => {
    'tipo': tipo,
    'prezzo': prezzo,
    if (dicitura != null && dicitura!.isNotEmpty) 'dicitura': dicitura,
  };

  static Lavorazione fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final num? p = d['prezzo'] as num?;
    return Lavorazione(
      id: doc.id,
      tipo: (d['tipo'] ?? '') as String,
      prezzo: (p ?? 0).toDouble(),
      dicitura: (d['dicitura'] as String?)?.trim(),
    );
  }
}

class LavorazioniStore {
  LavorazioniStore._() {
    _bind();
  }
  static final LavorazioniStore instance = LavorazioniStore._();

  final _db = FirebaseFirestore.instance;
  final List<Lavorazione> items = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  void _bind() {
    _sub?.cancel();
    _sub = _db.collection('lavorazioni').orderBy('tipo').snapshots().listen((
      qs,
    ) {
      items
        ..clear()
        ..addAll(qs.docs.map(Lavorazione.fromDoc));
    });
  }

  Future<String> add(Lavorazione l) async {
    final ref = await _db.collection('lavorazioni').add(l.toMap());
    return ref.id;
  }

  /// update(index, Lavorazione) **oppure** update(id, Lavorazione)
  Future<void> update(dynamic a, [Lavorazione? l]) async {
    if (a is int && l != null) {
      if (a < 0 || a >= items.length) return;
      final id = items[a].id;
      if (id.isEmpty) return;
      await _db.collection('lavorazioni').doc(id).update(l.toMap());
      return;
    }
    if (a is String && l != null) {
      await _db.collection('lavorazioni').doc(a).update(l.toMap());
      return;
    }
    throw ArgumentError(
      'update(index, Lavorazione) oppure update(id, Lavorazione)',
    );
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= items.length) return;
    final id = items[index].id;
    if (id.isEmpty) return;
    await _db.collection('lavorazioni').doc(id).delete();
  }

  Future<void> delete(String id) async {
    await _db.collection('lavorazioni').doc(id).delete();
  }

  void dispose() {
    _sub?.cancel();
  }
}
