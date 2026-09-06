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
}

// SettingsRow mirrors table_settings. PasswordHash is empty when the table
// has no password.
type SettingsRow struct {
	TableID                string
	PasswordHash           string
	MaxPlayers             int
	StartMoney             int64
	SmallBlind             int64
	BigBlind               int64
	Ante                   int64
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
	BlindsUpMinutes        int
	BlindsUpPercent        int
	TimeBankSeconds        int
	TimeBankRefillSeconds  int
	AllowStraddle          bool
	RunItTwice             bool
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
	// Statistics and standing.
	VPIPHands    int
	Showdowns    int
	ShowdownsWon int
	TimeBank     int
	Place        int
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
