using KazuyaFX_Service;

var builder = Host.CreateApplicationBuilder(args);

// appsettings.json の "Applications" セクションを読み込み
var appPaths = builder.Configuration.GetSection("Applications").Get<string[]>();

if (appPaths == null || appPaths.Length == 0)
{
    throw new InvalidOperationException("アプリケーションのパスが設定されていません。appsettings.json を確認してください。");
}

// 各アプリに対応する ApplicationControlService を動的に登録
foreach (var appPath in appPaths)
{
    builder.Services.AddSingleton<IHostedService>(provider =>
    {
        var logger = provider.GetRequiredService<ILogger<ApplicationControlService>>();
        return new ApplicationControlService(logger, appPath);
    });
}

var host = builder.Build();
host.Run();
