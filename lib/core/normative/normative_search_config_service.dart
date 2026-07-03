import 'package:cloud_firestore/cloud_firestore.dart';

abstract final class NormativeSearchConfigService {
  static const docId = 'normative_search';

  static const defaultSystemPrompt =
      'Sei un assistente specializzato in attività stragiudiziale e recupero '
      'crediti in Italia. Rispondi solo a domande in ambito normativo e '
      'operativo su questi temi.\n\n'
      'Regole:\n'
      '- Usa linguaggio chiaro e professionale, adatto a operatori del credito.\n'
      '- Cita norme, articoli o principi solo quando sei ragionevolmente sicuro; '
      'se non sei sicuro, dillo esplicitamente.\n'
      '- Non inventare testi di legge, sentenze o circolari.\n'
      '- Non dare consulenza legale personalizzata: ricorda che le risposte '
      'sono informative.\n'
      '- Se la domanda è fuori tema (non riguarda recupero crediti o attività '
      'stragiudiziale), rifiuta gentilmente e riporta l\'utente al perimetro.\n'
      '- Rispondi in italiano, in modo sintetico ma completo.';

  static Stream<String> watchStoredPrompt() {
    return FirebaseFirestore.instance
        .collection('settings')
        .doc(docId)
        .snapshots()
        .map((snap) => (snap.data()?['prompt'] ?? '').toString());
  }
}
