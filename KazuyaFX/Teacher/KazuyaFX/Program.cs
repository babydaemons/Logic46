﻿using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
﻿using System.Collections.Concurrent;
using System.Diagnostics;
using System.Text;

// 追加：Shift_JISなどを使う準備
Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
var SJIS = Encoding.GetEncoding("shift_jis");

var positionDao = new PositionDao();

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

// 証明書を更新する HostedService を追加
builder.Services.AddHostedService<CertificateRenewService>();
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
/// GET /api/student?name={name}&account={account}&entry={entry}&buy={buy}&symbol={symbol}&lots={lots}&command={command}&position_id={position_id}
/// </remarks>
app.MapGet("/api/student", (HttpContext context) =>
{
    if (context.Request.Query.ContainsKey("check"))
    {
        return Results.Text("ready");
    }
    else
    {
        return Results.Text("error");
    }
});

/// <summary>
/// 生徒のトレード情報を受信し、データベースに記録する（POST）。
/// </summary>
/// <remarks>
/// POST /api/student
/// Body (application/json):
/// {
///   "name": "Taro",
///   "entry": 1,
///   "buy": 1,
///   "symbol": "USDJPY",
///   "lots": 0.1,
///   "ticket": 123456
/// }
/// </remarks>
app.MapPost("/api/student", async (HttpContext context) =>
{
    // StreamReader のエンコーディングを明示
    var csvLine = string.Empty;
    try
    {
        csvLine = await new StreamReader(context.Request.Body, Encoding.UTF8).ReadToEndAsync();
    }
    catch (Exception ex)
    {
        // エンコーディングの問題で読み込みに失敗した場合
        return Results.Text($"Invalid CSV format: {ex}");
    }

    if (string.IsNullOrWhiteSpace(csvLine))
        return Results.Text("Empty CSV");

    string[] fields = csvLine.Replace("\0", "").Split(',');

    if (fields.Length != 6)
        return Results.Text("Invalid CSV format");

    var position = new Position
    {
        name = fields[0],
        entry = int.TryParse(fields[1], out var e) ? e : 0,
        buy = int.TryParse(fields[2], out var b) ? b : 0,
        symbol = fields[3],
        lots = double.TryParse(fields[4], out var l) ? l : 0,
        ticket = int.TryParse(fields[5], out var t) ? t : 0,
    };

    string positionId = $"{position.name}-{position.ticket}";
    if (position.entry == 1)
    {
        if (entryPositionIdList.ContainsKey(positionId))
        {
            return Results.Text("ok");
        }
        else
        {
            entryPositionIdList.TryAdd(positionId, 1);
        }
    }
    else
    {
        if (exitPositionIdList.ContainsKey(positionId))
        {
            return Results.Text("ok");
        }
        else
        {
            exitPositionIdList.TryAdd(positionId, 1);
        }
    }

    positionDao.InsertPosition(position);

    var Entry = position.entry == +1 ? "[Entry]," : "[Exit], ";
    var Buy = position.buy == +1 ? "[Buy], " : "[Sell],";
    var message = $"生徒さん[{position.name}], 売買{Entry} ポジション{Buy} 通貨ペア[{position.symbol}], 売買ロット[{position.lots:F2}], 売買番号[{position.ticket}]";
    Logger.Log(Color.YELLOW, position.entry == +1 ? $">>>>>>>>>> {message}" : $"<<<<<<<<<< {message}");

    return Results.Text("ok");
});

/// <summary>
/// 先生が生徒のトレード状況を取得する。
/// </summary>
/// <remarks>
/// POST /api/teacher
/// Body (application/json):
/// {
///   "names": ["Taro", "Jiro"]
/// }
/// </remarks>
app.MapPost("/api/teacher", async (HttpContext context) =>
{
    // StreamReader のエンコーディングを明示
    var names = string.Empty;
    try
    {
        names = await new StreamReader(context.Request.Body, Encoding.UTF8).ReadToEndAsync();
    }
    catch (Exception ex)
    {
        // エンコーディングの問題で読み込みに失敗した場合
        return Results.Text($"Invalid CSV format: {ex}");
    }

    var name_list = names.ToString().Split(',');
    string lines = string.Empty;

    foreach (var name in name_list)
    {
        //Logger.Log(Color.RED, name);
        if (string.IsNullOrWhiteSpace(name))
        {
            continue; // 空の名前はスキップ
        }
        if (teacherBusyFlags.ContainsKey(name!))
        {
            continue;
        }
        else
        {
            teacherBusyFlags.TryAdd(name!, 1);
        }
        try
        {
            while (positionDao.GetPosition(name!, out var position))
            {
                var entry = position.entry == +1 ? "Entry" : "Exit";
                var buy = position.buy == +1 ? "Buy" : "Sell";
                var line = $"\"{name}\",\"{position.entry}\",\"{position.buy}\",\"{position.symbol}\",\"{position.lots}\",\"{position.ticket}\"\n";
                lines += line;
                var Entry = position.entry == +1 ? "[Entry]," : "[Exit], ";
                var Buy = position.buy == +1 ? "[Buy], " : "[Sell],";
                string message = $"生徒さん[{name}], 売買{Entry} ポジション{Buy} 通貨ペア[{position.symbol}], 売買ロット[{position.lots:F2}], 売買番号[{position.ticket}]";
                Logger.Log(Color.GREEN, position.entry == +1 ? $">>>>>>>>>> {message}" : $"<<<<<<<<<< {message}");
            }
        }
        catch (Exception ex)
        {
            Logger.Log(Color.RED, $"!!!!!!!!!! {ex}");
            Logger.Log(Color.RED, $"!!!!!!!!!! {context.Request.QueryString}");
        }
        teacherBusyFlags.Remove(name!, out var _);
    }

    return Results.Text(lines, "text/csv; charset=utf-8");
});

/// <summary>
/// 先生が死活監視する。
/// </summary>
/// <remarks>
/// GET /api/teacher?chack=1
/// </remarks>
app.MapGet("/api/teacher", (HttpContext context, PositionDao positionDao) =>
{
    return Results.Text("ready");
});

app.Run();
