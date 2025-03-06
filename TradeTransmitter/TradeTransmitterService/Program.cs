using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;
using Microsoft.AspNetCore.Http;

using System.Text.Json;
using System.Net.Http;
using System.Runtime.InteropServices;
using System.Diagnostics;

const string RESET = Installer.RESET;
const string GREEN = Installer.GREEN;
const string YELLOW = Installer.YELLOW;
const string RED = Installer.RED;

string GetTimestamp() => Installer.GetTimestamp();
string lastTimestamp = GetTimestamp();

Installer.SetupFirewallRule();

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
var app = builder.Build();

var positionDao = new PositionDao();

// 例1: GET "/helthcheck"
app.MapGet("/helthcheck", () => "ok");

// 例2: GET "/push"
app.MapGet("/push", (HttpRequest request) => {
    lock (positionDao)
    {
        try
        {
            var email = request.Query["email"].ToString();
            var position_id = request.Query["position_id"].ToString();
            if (positionDao.ExistPosition(email, position_id))
            {
                return;
            }
            var account = int.Parse(request.Query["account"].ToString());
            var change = int.Parse(request.Query["change"].ToString());
            var command = int.Parse(request.Query["command"].ToString());
            var symbol = request.Query["symbol"].ToString();
            var lots = double.Parse(request.Query["lots"].ToString());
            if (change != +1 && change != -1)
            {
                throw new Exception($"changeは+1か-1のみ許可されています: {change}");
            }
            if (command != +1 && command != -1)
            {
                throw new Exception($"commandは+1か-1のみ許可されています: {command}");
            }
            if (lots <= 0)
            {
                throw new Exception($"lotsは0より大きい値のみ許可されています: {lots}");
            }
            if (symbol == null)
            {
                throw new Exception("symbolは必須です");
            }

            lastTimestamp = GetTimestamp();
            var position = new Position { email = email, account = account, change = change, command = command, symbol = symbol, lots = lots, position_id = position_id, create_at = lastTimestamp };
            var Change = position.change == +1 ? "[Entry]," : "[Exit], ";
            var Command = position.command == +1 ? "[Buy], " : "[Sell],";
            string message = $"生徒さん[{email}], 口座番号[{account}], 売買{Change} ポジション{Command} 通貨ペア[{position.symbol}], 売買ロット[{position.lots:F2}], ポジション識別子[{position.position_id}]";
            if (change == +1)
            {
                Logger.Log(Color.YELLOW, $"[{lastTimestamp}] ≫≫≫≫≫ {message}");
            }
            else
            {
                Logger.Log(Color.YELLOW, $"[{lastTimestamp}] ≪≪≪≪≪ {message}");
            }
            positionDao.InsertPosition(position);
        }
        catch (Exception ex)
        {
            Logger.Log(Color.RED, $"[{lastTimestamp}] ########## {ex}");
            Logger.Log(Color.RED, $"[{lastTimestamp}] ########## {request.QueryString}");
        }
    }
});

// 例3: POST "/pull"
app.MapGet("/pull", (HttpRequest request) =>
{
    lock (positionDao)
    {
        var lines = string.Empty;
        try
        {
            var email = request.Query["email"].ToString();
            var account = int.Parse(request.Query["account"].ToString());
            while (positionDao.GetPositions(email, out var position))
            {
                lastTimestamp = GetTimestamp();
                var change = position.change == +1 ? "Entry" : "Exit";
                var command = position.command == +1 ? "Buy" : "Sell";
                var line = $"{email},{account},{change},{command},{position.symbol},{position.lots},{position.position_id}\n";
                lines += line;
                var Change = position.change == +1 ? "[Entry]," : "[Exit], ";
                var Command = position.command == +1 ? "[Buy], " : "[Sell],";
                string message = $"生徒さん[{email}], 口座番号[{account}], 売買{Change} ポジション{Command} 通貨ペア[{position.symbol}], 売買ロット[{position.lots:F2}], ポジション識別子[{position.position_id}]";
                if (position.change == +1)
                {
                    Logger.Log(Color.GREEN, $"[{lastTimestamp}] ≫≫≫≫≫ {message}");
                }
                else
                {
                    Logger.Log(Color.GREEN, $"[{lastTimestamp}] ≪≪≪≪≪ {message}");
                }
            }
        }
        catch (Exception ex)
        {
            Logger.Log(Color.RED, $"[{lastTimestamp}] ########## {ex}");
            Logger.Log(Color.RED, $"[{lastTimestamp}] ########## {request.QueryString}");
        }
        return Results.Text(lines, "text/csv; charset=utf-8");
    }
});

app.Run();
