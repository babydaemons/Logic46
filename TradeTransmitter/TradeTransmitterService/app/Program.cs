using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;
using Microsoft.AspNetCore.Http;

using System.Text.Json;
using System.Net.Http;
using System.Runtime.InteropServices;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
var app = builder.Build();

var positions = new Positions(@"C:\TradeTransmitterService\TradeTransmitterService.json");

// 例1: GET "/"
app.MapGet("/", () => "ok");

// 例2: GET "/push"
app.MapGet("/push", (HttpRequest request) => {
    var email = request.Query["email"].ToString();
    var account = uint.Parse(request.Query["account"].ToString());
    var change = int.Parse(request.Query["change"].ToString());
    var command = int.Parse(request.Query["command"].ToString());
    var symbol = request.Query["symbol"].ToString();
    var lots = double.Parse(request.Query["lots"].ToString());
    var position_id = request.Query["position_id"].ToString();
    positions.AddPosition(email, account, new Position { change = change, command = command, symbol = symbol, lots = lots, position_id = position_id });
    Console.WriteLine($"▷▷▷▷▷▷ 生徒さん[{email}], 口座番号[{account}], 売買[{change}], ポジション[{command}], 通貨ペア[{symbol}], 売買ロット[{lots}], ポジション識別子[{position_id}]");
});

// 例3: POST "/pull"
app.MapGet("/pull", (HttpContext request) =>
{
    var email = request.Request.Query["email"].ToString();
    var account = uint.Parse(request.Request.Query["account"].ToString());
    var fetchedPositions = positions.GetPosition(email, account);
    var lines = string.Empty;
    foreach (var position in fetchedPositions)
    {
        var line = $"{position.change},{position.command},{position.symbol},{position.lots},{position.position_id}\n";
        lines += line;
        Console.WriteLine($"◀◀◀◀◀◀ 生徒さん[{email}], 口座番号[{account}], 売買[{position.change}], ポジション[{position.command}], 通貨ペア[{position.symbol}], 売買ロット[{position.lots}], ポジション識別子[{position.position_id}]");
    }
    return Results.Text(lines, "text/csv; charset=utf-8");
});

app.Run();
