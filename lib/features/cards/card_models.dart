import '../../core/api/api_contract.dart';

/// The machine has six folders, numbered 1 to 6.
const int folderCount = 6;

/// How many copies of a card are in one folder.
class CardFolderEntry {
  const CardFolderEntry({required this.folder, required this.quantity});

  /// Folder number, from 1 to [folderCount].
  final int folder;
  final int quantity;
}

/// A card (by name) and every folder it is in.
class FolderedCard {
  const FolderedCard({
    required this.id,
    required this.name,
    required this.folders,
  });

  final String id;
  final String name;

  /// Sorted by folder number. A card can be in several folders.
  final List<CardFolderEntry> folders;

  /// Reads one card from the server response. Folder entries outside 1..6 (or
  /// with a quantity below 1) are ignored.
  factory FolderedCard.fromJson(Map<String, dynamic> json) {
    final entries = <CardFolderEntry>[];
    final rawFolders = json[ApiFields.cardFolders] as List<dynamic>? ?? const [];
    for (final raw in rawFolders) {
      final map = raw as Map<String, dynamic>;
      final folder = (map[ApiFields.folderNumber] as num).toInt();
      final quantity = (map[ApiFields.folderQuantity] as num? ?? 1).toInt();
      if (folder >= 1 && folder <= folderCount && quantity >= 1) {
        entries.add(CardFolderEntry(folder: folder, quantity: quantity));
      }
    }
    entries.sort((a, b) => a.folder.compareTo(b.folder));
    return FolderedCard(
      id: json[ApiFields.cardId].toString(),
      name: json[ApiFields.cardName] as String,
      folders: List.unmodifiable(entries),
    );
  }
}

/// One page of results. [total] is the number of cards matching the search,
/// not just the ones in this page.
class CardsPage {
  const CardsPage({required this.items, required this.total});

  final List<FolderedCard> items;
  final int total;

  factory CardsPage.fromJson(Map<String, dynamic> json) {
    final items = (json[ApiFields.pageItems] as List<dynamic>)
        .map((e) => FolderedCard.fromJson(e as Map<String, dynamic>))
        .toList();
    return CardsPage(
      items: items,
      total: (json[ApiFields.pageTotal] as num?)?.toInt() ?? items.length,
    );
  }
}

enum CardsFailure { unauthorized, serverUnreachable, serverError }

class CardsException implements Exception {
  const CardsException(this.failure);

  final CardsFailure failure;

  @override
  String toString() => 'CardsException($failure)';
}
