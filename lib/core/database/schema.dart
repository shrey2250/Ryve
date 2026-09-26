/// RYVE SQLite Schema — Version 1
///
/// All monetary values stored as INTEGER (paise, 1 INR = 100 paise).
/// All IDs stored as TEXT (UUID v4).
/// All timestamps stored as TEXT (ISO 8601 UTC).
/// Soft deletion via deletedAt where applicable.
abstract final class DatabaseSchema {
  static const int version = 1;

  // ─── Table Names ─────────────────────────────────────────────────────────
  static const String accounts = 'accounts';
  static const String transactions = 'transactions';
  static const String categories = 'categories';
  static const String transfers = 'transfers';
  static const String budgets = 'budgets';
  static const String goals = 'goals';
  static const String people = 'people';
  static const String iouRecords = 'iou_records';
  static const String iouRepayments = 'iou_repayments';
  static const String groups = 'groups';
  static const String groupMembers = 'group_members';
  static const String groupExpenses = 'group_expenses';
  static const String expenseSplits = 'expense_splits';
  static const String settlements = 'settlements';
  static const String settings = 'settings';
  static const String recurringBills = 'recurring_bills';

  // ─── CREATE TABLE Statements ──────────────────────────────────────────────

  static const String createAccounts = '''
    CREATE TABLE $accounts (
      id          TEXT PRIMARY KEY,
      name        TEXT NOT NULL,
      type        TEXT NOT NULL CHECK(type IN ('cash','bank','upi','credit_card','other')),
      balancePaise INTEGER NOT NULL DEFAULT 0,
      currency    TEXT NOT NULL DEFAULT 'INR',
      isArchived  INTEGER NOT NULL DEFAULT 0,
      createdAt   TEXT NOT NULL,
      updatedAt   TEXT NOT NULL
    )
  ''';

  /// Transactions cover both income and expense.
  /// Transfers are stored separately and must NOT appear here.
  static const String createTransactions = '''
    CREATE TABLE $transactions (
      id          TEXT PRIMARY KEY,
      accountId   TEXT NOT NULL,
      type        TEXT NOT NULL CHECK(type IN ('expense','income')),
      amountPaise INTEGER NOT NULL CHECK(amountPaise > 0),
      categoryId  TEXT,
      description TEXT NOT NULL DEFAULT '',
      merchant    TEXT,
      date        TEXT NOT NULL,
      note        TEXT,
      createdAt   TEXT NOT NULL,
      updatedAt   TEXT NOT NULL,
      deletedAt   TEXT,
      FOREIGN KEY (accountId) REFERENCES $accounts(id),
      FOREIGN KEY (categoryId) REFERENCES $categories(id)
    )
  ''';

  static const String createCategories = '''
    CREATE TABLE $categories (
      id          TEXT PRIMARY KEY,
      name        TEXT NOT NULL,
      icon        TEXT NOT NULL,
      isSystem    INTEGER NOT NULL DEFAULT 0,
      isArchived  INTEGER NOT NULL DEFAULT 0,
      createdAt   TEXT NOT NULL,
      updatedAt   TEXT NOT NULL
    )
  ''';

  /// Transfers do NOT affect income/expense totals.
  /// Both account balances are updated atomically.
  static const String createTransfers = '''
    CREATE TABLE $transfers (
      id              TEXT PRIMARY KEY,
      fromAccountId   TEXT NOT NULL,
      toAccountId     TEXT NOT NULL,
      amountPaise     INTEGER NOT NULL CHECK(amountPaise > 0),
      date            TEXT NOT NULL,
      note            TEXT,
      createdAt       TEXT NOT NULL,
      updatedAt       TEXT NOT NULL,
      deletedAt       TEXT,
      FOREIGN KEY (fromAccountId) REFERENCES $accounts(id),
      FOREIGN KEY (toAccountId)   REFERENCES $accounts(id)
    )
  ''';

