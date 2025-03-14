using System.Collections.Concurrent;
using System.Diagnostics;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using System.Threading.Tasks;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<PositionDao>();
var app = builder.Build();

ConcurrentDictionary<string, string> positionIds = new();
DateTime startAt = DateTime.Now;
Stopwatch stopwatch = Stopwatch.StartNew();
string Timestamp => (startAt + stopwatch.Elapsed).ToString("yyyy-MM-dd HH:mm:ss.fffffff");

/// <summary>
/// ヘルスチェック用のエンドポイント。
/// サーバーの正常稼働を確認する。
/// </summary>
/// <remarks>
/// GET /api/trade/healthcheck
/// </remarks>
app.MapGet("/api/trade/healthcheck", () => Results.Ok("KazuyaFX_Server: OK"));

/// <summary>
/// 生徒のトレード情報を受信し、データベースに記録する。
/// </summary>
/// <remarks>
/// GET /api/trade/student?email={email}&account={account}&entry={entry}&buy={buy}&symbol={symbol}&lots={lots}&command={command}&position_id={position_id}
/// </remarks>
app.MapGet("/api/trade/student", async (HttpContext context, PositionDao positionDao) =>
{
    var email = context.Request.Query["email"];
    var positionId = context.Request.Query["position_id"];

    if (positionDao.ExistPosition(email!, positionId!))
        return Results.NoContent();

    var position = new Position
    {
        email = email!,
        account = int.Parse(context.Request.Query["account"]),
        entry = int.Parse(context.Request.Query["entry"]),
        buy = int.Parse(context.Request.Query["buy"]),
        symbol = context.Request.Query["symbol"]!,
        lots = double.Parse(context.Request.Query["lots"]),
        position_id = positionId!
    };
    positionDao.InsertPosition(position);

    return Results.Ok(await WaitForPositionId(email!));
});

/// <summary>
/// 先生が生徒のトレード状況を取得する。
/// </summary>
/// <remarks>
/// GET /api/trade/teacher?email={email}&position_id={position_id}
/// </remarks>
app.MapGet("/api/trade/teacher", (HttpContext context, PositionDao positionDao) =>
{
    var email = context.Request.Query["email"];
    var positionId = context.Request.Query["position_id"];

    if (!string.IsNullOrEmpty(positionId))
    {
        positionIds[email!] = positionId!;
        return Results.Ok();
    }

    var positions = positionDao.GetPositions(email!);
    string lines = string.Join("\n", positions.Select(p => $"{email},{p.account},{p.entry},{p.buy},{p.symbol},{p.lots},{p.position_id}"));
    return Results.Text(lines, "text/csv; charset=utf-8");
});

/// <summary>
/// ポジションIDを非同期で待機する。
/// </summary>
async Task<string> WaitForPositionId(string email)
{
    for (int i = 0; i < 1000; i++)
    {
        if (positionIds.TryRemove(email, out var positionId))
            return positionId;
        await Task.Delay(10);
    }
    return "########################";
}

app.Run();
