using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;
using Microsoft.AspNetCore.Http;

using System.Text.Json;
using System.Net.Http;
using System.Runtime.InteropServices;

const string ESCAPE = "\x1b";
const string RESET = ESCAPE + "[0m";
const string GREEN = ESCAPE + "[32m";
const string YELLOW = ESCAPE + "[33m";

string GetTimestamp() => DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
var app = builder.Build();

var positionDao = new PositionDao(@"C:\TradeTransmitterService\TradeTransmitterService.sqlite3");

// 例1: GET "/"
app.MapGet("/", () => "ok");

// 例2: GET "/push"
app.MapGet("/push", (HttpRequest request) => {
    try
    {
        var email = request.Query["email"].ToString();
        var account = int.Parse(request.Query["account"].ToString());
        var change = int.Parse(request.Query["change"].ToString());
        var command = int.Parse(request.Query["command"].ToString());
        var symbol = request.Query["symbol"].ToString();
        var lots = double.Parse(request.Query["lots"].ToString());
        var position_id = request.Query["position_id"].ToString();
        var created_at = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        positionDao.InsertPosition(new Position { Email = email, Account = account, Change = change, Command = command, Symbol = symbol, Lots = lots, PositionId = position_id, CreateAt = created_at });
        string message = $"生徒さん[{email}], 口座番号[{account}], 売買[{change}], ポジション[{command}], 通貨ペア[{symbol}], 売買ロット[{lots}], ポジション識別子[{position_id}]";
        Console.WriteLine($"{YELLOW}[{created_at}]≫≫≫≫≫ {message}{RESET}");
    }
    catch (Exception)
    {
    }
});

// 例3: POST "/pull"
app.MapGet("/pull", (HttpContext request) =>
{
    var lines = string.Empty;
    try
    {
        var email = request.Request.Query["email"].ToString();
        var account = int.Parse(request.Request.Query["account"].ToString());
        var positions = positionDao.GetPositions(email, account);
        foreach (var position in positions)
        {
            var line = $"{position.Change},{position.Command},{position.Symbol},{position.Lots},{position.PositionId}\n";
            lines += line;
            string message = $"生徒さん[{email}], 口座番号[{account}], 売買[{position.Change}], ポジション[{position.Command}], 通貨ペア[{position.Symbol}], 売買ロット[{position.Lots}], ポジション識別子[{position.PositionId}]";
            Console.WriteLine($"{GREEN}[{GetTimestamp()}]≪≪≪≪≪ {message}{RESET}");
        }
    }
    catch (Exception)
    {
    }
    return Results.Text(lines, "text/csv; charset=utf-8");
});

app.Run();
