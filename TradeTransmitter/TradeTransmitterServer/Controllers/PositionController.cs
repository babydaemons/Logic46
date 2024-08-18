using Microsoft.AspNetCore.Mvc;
using System.Collections.Concurrent;
namespace TradeTransmitter;

[ApiController]
[Route("api/[controller]")]
public class PositionController : ControllerBase
{
    private static ConcurrentQueue<TradeRequestModel> AllPositions = new();

    [HttpPost("submit")]
    public IActionResult SubmitData([FromBody] TradeRequestModel position)
    {
        if (position == null)
        {
            return BadRequest("Invalid data.");
        }

        AllPositions.Enqueue(position);
        var command = $"{position.BrokerName},{position.AccountNumber},{position.Change},{position.Symbol},{position.Lots},{position.Ticket},{position.MagicNumber}";
        System.Console.Error.WriteLine($">>>>>>>>>> {command}");
        return Ok($"{command}");
    }

    public static void StartPolling()
    {
        AllPositions.Clear();
    }

    public static string ExecutePolling()
    {
        string records = $"{AllPositions.Count}\n";
        while (!AllPositions.IsEmpty)
        {
            if (AllPositions.TryDequeue(out var position))
            {
                var command = $"{position.BrokerName},{position.AccountNumber},{position.Change},{position.Symbol},{position.Lots},{position.Ticket},{position.MagicNumber}";
                System.Console.Error.WriteLine($"<<<<<<<<<< {command}");
                records += $"{command}\n";
            }
        }
        return records;
    }

    public static void StopPolling()
    {
        AllPositions.Clear();
    }
}
