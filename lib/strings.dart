/// All user-facing copy in one place (English only for MVP). Nothing here should be interpolated with
/// personal data beyond simple placeholders the caller fills in with `.replaceFirst`/string interpolation
/// at the call site; this file only holds the literal templates and labels.
class Str {
  const Str._();

  // ---- Common ----
  static const String appName = 'HomeSchooling';
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String done = 'Done';
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String retry = 'Try again';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String close = 'Close';
  static const String confirm = 'Confirm';
  static const String loading = 'Loading…';
  static const String today = 'Today';
  static const String tomorrow = 'Tomorrow';
  static const List<String> weekdaysShort = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> monthsShort = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  // ---- Errors (generic, shown when a request fails) ----
  static const String errorNetwork = "Can't reach the server. Check your connection and try again.";
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorOtpInvalid = "That code is wrong or has expired. Check it and try again, or resend.";
  static const String errorBadResponse = 'The server sent something unexpected. Please try again.';
  static const String errorSessionExpired = 'Your session ended. Please sign in again.';
  static const String errorConflict = 'This was changed somewhere else. Reloading the latest version.';
  static const String errorEmailTaken = 'That email is already registered. Try signing in instead.';
  static const String errorValidation = 'Please check the highlighted fields.';
  static const String errorInvalidCredentials = 'Email or password is incorrect.';
  static const String errorRateLimited = 'Too many attempts. Please wait a few minutes and try again.';
  static const String errorDeliveryFailed = "We couldn't send that message. Please try again in a moment.";
  static const String emptyGeneric = 'Nothing here yet.';

  // ---- Auth ----
  static const String signupTitle = 'Create your account';
  static const String loginTitle = 'Welcome back';
  static const String fullNameLabel = 'Your full name';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String currentPasswordLabel = 'Current password';
  static const String familyNameLabel = 'Family name (optional)';
  static const String passwordHint = 'At least 10 characters';
  static const String signupCta = 'Create account';
  static const String loginCta = 'Sign in';
  static const String needAccount = "Don't have an account? Create one";
  static const String haveAccount = 'Already have an account? Sign in';
  static const String invalidEmail = 'Enter a valid email address';
  static const String invalidPassword = 'Password must be 10-128 characters';
  static const String invalidFullName = 'Enter your name';
  static const String signupWelcome = 'A few details, then we will set up your family.';

  // ---- Forgot password / temporary password ----
  static const String forgotPasswordCta = 'Forgot password?';
  static const String forgotPasswordTitle = 'Reset your password';
  static const String forgotPasswordIntro = "Enter your account email and we'll send you a temporary password.";
  static const String forgotPasswordSend = 'Email me a temporary password';
  static const String forgotPasswordSentTitle = 'Check your email';
  static const String forgotPasswordSentBody =
      'If that email has an account, a temporary password is on its way. It only works for a short time. '
      "Sign in with it and you'll be asked to choose a new password.";
  static const String backToSignIn = 'Back to sign in';
  static const String changePasswordTitle = 'Choose a new password';
  static const String changePasswordIntro =
      'You signed in with a temporary password. Choose a new password to continue.';
  static const String temporaryPasswordLabel = 'Temporary password';
  static const String newPasswordLabel = 'New password';
  static const String confirmPasswordLabel = 'Confirm new password';
  static const String passwordsDoNotMatch = "The two passwords don't match";
  static const String passwordMustDiffer = 'Choose a password different from the temporary one';
  static const String changePasswordCta = 'Save new password';
  static const String errorTempPasswordWrong =
      'That temporary password is not correct or has expired. Go back to sign in and request a new one.';
  static const String signOut = 'Sign out';

  // ---- Guardian verification (DPDP) ----
  static const String guardianTitle = 'Verify you are a parent or guardian';
  static const String guardianIntro =
      'Indian law (the DPDP Act) requires us to verify a parent or guardian before we '
      'create a profile for a child under 18. This takes about a minute.';
  static const String guardianPhoneLabel = 'Mobile number';
  static const String guardianPhoneHint = 'We will text you a 6-digit code';
  static const String guardianSendCode = 'Send code';
  static const String guardianCodeLabel = 'Enter the 6-digit code';
  static const String guardianResend = 'Resend code';
  static const String guardianEmailCta = 'Email me a code instead';
  static const String guardianEmailHint = "We'll send the 6-digit code to the email address you signed up with.";
  static const String guardianCodeSentTo = 'Code sent to';
  static const String guardianInvalidPhone = 'Enter a valid mobile number';
  static const String guardianInvalidOtp = 'Enter the 6-digit code';
  static const String guardianDevCodeNotice = 'Dev/test build: the code was returned by the server, shown below.';

