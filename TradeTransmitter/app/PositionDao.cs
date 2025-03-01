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
    // コマンド
    public int change { get; set; }
    // コマンド
    public int command { get; set; }
    // シンボル
    public required string symbol { get; set; }
    // ロット数
    public double lots { get; set; }
    // 作成日時
    public string? create_at { get; set; }
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
                command INTEGER NOT NULL,
                symbol TEXT NOT NULL,
                lots REAL NOT NULL,
                create_at TEXT NULL
            )");
        connection.Execute(@"
            CREATE INDEX IF NOT EXISTS idx_positions_email_account ON positions (email, account)");
        connection.Execute(@"
            CREATE TABLE IF NOT EXISTS historical_positions (
                position_id TEXT PRIMARY KEY NOT NULL UNIQUE,
                email TEXT NOT NULL,
                account INTEGER NOT NULL,
                command INTEGER NOT NULL,
                symbol TEXT NOT NULL,
                lots REAL NOT NULL,
                create_at TEXT NOT NULL,
                delete_at TEXT NULL
            )");
        connection.Execute(@"
            CREATE INDEX IF NOT EXISTS idx_historical_positions_email_account ON historical_positions (email, account)");
        connection.Execute(@"
            CREATE INDEX IF NOT EXISTS idx_historical_positions_delete_at ON historical_positions (delete_at)");
    }

    /// <summary>
    /// ポジションを挿入する
    /// </summary>
    public void InsertPosition(Position position)
    {
        using var connection = new SQLiteConnection(_connectionString);
        string sql = @"
            INSERT INTO positions (position_id, email, account, command, symbol, lots, create_at)
            VALUES (@position_id, @email, @account, @change, @command, @symbol, @lots, NULL)";
        connection.Execute(sql, position);
    }

    /// <summary>
    /// ポジションを挿入する
    /// </summary>
    public void MovePosition(string position_id)
    {
        using var connection = new SQLiteConnection(_connectionString);
        string sql = @"
            INSERT INTO historical_positions (position_id, email, account, command, symbol, lots, create_at, delete_at)
            SELECT position_id, email, account, command, symbol, lots, create_at, NULL FROM positions
            WHERE position_id = @position_id";
        connection.Execute(sql, new { position_id = position_id });
    }

    /// <summary>
    /// 指定したemailとaccountでレコードを取得する（論理削除されていないもののみ）
    /// </summary>
    public List<Position> GetPositions(string email, int account)
    {
        using var connection = new SQLiteConnection(_connectionString);
        string sql = @"
            SELECT position_id, email, account, +1 AS change, command, symbol, lots FROM historical_positions 
            WHERE email = @email AND account = @account AND delete_at IS NULL
            UNION
            SELECT position_id, email, account, -1 AS change, command, symbol, lots FROM positions 
            WHERE email = @email AND account = @account AND create_at IS NULL";
        return connection.Query<Position>(sql, new { email = email, account = account }).ToList();
    }

    /// <summary>
    /// 指定したemailとaccountでレコードを論理削除する
    /// </summary>
    public void EntryPosition(string position_id, string create_at)
    {
        using var connection = new SQLiteConnection(_connectionString);
        string sql = @"
            UPDATE positions SET create_at = @create_at
            WHERE position_id = @position_id";
        connection.Execute(sql, new { position_id = position_id });
    }

    /// <summary>
    /// 指定したemailとaccountでレコードを論理削除する
    /// </summary>
    public void ExitPosition(string position_id, string delete_at)
    {
        using var connection = new SQLiteConnection(_connectionString);
        string sql = @"
            UPDATE historical_positions SET delete_at = @delete_at
            WHERE position_id = @position_id";
        connection.Execute(sql, new { position_id = position_id, delete_at = delete_at });
    }
}
