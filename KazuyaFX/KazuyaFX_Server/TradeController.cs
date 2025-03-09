using System.Collections.Concurrent;
using System.Diagnostics;
using System.Security.Principal;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api")]
public class TradeController : ControllerBase
{
    private static DateTime startAt = DateTime.Now;
    private static Stopwatch stopwatch = Stopwatch.StartNew();
    public static string Timestamp => (startAt + stopwatch.Elapsed).ToString("yyyy-MM-dd HH:mm:ss.fffffff");

    private ConcurrentDictionary<string, string> _positionIds = new ConcurrentDictionary<string, string>();

    private PositionDao _positionDao = new PositionDao();

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
        var Change = position.entry == +1 ? "[Entry]," : "[Exit], ";
        var Command = position.buy == +1 ? "[Buy], " : "[Sell],";
        string message = $"生徒さん[{email}], 口座番号[{account}], 売買{Change} ポジション{Command} 通貨ペア[{position.symbol}], 売買ロット[{position.lots:F2}], ポジション識別子[{position.position_id}]";
        if (entry == +1)
        {
            Logger.Log(Color.YELLOW, $"[{Timestamp}] >>>>>>>>>> {message}");
        }
        else
        {
            Logger.Log(Color.YELLOW, $"[{Timestamp}] <<<<<<<<<< {message}");
        }
        string issuedPositionId = await WaitForPositionId(email);
        return Ok(issuedPositionId);
    }

    [HttpGet("teacher")]
    public IActionResult Teacher([FromQuery] string email, [FromQuery] string position_id)
    {
        var lines = string.Empty;
        if (string.IsNullOrEmpty(position_id))
        {
            var positions = _positionDao.GetPositions(email);
            foreach (var position in positions)
            {
                var entry = position.entry == +1 ? "Entry" : "Exit";
                var buy = position.buy == +1 ? "Buy" : "Sell";
                var line = $"{email},{position.account},{position.entry},{position.buy},{position.symbol},{position.lots},{position.position_id}\n";
                lines += line;

                var Entry = position.entry == +1 ? "[Entry]," : "[Exit], ";
                var Buy = position.buy == +1 ? "[Buy], " : "[Sell],";
                string message = $"生徒さん[{email}], 口座番号[{position.account}], 売買{Entry} ポジション{Buy} 通貨ペア[{position.symbol}], 売買ロット[{position.lots:F2}], ポジション識別子[{position.position_id}]";
                if (position.entry == +1)
                {
                    Logger.Log(Color.GREEN, $"[{Timestamp}] >>>>>>>>>> {message}");
                }
                else
                {
                    Logger.Log(Color.GREEN, $"[{Timestamp}] <<<<<<<<<< {message}");
                }
            }
        }
        else
        {
            _positionIds[email] = position_id;
            Logger.Log(Color.CYAN, $"[{Timestamp}] ========== 先生がチケット番号[{position_id}]を受け取りました。");
        }
        return (IActionResult)Results.Text(lines, "text/csv; charset=utf-8");
    }

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