  /// DRAFT — placeholder guardian declaration text. NEEDS LEGAL REVIEW before this ships to production.
  /// It must match, word for word once approved, the notice whose version string comes from
  /// `GET /v1/config -> declaration_notice_version` (see RemoteConfig).
  static const String guardianDeclarationDraft =
      'DRAFT — pending legal review. I declare that I am the parent or lawful guardian of the child whose '
      'profile I am about to create, that I am at least 18 years old, and that I consent, on the child\'s '
      'behalf, to the collection and use of the child\'s personal data as described in our Privacy Notice, '
      'for the purpose of providing homeschooling activities, tracking learning progress, and related '
      'communications. I understand I can withdraw this consent at any time from Settings, which may limit '
      'or stop the service for this child.';
  static const String guardianDeclarationCheckbox = 'I have read and agree to the declaration above';
  static const String guardianDeclarationLegalNotice =
      '(placeholder copy — legal has not signed off on this text yet)';
  static const String guardianConfirmCta = 'Confirm and continue';
  static const String guardianSuccess = 'Thank you. You are verified as a guardian.';

  // ---- PIN ----
  static const String pinSetTitle = 'Set a parent PIN';
  static const String pinSetIntro = 'This PIN protects parent-only screens when your child is using the app.';
  static const String pinChangeTitle = 'Change parent PIN';
  static const String pinVerifyTitle = 'Enter your PIN';
  static const String pinLabel = 'PIN (4-6 digits)';
  static const String pinConfirmLabel = 'Confirm PIN';
  static const String pinMismatch = "PINs don't match";
  static const String pinInvalid = 'PIN must be 4 to 6 digits';
  static const String pinCurrentLabel = 'Current PIN';
  static const String pinWrong = 'Wrong PIN';
  static const String pinForgot = 'Forgot PIN?';
  static const String pinResetTitle = 'Reset your PIN';
  static const String pinResetIntro = 'Enter your account password and choose a new PIN.';
  static const String pinResetCta = 'Reset PIN';
  static const String pinSetCta = 'Set PIN';
  static const String pinLockedPrefix = 'Too many attempts. Try again in';

  static String pinAttemptsRemaining(int n) => n == 1 ? '1 attempt left' : '$n attempts left';

  static String pinLockedFor(String duration) => '$pinLockedPrefix $duration';

  // ---- Profiles / who's learning ----
  static const String whoIsLearning = "Who's learning today?";
  static const String parentTile = 'Parent';
  static const String addChild = 'Add a child';
  static const String editChild = 'Edit profile';
  static const String childNameLabel = "Child's first name or nickname";
  static const String birthYearLabel = 'Birth year (optional)';
  static const String levelLabel = 'Starting level';
  static const String interestsLabel = 'Interests';
  static const String goalsLabel = 'Goals (optional)';
  static const String deleteChildTitle = 'Delete this profile?';
  static const String deleteChildBody =
      'This removes the child\'s profile, plan and progress. This cannot be undone. Enter your PIN to confirm.';
  static const String deleteChildCta = 'Delete profile';
  static const String saveChanges = 'Save changes';
  static const String createProfile = 'Create profile';
  static const String staleProfile = 'This profile changed elsewhere. We reloaded the latest version — please review and save again.';

  // ---- Child home ----
  static String greeting(int dayPart, String name) {
    final List<String> greetings = <String>['Good morning', 'Good afternoon', 'Good evening'];
    return '${greetings[dayPart]}, $name!';
  }

  static const String todaysPlan = "Today's activities";
  static const String noActivitiesToday = 'Nothing planned for today. Ask a grown-up to add something!';
  static const String startActivity = 'Start';
  static const String continueActivity = 'Continue';
  static const String activityDone = 'Well done!';
  static const String backToParent = 'Switch profile';
  static const String daysLearnedThisWeek = 'days you learned this week';

