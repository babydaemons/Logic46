using System.Data.SQLite;
using Dapper;

public class Position
{
    // 自動採番PK
    public int Id { get; set; }
    // メールアドレス
    public required string Email { get; set; }
    // 口座番号
    public int Account { get; set; }
    // ポジションID
    public required string PositionId { get; set; }
    // 変更
    public int Change { get; set; }
    // コマンド
    public int Command { get; set; }
    // シンボル
    public required string Symbol { get; set; }
    // ロット数
    public double Lots { get; set; }
    // 作成日時
    public required string CreateAt { get; set; }
    // 削除日時（NULL可）
    public string? DeleteAt { get; set; }
}

public class PositionDao
{
    private readonly string _connectionString;

    public PositionDao(string dbPath)
    {
        string connectionString = $"Data Source={dbPath};Version=3;";
        _connectionString = connectionString;
        using var connection = new SQLiteConnection(_connectionString);
        connection.Execute(@"
            CREATE TABLE IF NOT EXISTS positions (
                id INTEGER PRIMARY KEY AUTOINCREMENT, -- プライマリキー（内部識別用）
                position_id TEXT NOT NULL UNIQUE, -- ユニークキー
                email TEXT NOT NULL,
                account INTEGER NOT NULL,
                change INTEGER NOT NULL,
                command INTEGER NOT NULL,
                symbol TEXT NOT NULL,
                lots REAL NOT NULL,
                create_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
                delete_at TEXT NULL
            )");
        connection.Execute(@"
            CREATE INDEX IF NOT EXISTS idx_positions_email_account ON positions (email, account)");
        connection.Execute(@"
            CREATE INDEX IF NOT EXISTS idx_positions_delete_at ON positions (delete_at)");
    }

    /// <summary>
    /// ポジションを挿入する
    /// </summary>
    public void InsertPosition(Position position)
    {
        using var connection = new SQLiteConnection(_connectionString);
        string sql = @"
            INSERT INTO positions (email, account, position_id, change, command, symbol, lots, create_at, delete_at)
            VALUES (@Email, @Account, @PositionId, @Change, @Command, @Symbol, @Lots, @CreateAt, @DeleteAt)";
        connection.Execute(sql, position);
    }

    /// <summary>
    /// 指定したemailとaccountでレコードを取得する（論理削除されていないもののみ）
    /// </summary>
    public List<Position> GetPositions(string email, int account)
    {
        using var connection = new SQLiteConnection(_connectionString);
        string sql = @"
            SELECT * FROM positions 
            WHERE email = @Email AND account = @Account AND delete_at IS NULL";
        return connection.Query<Position>(sql, new { Email = email, Account = account }).ToList();
    }

    /// <summary>
    /// 指定したemailとaccountでレコードを論理削除する
    /// </summary>
    public void SoftDeletePositions(string email, int account)
    {
        using var connection = new SQLiteConnection(_connectionString);
        string sql = @"
            UPDATE positions SET delete_at = datetime('now')
            WHERE email = @Email AND account = @Account AND delete_at IS NULL";
        connection.Execute(sql, new { Email = email, Account = account });
    }
}
