using Microsoft.AspNetCore.Mvc;
namespace TradeTransmitter;

[ApiController]
[Route("api/[controller]")]
public class PollingController : ControllerBase
{
    [HttpGet("{brokerSite}/{accountNumber}")]
    public IActionResult ExecutePolling(string brokerSite, string accountNumber)
    {
        var records = PositionController.ExecutePolling(brokerSite, accountNumber);
        return Ok($"{records}");
    }
}
