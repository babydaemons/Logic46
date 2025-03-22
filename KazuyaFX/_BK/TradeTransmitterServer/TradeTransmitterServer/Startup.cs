namespace TradeTransmitter;

public class Startup
{
    // サービスを追加するメソッド
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllers();
        // 他のサービスを追加
    }

    // HTTPリクエストパイプラインを構成するメソッド
    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        if (env.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
        }
        else
        {
            app.UseExceptionHandler("/Home/Error");
            app.UseHsts();
        }

        app.UseHttpsRedirection();
        app.UseStaticFiles();

        app.UseRouting();

        app.UseAuthorization();

        app.UseEndpoints(endpoints =>
        {
            endpoints.MapControllers();
        });
    }
}
