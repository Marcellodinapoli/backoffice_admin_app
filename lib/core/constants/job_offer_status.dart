/// Etichette UI per gli stati delle offerte di lavoro (valori Firestore in inglese).
abstract final class JobOfferStatus {
  static String label(String status) {
    switch (status) {
      case 'pending':
        return 'In attesa';
      case 'approved':
        return 'Approvata';
      case 'blocked':
        return 'Bloccata';
      case 'expired':
        return 'Scaduta';
      case 'rejected':
        return 'Rifiutata';
      default:
        return status;
    }
  }
}