  /// V1 supports one overall monthly budget.
  /// categoryId nullable for future per-category budgets.
  static const String createBudgets = '''
    CREATE TABLE $budgets (
      id          TEXT PRIMARY KEY,
      month       TEXT NOT NULL,
      amountPaise INTEGER NOT NULL CHECK(amountPaise > 0),
      categoryId  TEXT,
      createdAt   TEXT NOT NULL,
      updatedAt   TEXT NOT NULL,
      FOREIGN KEY (categoryId) REFERENCES $categories(id)
    )
  ''';

  static const String createGoals = '''
    CREATE TABLE $goals (
      id                      TEXT PRIMARY KEY,
      name                    TEXT NOT NULL,
      targetAmountPaise       INTEGER NOT NULL CHECK(targetAmountPaise > 0),
      savedAmountPaise        INTEGER NOT NULL DEFAULT 0,
      monthlyContributionPaise INTEGER,
      targetDate              TEXT,
      icon                    TEXT NOT NULL DEFAULT 'star',
      createdAt               TEXT NOT NULL,
      updatedAt               TEXT NOT NULL,
      deletedAt               TEXT
    )
  ''';

  static const String createPeople = '''
    CREATE TABLE $people (
      id              TEXT PRIMARY KEY,
      name            TEXT NOT NULL,
      avatarInitials  TEXT,
      createdAt       TEXT NOT NULL,
      updatedAt       TEXT NOT NULL
    )
  ''';

  /// Remaining balance = originalAmountPaise − SUM(iou_repayments.amountPaise)
  static const String createIouRecords = '''
    CREATE TABLE $iouRecords (
      id                  TEXT PRIMARY KEY,
      personId            TEXT NOT NULL,
      type                TEXT NOT NULL CHECK(type IN ('lent','borrowed')),
      originalAmountPaise INTEGER NOT NULL CHECK(originalAmountPaise > 0),
      dueDate             TEXT,
      note                TEXT,
      status              TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','settled')),
      createdAt           TEXT NOT NULL,
      updatedAt           TEXT NOT NULL,
      deletedAt           TEXT,
      FOREIGN KEY (personId) REFERENCES $people(id)
    )
  ''';

  static const String createIouRepayments = '''
    CREATE TABLE $iouRepayments (
      id          TEXT PRIMARY KEY,
      iouId       TEXT NOT NULL,
      amountPaise INTEGER NOT NULL CHECK(amountPaise > 0),
      date        TEXT NOT NULL,
      note        TEXT,
      createdAt   TEXT NOT NULL,
      FOREIGN KEY (iouId) REFERENCES $iouRecords(id)
    )
  ''';

  static const String createGroups = '''
    CREATE TABLE $groups (
      id        TEXT PRIMARY KEY,
      name      TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      deletedAt TEXT
    )
  ''';

  static const String createGroupMembers = '''
    CREATE TABLE $groupMembers (
      id        TEXT PRIMARY KEY,
      groupId   TEXT NOT NULL,
      name      TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      FOREIGN KEY (groupId) REFERENCES $groups(id)
    )
  ''';

  static const String createGroupExpenses = '''
    CREATE TABLE $groupExpenses (
      id              TEXT PRIMARY KEY,
      groupId         TEXT NOT NULL,
      description     TEXT NOT NULL,
      amountPaise     INTEGER NOT NULL CHECK(amountPaise > 0),
      paidByMemberId  TEXT NOT NULL,
      date            TEXT NOT NULL,
      note            TEXT,
      createdAt       TEXT NOT NULL,
      updatedAt       TEXT NOT NULL,
      deletedAt       TEXT,
      FOREIGN KEY (groupId)        REFERENCES $groups(id),
      FOREIGN KEY (paidByMemberId) REFERENCES $groupMembers(id)
    )
  ''';

