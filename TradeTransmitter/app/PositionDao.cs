using System.Data.SQLite;
using System.Diagnostics;
using Dapper;

public class Position
{
    // ポジションID
    public required string position_id { get; set; }
    // メールアドレス
    public required string email { get; set; }
    // 口座番号
    public int account { get; set; }
    // 変更
    public int change { get; set; }
    // コマンド
    public int command { get; set; }
    // シンボル
    public required string symbol { get; set; }
    // ロット数
    public double lots { get; set; }
    // 作成日時
    public string? create_at { get; set; }
    // 削除日時（NULL可）
    public string? delete_at { get; set; }
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
                position_id TEXT PRIMARY KEY NOT NULL UNIQUE,
                email TEXT NOT NULL,
                account INTEGER NOT NULL,
                change INTEGER NOT NULL,
                command INTEGER NOT NULL,
                symbol TEXT NOT NULL,
                lots REAL NOT NULL,
                create_at TEXT NULL,
                delete_at TEXT NULL
            )");
        connection.Execute(@"
            CREATE INDEX IF NOT EXISTS idx_positions_email_account ON positions (email, account)");
        connection.Execute(@"
            CREATE INDEX IF NOT EXISTS idx_positions_create_at ON positions (create_at)");
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
            INSERT INTO positions (position_id, email, account, change, command, symbol, lots, create_at, delete_at)
            VALUES (@position_id, @email, @account, @change, @command, @symbol, @lots, NULL, NULL)";
        connection.Execute(sql, position);
    }

    /// <summary>
    /// ポジションを挿入する
    /// </summary>
    public void UpdatePosition(string positionId)
    {
        using var connection = new SQLiteConnection(_connectionString);
        string sql = @"
            UPDATE positions SET change = -1
            WHERE position_id = @PositionId";
        connection.Execute(sql, new { PositionId = positionId });
    }

    /// <summary>
    /// 指定したemailとaccountでレコードを取得する（論理削除されていないもののみ）
    /// </summary>
    public List<Position> GetPositions(string email, int account)
    {
        using var connection = new SQLiteConnection(_connectionString);
        string sql = @"
            SELECT position_id, email, account, change, command, symbol, lots, create_at, delete_at FROM positions 
            WHERE email = @Email AND account = @Account AND (create_at IS NULL OR (change = -1 AND delete_at IS NULL))";
        return connection.Query<Position>(sql, new { Email = email, Account = account }).ToList();
    }

    /// <summary>
    /// 指定したemailとaccountでレコードを論理削除する
    /// </summary>
    public void EntryPosition(string positionId, string create_at)
    {
        using var connection = new SQLiteConnection(_connectionString);
        string sql = @"
            UPDATE positions SET create_at = @CreateAt
            WHERE position_id = @Positiond";
        connection.Execute(sql, new { Positiond = positionId, CreateAt = create_at });
    }

    /// <summary>
    /// 指定したemailとaccountでレコードを論理削除する
    /// </summary>
    public void ExitPosition(string positionId, string delete_at)
    {
        using var connection = new SQLiteConnection(_connectionString);
        string sql = @"
            UPDATE positions SET delete_at = @DeleteAt
            WHERE position_id = @Positiond";
        connection.Execute(sql, new { Positiond = positionId, DeleteAt = delete_at });
    }
}