  // ---- Player ----
  static const String hintButton = 'Hint';
  static const String grownUpHelped = 'A grown-up helped me';
  static const String stepOfLabel = 'Step';
  static const String playerExitTitle = 'Leave this activity?';
  static const String playerExitBody = 'Your answers so far will be saved. You can continue later.';
  static const String playerExitCta = 'Leave';
  static const String playerSubmit = 'Finish';
  static const String playerSubmitting = 'Sending…';
  static const String playerOfflineQueued = "No internet right now. We'll send this as soon as you're back online.";
  static const String captureDoneWithGrownUp = 'Do this with a grown-up, then tap Done.';
  static const String reflectionPrompt = 'How did that feel?';
  static const String timerStart = 'Start timer';
  static const String timerPause = 'Pause';
  static const String timerResume = 'Resume';
  static const String matchLeftHint = 'Tap one on the left, then its match on the right';
  static const String sequenceHint = 'Drag to put them in order';
  static const String numericInputHint = 'Type a number';
  static const String shortTextHint = 'Type your answer';
  static const String resultTitle = 'Great work!';
  static const String resultReviewPending = 'A grown-up will look at this with you soon.';

  // ---- Parent: dashboard ----
  static const String dashboardTitle = 'Dashboard';
  static const String dashboardWeekProgress = 'This week';
  static const String dashboardActivities = 'Activities';
  static const String dashboardMinutes = 'Minutes';
  static const String dashboardNewSkills = 'New skills';
  static const String dashboardStreak = 'Day streak';
  static const String recommendedForChild = 'Recommended';
  static const String planTomorrow = 'Plan tomorrow';
  static const String viewFullProgress = 'View full progress';

  // ---- Parent: planner ----
  static const String plannerTitle = 'Planner';
  static const String plannerAddActivity = 'Add activity';
  static const String plannerReschedule = 'Reschedule';
  static const String plannerSkip = 'Mark as skipped';
  static const String plannerRemove = 'Remove from plan';
  static const String plannerEmptyDay = 'Nothing planned this day.';
  static const String plannerPickDate = 'Move to';

  // ---- Parent: catalogue ----
  static const String catalogueTitle = 'Activity library';
  static const String catalogueSearchHint = 'Search activities';
  static const String catalogueFilterSubject = 'Subject';
  static const String catalogueFilterLevel = 'Level';
  static const String catalogueFilterInterest = 'Interest';
  static const String catalogueAllSubjects = 'All subjects';
  static const String catalogueAllLevels = 'All levels';
  static const String catalogueAllInterests = 'All interests';
  static const String catalogueAddToPlan = 'Add to plan';
  static const String catalogueLoadMore = 'Load more';
  static const String catalogueNoResults = 'No activities match your filters.';

  // ---- Parent: progress / mastery ----
  static const String progressTitle = 'Progress';
  static const String masteryEmerging = 'Emerging';
  static const String masteryDeveloping = 'Developing';
  static const String masterySecure = 'Secure';
  static const String needsRevisit = 'Needs revisit';
  static const String addObservation = 'Add observation';
  static const String observationRatingLabel = 'How did they do?';
  static const String observationNoteLabel = 'Note (optional)';
  static const String ratingTrying = 'Trying';
  static const String ratingWithHelp = 'With help';
  static const String ratingIndependent = 'Independent';
  static const String baselineChecklistTitle = 'Starting checklist';
  static const String baselineChecklistIntro = 'Rate what your child can already do, so we start at the right level.';
  static const String addMoreSkills = 'Add more skills';
  static const String switchProfile = 'Switch profile';
  static const String noNewSkillsToAdd = "That's everything at this level for now \u2014 new skills will show up here after an app update.";

  // ---- Parent: reviews ----
  static const String reviewsTitle = 'Needs your review';
  static const String reviewsEmpty = "You're all caught up. Nothing needs review right now.";
  static const String reviewsIntro = 'Rate how your child did on the steps a grown-up needs to check.';
  static const String reviewSubmit = 'Save review';

  // ---- Parent: settings ----
  static const String settingsTitle = 'Settings';
  static const String settingsConsents = 'Privacy and consent';
  static const String settingsChangePin = 'Change PIN';
  static const String settingsSignOut = 'Sign out';
  static const String settingsAppVersion = 'App version';
  static const String settingsEnvironment = 'Environment';
  static const String settingsDeleteChild = 'Delete a child profile';
  static const String consentMediaCapture = 'Photos and audio in activities';
  static const String consentAiPersonalization = 'Personalised recommendations';
  static const String consentProductAnalytics = 'Product analytics';
  static const String signOutConfirmTitle = 'Sign out?';
  static const String signOutConfirmBody = "You'll need your email and password to sign in again.";

  // ---- Update gate ----
  static const String updateRequiredTitle = 'Update required';
  static const String updateRequiredBody =
      'A new version of HomeSchooling is required to continue. Please update from the Play Store.';
}
