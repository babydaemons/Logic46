﻿using System.Collections.Concurrent;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System.Diagnostics;

var builder = WebApplication.CreateBuilder(new WebApplicationOptions
{
    Args = args,
    ContentRootPath = AppContext.BaseDirectory
});

// 設定取得
var config = builder.Configuration;
bool runAsService = config.GetValue<bool>("RunAsService");

// RunAsService が true のときだけ Windowsサービスとして登録
if (runAsService)
{
    builder.Host.UseWindowsService();
}

// nginx または指定アプリを起動する HostedService を追加
builder.Services.AddHostedService<ApplicationHostedService>();
builder.Services.AddSingleton<PositionDao>();

var app = builder.Build();

ConcurrentDictionary<string, int> entryPositionIdList = new();
ConcurrentDictionary<string, int> exitPositionIdList = new();
ConcurrentDictionary<string, int> teacherBusyFlags = new();

Logger.Log(Color.CYAN, "先生用 MetaTrader4 トレード受信サーバーが起動しました...");

/// <summary>
/// ヘルスチェック用のエンドポイント。
/// サーバーの正常稼働を確認する。
/// </summary>
/// <remarks>
/// GET /api/check
/// </remarks>
app.MapGet("/api/check", () => Results.Text("KazuyaFX_Server: OK"));

/// <summary>
/// 生徒のトレード情報を受信し、データベースに記録する。
/// </summary>
/// <remarks>
/// GET /api/student?email={email}&account={account}&entry={entry}&buy={buy}&symbol={symbol}&lots={lots}&command={command}&position_id={position_id}
/// </remarks>
app.MapGet("/api/student", ([FromServices] PositionDao positionDao, HttpContext context) =>
{
    lock (positionDao)
    {
        var email = context.Request.Query["email"];
        var positionId = context.Request.Query["position_id"];

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

        if (position.entry == 1)
        {
            if (entryPositionIdList.ContainsKey(position.position_id))
            {
                // すでに同じポジションIDが存在する場合は、何もしない。
                return Results.Text("ok");
            }
            else
            {
                entryPositionIdList.TryAdd(positionId!, 1);
            }
        }
        else
        {
            if (exitPositionIdList.ContainsKey(position.position_id))
            {
                // すでに同じポジションIDが存在する場合は、何もしない。
                return Results.Text("ok");
            }
            else
            {
                exitPositionIdList.TryAdd(positionId!, 1);
            }
        }

        positionDao.InsertPosition(position);

        var Entry = position.entry == +1 ? "[Entry]," : "[Exit], ";
        var Buy = position.buy == +1 ? "[Buy], " : "[Sell],";
        var message = $"生徒さん[{email}], 口座番号[{position.account}], 売買{Entry} ポジション{Buy} 通貨ペア[{position.symbol}], 売買ロット[{position.lots:F2}], ポジションID[{position.position_id}]";
        Logger.Log(Color.YELLOW, position.entry == +1 ? $">>>>>>>>>> {message}" : $"<<<<<<<<<< {message}");

        return Results.Text("ok");
    }
});

/// <summary>
/// 先生が生徒のトレード状況を取得する。
/// </summary>
/// <remarks>
/// GET /api/teacher?email={email}
/// </remarks>
app.MapGet("/api/teacher", (HttpContext context, PositionDao positionDao) =>
{
    var email = context.Request.Query["email"];

    if (teacherBusyFlags.ContainsKey(email!))
    {
        return Results.Text("", "text/csv; charset=utf-8");
    }
    else
    {
        teacherBusyFlags.TryAdd(email!, 1);
    }

    string lines = string.Empty;

    try
    {
        while (positionDao.GetPosition(email!, out var position))
        {
            var entry = position.entry == +1 ? "Entry" : "Exit";
            var buy = position.buy == +1 ? "Buy" : "Sell";
            var line = $"\"{email}\",\"{position.account}\",\"{position.entry}\",\"{position.buy}\",\"{position.symbol}\",\"{position.lots}\",\"{position.position_id}\"\n";
            lines += line;
            var Entry = position.entry == +1 ? "[Entry]," : "[Exit], ";
            var Buy = position.buy == +1 ? "[Buy], " : "[Sell],";
            string message = $"生徒さん[{email}], 口座番号[{position.account}], 売買{Entry} ポジション{Buy} 通貨ペア[{position.symbol}], 売買ロット[{position.lots:F2}], ポジションID[{position.position_id}]";
            Logger.Log(Color.GREEN, position.entry == +1 ? $">>>>>>>>>> {message}" : $"<<<<<<<<<< {message}");
        }
    }
    catch (Exception ex)
    {
        Logger.Log(Color.RED, $"!!!!!!!!!! {ex}");
        Logger.Log(Color.RED, $"!!!!!!!!!! {context.Request.QueryString}");
    }

    teacherBusyFlags.Remove(email!, out var _);
    return Results.Text(lines, "text/csv; charset=utf-8");
});

app.Run();
