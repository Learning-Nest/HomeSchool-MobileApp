import 'package:homeschooling/core/elevation.dart';
import 'package:homeschooling/core/pending_queue.dart';
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
import 'package:homeschooling/state/environment.dart';
import 'package:mocktail/mocktail.dart';

import 'fakes.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFamilyRepository extends Mock implements FamilyRepository {}

class MockChildrenRepository extends Mock implements ChildrenRepository {}

class MockCatalogueRepository extends Mock implements CatalogueRepository {}

class MockCurriculumRepository extends Mock implements CurriculumRepository {}

class MockPlanningRepository extends Mock implements PlanningRepository {}

class MockProgressRepository extends Mock implements ProgressRepository {}

class MockPinRepository extends Mock implements PinRepository {}

class MockConfigRepository extends Mock implements ConfigRepository {}

class MockSessionRepository extends Mock implements SessionRepository {}

class MockTextbookRepository extends Mock implements TextbookRepository {}

/// Everything a test needs to build an [AppEnvironment] with every repository mocked, plus the mocks
/// themselves to stub/verify against.
class TestEnvironment {
  TestEnvironment()
      : auth = MockAuthRepository(),
        family = MockFamilyRepository(),
        children = MockChildrenRepository(),
        catalogue = MockCatalogueRepository(),
        curriculum = MockCurriculumRepository(),
        planning = MockPlanningRepository(),
        progress = MockProgressRepository(),
        pin = MockPinRepository(),
        config = MockConfigRepository(),
        session = MockSessionRepository(),
        textbook = MockTextbookRepository();

  final MockAuthRepository auth;
  final MockFamilyRepository family;
  final MockChildrenRepository children;
  final MockCatalogueRepository catalogue;
  final MockCurriculumRepository curriculum;
  final MockPlanningRepository planning;
  final MockProgressRepository progress;
  final MockPinRepository pin;
  final MockConfigRepository config;
  final MockSessionRepository session;
  final MockTextbookRepository textbook;

  AppEnvironment build() {
    return AppEnvironment(
      secureStore: InMemorySecureStore(),
      tokenManager: freshTokenManager(),
      pendingQueue: PendingQueue(storage: InMemoryKeyValueStorage()),
      elevationCache: ElevationCache(),
      authRepository: auth,
      familyRepository: family,
      childrenRepository: children,
      catalogueRepository: catalogue,
      curriculumRepository: curriculum,
      planningRepository: planning,
      progressRepository: progress,
      pinRepository: pin,
      configRepository: config,
      sessionRepository: session,
      textbookRepository: textbook,
    );
  }
}
