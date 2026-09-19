package store

// TableRow mirrors the tables table. Zero EndedAt means NULL.
type TableRow struct {
	ID         string
	Name       string
	State      string
	CreatedAt  int64
	EndedAt    int64
	HandNumber int
	ButtonSeat int // -1 when no hand has been dealt yet
	// AdminTokenHash is the SHA-256 of the creator's admin token.
	AdminTokenHash string
	// RoundStartHand is HandNumber when the current round began (0 for the
	// first round); a new round on the same table moves it up.
	RoundStartHand int
	// LastRound is the JSON standing of the last finished round, "" = none.
	LastRound string
}

// SettingsRow mirrors table_settings. PasswordHash is empty when the table
// has no password.
type SettingsRow struct {
	TableID      string
	PasswordHash string
	MaxPlayers   int
	StartMoney   int64
	SmallBlind   int64
	BigBlind     int64
	Ante         int64
	// The blind level the host configured: what a new round starts at, kept
	// apart from the live level the blind schedule raises.
	StartSmallBlind        int64
	StartBigBlind          int64
	StartAnte              int64
	TurnTime               int
	DisconnectedTurnTime   int
	SitOutAfterMissedTurns int
	JoinPolicy             string
	AllowSpectators        bool
	SpectatorChat          bool
	ChatEnabled            bool
	AllowRebuy             bool
	ShowdownReveal         string
	AutoStart              bool
	HandDelayMs            int
	AllowRabbitHunt        bool
	AllowDrawing           bool
	Tournament             bool
	BlindsUpMinutes        int
	BlindsUpPercent        int
	TimeBankSeconds        int
	TimeBankRefillSeconds  int
	AllowStraddle          bool
	RunItTwice             bool
	Variant                string
}

// PlayerRow mirrors players. Zero LeftAt means NULL.
type PlayerRow struct {
	ID          string
	TableID     string
	Name        string
	Seat        int
	Stack       int64
	Status      string
	Muted       bool
	MissedTurns int
	BuyInTotal  int64
	HandsPlayed int
	HandsWon    int
	BiggestPot  int64
	JoinedAt    int64
	LeftAt      int64
	Avatar      int
	Hat         string // one of protocol.Hats, "" = none
	WinStreak   int    // hands won in a row
	// Statistics and standing.
	VPIPHands    int
	Showdowns    int
	ShowdownsWon int
	TimeBank     int
	Place        int
	// AccountID links the seat to a profile ("" for a guest), AccountHandle
	// is that profile's handle as it was when the player sat down.
	AccountID     string
	AccountHandle string
}

// AccountRow mirrors accounts: an optional player profile. Handle is the
// name as typed, HandleKey its folded form (uniqueness), and the Vis*
// fields say who may see each part of the profile ("private", "friends" or
// "public").
type AccountRow struct {
	ID           string
	Handle       string
	HandleKey    string
	DisplayName  string
	PasswordHash string
	RecoveryHash string
	CreatedAt    int64

	VisProfile      string
	VisWinnings     string
	VisBestHands    string
	VisAchievements string
	VisActivity     string
}

// HandResultRow mirrors hand_results: one profile's part in one hand.
type HandResultRow struct {
	AccountID   string
	TableID     string
	TableName   string
	HandNumber  int
	EndedAt     int64
	BigBlind    int64
	Net         int64
	Won         int64
	DealtIn     bool
	Folded      bool
	VPIP        bool
	Showdown    bool
	ShowdownWon bool
	AllIn       bool
	// Category is a poker.Category, -1 when the hand never saw a board;
	// Royal marks an ace-high straight flush, Shown that the table saw it.
	Category    int
	Royal       bool
	Shown       bool
	Description string
	BestCards   string
	Counted     bool
	Profiles    int
}

// RoundResultRow mirrors round_results: one profile's finished round.
type RoundResultRow struct {
	AccountID  string
	TableID    string
	TableName  string
	RoundStart int
	EndedAt    int64
	BigBlind   int64
	Net        int64
	Place      int
	Players    int
	Tournament bool
	Counted    bool
}

// AccountSessionRow mirrors account_sessions: a profile login, which
// outlives the tables the player sits at.
type AccountSessionRow struct {
	TokenHash string
	AccountID string
	CreatedAt int64
	ExpiresAt int64
}

// SessionRow mirrors sessions.
type SessionRow struct {
	TokenHash string
	Kind      string // player | spectator
	TableID   string
	PlayerID  string
	Name      string
	CreatedAt int64
	ExpiresAt int64
}

// ChatRow mirrors chat_messages.
type ChatRow struct {
	ID         int64
	TableID    string
	AuthorKind string
	AuthorName string
	Text       string
	TS         int64
}

// HandRow mirrors hands. JSON columns are kept as raw bytes.
type HandRow struct {
	ID            int64
	TableID       string
	Number        int
	StartedAt     int64
	EndedAt       int64
	ButtonSeat    int
	SmallBlind    int64
	BigBlind      int64
	Ante          int64
	StacksAtStart []byte
	Events        []byte
	Results       []byte
	Voided        bool
}

// AdminActionRow mirrors admin_actions.
type AdminActionRow struct {
	ID       int64
	TS       int64
	Action   string
	TableID  string
	PlayerID string
	Details  []byte
}
