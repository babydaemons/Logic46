using Microsoft.AspNetCore.Mvc;
namespace TradeTransmitter;

[ApiController]
public class HomeController : ControllerBase
{
    // http://localhost/ �ɃA�N�Z�X�����Ƃ��ɂ��̃��\�b�h���Ă΂��
    [HttpGet("/")]
    public IActionResult Index()
    {
        return Ok("Welcome to the Home Page!");
    }
}
