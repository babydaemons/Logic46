using Microsoft.AspNetCore.Mvc;
namespace TradeTransmitter;

[ApiController]
public class HomeController : ControllerBase
{
    // http://localhost/ にアクセスしたときにこのメソッドが呼ばれる
    [HttpGet("/")]
    public IActionResult Index()
    {
        return Ok("Welcome to the Home Page!");
    }
}
