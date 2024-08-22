using Microsoft.AspNetCore.Mvc;
using System.Collections.Concurrent;
namespace TradeTransmitter;

[ApiController]
[Route("api/[controller]")]
public class PositionController : ControllerBase
{
    private static ConcurrentQueue<PositionRequestModel> AllPositions = new();

    [HttpPost("submit")]
    public IActionResult SubmitData([FromBody] TradeRequestModel request)
    {
        if (request == null)
        {
            return BadRequest("Invalid data.");
        }
        if (request.Positions == null)
        {
            return BadRequest("Invalid data.");
        }

        string result = string.Empty;
        foreach (var position in request.Positions)
        {
            AllPositions.Enqueue(position);
            var command = $"{position.PositionId},{position.Change},{position.Symbol},{position.Lots},{position.MagicNumber}";
            System.Console.Error.WriteLine($">>>>>>>>>> {command}");
            result += $"{command}\n";
        }
        return Ok($"{result}");
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
                var command = $"{position.PositionId},{position.Change},{position.Symbol},{position.Lots},{position.MagicNumber}";
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
