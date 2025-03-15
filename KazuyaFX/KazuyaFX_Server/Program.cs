using System.Collections.Concurrent;
using System.Diagnostics;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<PositionDao>();
var app = builder.Build();

ConcurrentDictionary<string, string> tickets = new();
ConcurrentDictionary<string, int> busyFlags = new();

/// <summary>
/// ヘルスチェック用のエンドポイント。
/// サーバーの正常稼働を確認する。
/// </summary>
/// <remarks>
/// GET /api/healthcheck
/// </remarks>
app.MapGet("/api/check", () => Results.Text("KazuyaFX_Server: OK"));

/// <summary>
/// 生徒のトレード情報を受信し、データベースに記録する。
/// </summary>
/// <remarks>
/// GET /api/student?email={email}&account={account}&entry={entry}&buy={buy}&symbol={symbol}&lots={lots}&command={command}&position_id={position_id}
/// </remarks>
app.MapGet("/api/student", async ([FromServices] PositionDao positionDao, HttpContext context) =>
{
    var email = context.Request.Query["email"];
    var positionId = context.Request.Query["position_id"];

    if (positionDao.ExistPosition(email!, positionId!))
    {
        // すでに同じポジションIDが存在する場合は、何もしない。
        return Results.Text("ok");
    }

    var position = new Position
    {
        email = email!,
        account = int.TryParse(context.Request.Query["account"], out var a) ? a : 0,
        entry = int.TryParse(context.Request.Query["entry"], out var e) ? e : 0,
        buy = int.TryParse(context.Request.Query["buy"], out var b) ? b : 0,
        symbol = context.Request.Query["symbol"]!,
        lots = double.TryParse(context.Request.Query["lots"], out var l) ? l : 0,
        position_id = positionId!
    };
    positionDao.InsertPosition(position);

    var Entry = position.entry == +1 ? "[Entry]," : "[Exit], ";
    var Buy = position.buy == +1 ? "[Buy], " : "[Sell],";
    var message = $"生徒さん[{email}], 口座番号[{position.account}], 売買{Entry} ポジション{Buy} 通貨ペア[{position.symbol}], 売買ロット[{position.lots:F2}], ポジションID[{position.position_id}]";
    Logger.Log(Color.YELLOW, position.entry == +1 ? $">>>>>>>>>> {message}" : $"<<<<<<<<<< {message}");

    return Results.Text(await WaitForPositionId(email!));
});

/// <summary>
/// 先生が生徒のトレード状況を取得する。
/// </summary>
/// <remarks>
/// GET /api/teacher?email={email}&ticket={ticket}
/// </remarks>
app.MapGet("/api/teacher", (HttpContext context, PositionDao positionDao) =>
{
    var email = context.Request.Query["email"];
    var ticket = context.Request.Query["ticket"];

    if (busyFlags.ContainsKey(email!))
    {
        return Results.Text("", "text/csv; charset=utf-8");
    }

    busyFlags.TryAdd(email!, 1);
    if (!string.IsNullOrEmpty(ticket))
    {
        // チケット番号が渡されたら、生徒側に返すために保存しておく。
        tickets[email!] = ticket!;
        return Results.Text("ok");
    }

    var positions = positionDao.GetPositions(email!);
    string lines = string.Join("\n", positions.Select(p => $"\"{email}\",\"{p.account}\",\"{p.entry}\",\"{p.buy}\",\"{p.symbol}\",\"{p.lots}\",\"{p.position_id}\""));

    try
    {
        foreach (var position in positions)
        {
            var entry = position.entry == +1 ? "Entry" : "Exit";
            var buy = position.buy == +1 ? "Buy" : "Sell";
            var line = $"{email},{position.account},{entry},{buy},{position.symbol},{position.lots},{position.position_id}\n";
            lines += line;
            var Entry = position.entry == +1 ? "[Entry]," : "[Exit], ";
            var Buy = position.buy == +1 ? "[Buy], " : "[Sell],";
            string message = $"生徒さん[{email}], 口座番号[{position.account}], 売買{Entry} ポジション{Buy} 通貨ペア[{position.symbol}], 売買ロット[{position.lots:F2}], ポジションID[{position.position_id}]";
            if (position.entry == +1)
            {
                Logger.Log(Color.GREEN, $">>>>>>>>>> {message}");
            }
            else
            {
                Logger.Log(Color.GREEN, $"<<<<<<<<<< {message}");
            }
        }
    }
    catch (Exception ex)
    {
        Logger.Log(Color.RED, $"!!!!!!!!!! {ex}");
        Logger.Log(Color.RED, $"!!!!!!!!!! {context.Request.QueryString}");
    }

    busyFlags.Remove(email!, out var flag);
    return Results.Text(lines, "text/csv; charset=utf-8");
});

/// <summary>
/// ポジションIDを非同期で待機する。
/// </summary>
async Task<string> WaitForPositionId(string email)
{
    for (int i = 0; i < 1000; i++)
    {
        if (tickets.TryRemove(email, out var ticket))
        {
            return ticket;
        }
        await Task.Delay(10);
    }
    return "!!!!!!!!!!!!";
}

app.Run();
