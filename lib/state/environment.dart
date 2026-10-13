import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeschooling/core/api_client.dart';
import 'package:homeschooling/core/auth_tokens.dart';
import 'package:homeschooling/core/config.dart';
import 'package:homeschooling/core/device_id.dart';
import 'package:homeschooling/core/elevation.dart';
import 'package:homeschooling/core/pending_queue.dart';
import 'package:homeschooling/core/prefs_storage.dart';
import 'package:homeschooling/core/secure_store.dart';
import 'package:homeschooling/data/auth_repository.dart';
import 'package:homeschooling/data/catalogue_repository.dart';
import 'package:homeschooling/data/children_repository.dart';
import 'package:homeschooling/data/config_repository.dart';
import 'package:homeschooling/data/curriculum_repository.dart';
import 'package:homeschooling/data/family_repository.dart';
import 'package:homeschooling/data/pin_repository.dart';
import 'package:homeschooling/data/planning_repository.dart';
import 'package:homeschooling/data/progress_repository.dart';
import 'package:homeschooling/data/session_repository.dart';
import 'package:homeschooling/data/textbook_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything built once at app start and handed down through Riverpod. Assembling this by hand (rather than
/// letting every repository provider build its own dependencies) keeps the wiring in one place and lets tests
/// construct a fake [AppEnvironment] without touching plugins (secure storage, shared_preferences).
class AppEnvironment {
  /// Public on purpose: tests build one directly with fake/mock repositories (mocktail) and an in-memory
  /// [SecureKeyValue]/[KeyValueStorage], instead of going through [bootstrap] (which touches real plugins).
  AppEnvironment({
    required this.secureStore,
    required this.tokenManager,
    required this.pendingQueue,
    required this.elevationCache,
    required this.authRepository,
    required this.familyRepository,
    required this.childrenRepository,
    required this.catalogueRepository,
    required this.curriculumRepository,
    required this.planningRepository,
    required this.progressRepository,
    required this.pinRepository,
    required this.configRepository,
    required this.sessionRepository,
    required this.textbookRepository,
  });

  final SecureKeyValue secureStore;
  final TokenManager tokenManager;
  final PendingQueue pendingQueue;
  final ElevationCache elevationCache;
  final AuthRepository authRepository;
  final FamilyRepository familyRepository;
  final ChildrenRepository childrenRepository;
  final CatalogueRepository catalogueRepository;
  final CurriculumRepository curriculumRepository;
  final PlanningRepository planningRepository;
  final ProgressRepository progressRepository;
  final PinRepository pinRepository;
  final ConfigRepository configRepository;
  final SessionRepository sessionRepository;
  final TextbookRepository textbookRepository;

  Future<String> get deviceId => getOrCreateDeviceId(secureStore);

  void Function()? _sessionExpiredHandler;

  /// Called once by the root widget so a rejected refresh token can drive the app back to the login screen.
  void setSessionExpiredHandler(void Function() handler) => _sessionExpiredHandler = handler;

  void _notifySessionExpired() => _sessionExpiredHandler?.call();

  /// Builds the real environment. Call once, before `runApp`.
  static Future<AppEnvironment> bootstrap() async {
    final SecureKeyValue secureStore = FlutterSecureKeyValue();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final PrefsStorage prefsStorage = PrefsStorage(prefs);

    // authRepository/childrenRepository are assigned below, but TokenManager needs closures over them now:
    // the closures are only invoked later (on a 401), by which time both are set. This breaks what would
    // otherwise be a circular dependency (ApiClient needs TokenManager; TokenManager needs these repositories;
    // these repositories need an authed ApiClient).
    late final AuthRepository authRepository;
    late final ChildrenRepository childrenRepository;

    late final AppEnvironment env;
    final TokenManager tokenManager = TokenManager(
      store: secureStore,
      refreshCall: (String refreshToken) => authRepository.refresh(refreshToken),
      reopenChildCall: (String childId) => childrenRepository.openChildSession(childId),
      onSessionExpired: () => env._notifySessionExpired(),
    );
    await tokenManager.load();

    final ApiClient plainApi = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    final ApiClient authedApi = ApiClient(baseUrl: AppConfig.apiBaseUrl, tokens: tokenManager);

    authRepository = AuthRepository(plain: plainApi, authed: authedApi);
    childrenRepository = ChildrenRepository(api: authedApi, deviceId: () => getOrCreateDeviceId(secureStore));

    final PendingQueue pendingQueue = PendingQueue(storage: prefsStorage);
    pendingQueue.load();

    env = AppEnvironment(
      secureStore: secureStore,
      tokenManager: tokenManager,
      pendingQueue: pendingQueue,
      elevationCache: ElevationCache(),
      authRepository: authRepository,
      familyRepository: FamilyRepository(authedApi),
      childrenRepository: childrenRepository,
      catalogueRepository: CatalogueRepository(authedApi),
      curriculumRepository: CurriculumRepository(authedApi),
      planningRepository: PlanningRepository(authedApi),
      progressRepository: ProgressRepository(authedApi),
      pinRepository: PinRepository(authedApi),
      configRepository: ConfigRepository(plainApi),
      sessionRepository: SessionRepository(authedApi),
      textbookRepository: TextbookRepository(authedApi),
    );
    return env;
  }
}

/// Overridden with the real [AppEnvironment] in `main()`. Reading this before the override is a bug.
final Provider<AppEnvironment> environmentProvider = Provider<AppEnvironment>(
  (Ref ref) => throw UnimplementedError('environmentProvider must be overridden in main()'),
);