  /// V1 supports equal split only.
  /// The sum of all split amountPaise MUST equal the parent groupExpense.amountPaise.
  /// Rounding remainder is assigned to the first member deterministically.
  static const String createExpenseSplits = '''
    CREATE TABLE $expenseSplits (
      id              TEXT PRIMARY KEY,
      groupExpenseId  TEXT NOT NULL,
      memberId        TEXT NOT NULL,
      amountPaise     INTEGER NOT NULL CHECK(amountPaise >= 0),
      createdAt       TEXT NOT NULL,
      FOREIGN KEY (groupExpenseId) REFERENCES $groupExpenses(id),
      FOREIGN KEY (memberId)       REFERENCES $groupMembers(id)
    )
  ''';

  static const String createSettlements = '''
    CREATE TABLE $settlements (
      id            TEXT PRIMARY KEY,
      groupId       TEXT NOT NULL,
      fromMemberId  TEXT NOT NULL,
      toMemberId    TEXT NOT NULL,
      amountPaise   INTEGER NOT NULL CHECK(amountPaise > 0),
      date          TEXT NOT NULL,
      note          TEXT,
      createdAt     TEXT NOT NULL,
      FOREIGN KEY (groupId)       REFERENCES $groups(id),
      FOREIGN KEY (fromMemberId)  REFERENCES $groupMembers(id),
      FOREIGN KEY (toMemberId)    REFERENCES $groupMembers(id)
    )
  ''';

  /// Key-value store for app settings.
  /// Never store raw PINs — store only hashed values and metadata.
  static const String createSettings = '''
    CREATE TABLE $settings (
      key       TEXT PRIMARY KEY,
      value     TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''';

  /// Recurring bills and subscription tracking.
  static const String createRecurringBills = '''
    CREATE TABLE $recurringBills (
      id          TEXT PRIMARY KEY,
      name        TEXT NOT NULL,
      amountPaise INTEGER NOT NULL CHECK(amountPaise > 0),
      cycle       TEXT NOT NULL CHECK(cycle IN ('monthly','yearly','weekly')),
      nextDueDate TEXT NOT NULL,
      categoryId  TEXT,
      accountId   TEXT,
      icon        TEXT NOT NULL DEFAULT 'receipt',
      isActive    INTEGER NOT NULL DEFAULT 1,
      createdAt   TEXT NOT NULL,
      updatedAt   TEXT NOT NULL,
      deletedAt   TEXT,
      FOREIGN KEY (categoryId) REFERENCES $categories(id),
      FOREIGN KEY (accountId)  REFERENCES $accounts(id)
    )
  ''';

  // ─── Indexes ─────────────────────────────────────────────────────────────
  static const List<String> createIndexes = [
    'CREATE INDEX idx_transactions_account ON $transactions(accountId)',
    'CREATE INDEX idx_transactions_date ON $transactions(date)',
    'CREATE INDEX idx_transactions_deleted ON $transactions(deletedAt)',
    'CREATE INDEX idx_transfers_accounts ON $transfers(fromAccountId, toAccountId)',
    'CREATE INDEX idx_iou_records_person ON $iouRecords(personId)',
    'CREATE INDEX idx_group_members_group ON $groupMembers(groupId)',
    'CREATE INDEX idx_group_expenses_group ON $groupExpenses(groupId)',
    'CREATE INDEX idx_expense_splits_expense ON $expenseSplits(groupExpenseId)',
    'CREATE INDEX idx_settlements_group ON $settlements(groupId)',
    'CREATE INDEX idx_recurring_bills_due ON $recurringBills(nextDueDate)',
  ];

  // ─── All create statements in dependency order ────────────────────────────
  static List<String> get allCreateStatements => [
        createCategories,
        createAccounts,
        createTransactions,
        createTransfers,
        createBudgets,
        createGoals,
        createPeople,
        createIouRecords,
        createIouRepayments,
        createGroups,
        createGroupMembers,
        createGroupExpenses,
        createExpenseSplits,
        createSettlements,
        createSettings,
        createRecurringBills,
        ...createIndexes,
      ];
}
