import '../repositories/chat_repository.dart';
import '../repositories/marketplace_repository.dart';
import '../services/auth_service.dart';
import '../services/backend_api_service.dart';
import '../services/device_service.dart';
import '../services/presence_service.dart';
import '../services/storage_service.dart';

class ChatCartServices {
  ChatCartServices._();
  static final instance = ChatCartServices._();

  final auth = AuthService();
  final chat = ChatRepository();
  final marketplace = MarketplaceRepository();
  final storage = StorageService();
  final presence = PresenceService();
  final typing = TypingService();
  final backend = BackendApiService();
  late final devices = DeviceService(backend: backend);
}
