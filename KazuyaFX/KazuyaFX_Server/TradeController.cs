using System.Collections.Concurrent;
using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/trade")]
public class TradeController : ControllerBase
{
    private static DateTime startAt = DateTime.Now;
    private static Stopwatch stopwatch = Stopwatch.StartNew();
    public static string Timestamp => (startAt + stopwatch.Elapsed).ToString("yyyy-MM-dd HH:mm:ss.fffffff");

    private ConcurrentDictionary<string, string> _positionIds = new ConcurrentDictionary<string, string>();
    private PositionDao _positionDao = new PositionDao();

    /// <summary>
    /// ヘルスチェック用のエンドポイント。
    /// サーバーの正常稼働を確認する。
    /// </summary>
    /// <returns>サーバーステータスのメッセージ</returns>
    /// <remarks>
    /// GET /api/healthcheck
    /// </remarks>
    [HttpGet("healthcheck")]
    public IActionResult HealthCheck()
    {
        return Ok("KazuyaFX_Server: OK");
    }

    /// <summary>
    /// 生徒のトレード情報を受信し、データベースに記録する。
    /// </summary>
    /// <param name="email">生徒のメールアドレス</param>
    /// <param name="account">生徒の口座番号</param>
    /// <param name="entry">エントリー情報（1: エントリー, 0: エグジット）</param>
    /// <param name="buy">売買情報（1: 買い, 0: 売り）</param>
    /// <param name="symbol">取引通貨ペア</param>
    /// <param name="lots">ロット数</param>
    /// <param name="command">コマンド</param>
    /// <param name="position_id">ポジション識別子</param>
    /// <returns>発行されたポジションID</returns>
    /// <remarks>
    /// GET /api/student?email={email}&account={account}&entry={entry}&buy={buy}&symbol={symbol}&lots={lots}&command={command}&position_id={position_id}
    /// </remarks>
    [HttpGet("student")]
    public async Task<IActionResult> Student([FromQuery] string email, [FromQuery] int account, [FromQuery] int entry, [FromQuery] int buy, [FromQuery] string symbol, [FromQuery] double lots, [FromQuery] int command, [FromQuery] string position_id)
    {
        if (_positionDao.ExistPosition(email, position_id))
        {
            return NoContent();
        }

        var position = new Position { email = email, account = account, entry = entry, buy = buy, symbol = symbol, lots = lots, position_id = position_id };
        _positionDao.InsertPosition(position);
        Console.WriteLine($"Received trade for {email}: {symbol} {lots} lots");

        string issuedPositionId = await WaitForPositionId(email);
        return Ok(issuedPositionId);
    }

    /// <summary>
    /// 先生が生徒のトレード状況を取得する。
    /// </summary>
    /// <param name="email">先生のメールアドレス</param>
    /// <param name="position_id">ポジション識別子（任意）</param>
    /// <returns>ポジション情報のCSVデータ</returns>
    /// <remarks>
    /// GET /api/teacher?email={email}&position_id={position_id}
    /// </remarks>
    [HttpGet("teacher")]
    public IActionResult Teacher([FromQuery] string email, [FromQuery] string position_id)
    {
        var lines = string.Empty;
        if (string.IsNullOrEmpty(position_id))
        {
            var positions = _positionDao.GetPositions(email);
            foreach (var position in positions)
            {
                var line = $"{email},{position.account},{position.entry},{position.buy},{position.symbol},{position.lots},{position.position_id}\n";
                lines += line;
            }
        }
        else
        {
            _positionIds[email] = position_id;
        }
        return Results.Text(lines, "text/csv; charset=utf-8");
    }

    /// <summary>
    /// ポジションIDを非同期で待機する。
    /// </summary>
    /// <param name="email">メールアドレス</param>
    /// <returns>ポジションID</returns>
    private async Task<string> WaitForPositionId(string email)
    {
        for (int i = 0; i < 1000; i++) // 最大10秒待機 (10 * 1000ms)
        {
            if (_positionIds.TryRemove(email, out var positionId))
            {
                return positionId;
            }
            await Task.Delay(10);
        }
        return "########################";
    }
}
