using System.Collections.Concurrent;
using Microsoft.AspNetCore.Mvc;
namespace TradeTransmitter;

[ApiController]
[Route("api/[controller]")]
public class PollingController : ControllerBase
{
    [HttpGet("start")]
    public IActionResult StartPolling()
    {
        PositionController.StartPolling();
        return Ok("started");
    }

    [HttpGet("execute")]
    public IActionResult ExecutePolling()
    {
        string records = PositionController.ExecutePolling();
        return Ok($"{records}");
    }

    [HttpGet("stop")]
    public IActionResult StopPolling()
    {
        PositionController.StopPolling();
        return Ok("stopped");
    }
}
