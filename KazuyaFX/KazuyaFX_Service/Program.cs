using KazuyaFX_Service;

var builder = Host.CreateApplicationBuilder(args);
builder.Services.AddHostedService<ApplicationsControlService>();

var host = builder.Build();
host.Run();
