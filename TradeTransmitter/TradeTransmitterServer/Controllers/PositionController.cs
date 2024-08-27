using Microsoft.AspNetCore.Mvc;
using System.Collections.Concurrent;
namespace TradeTransmitter;

[ApiController]
[Route("api/[controller]")]
public class PositionController : ControllerBase
{
    private static ConcurrentQueue<PositionRequestModel> AllPositions = new();

    [HttpGet("{change}/{command}/{symbol}/{lots}/{magic}/{position_id}")]
    public IActionResult SubmitData(string change, string command, string symbol, double lots, ulong magic, string position_id)
    {
        var position = new PositionRequestModel
        {
            Change = change,
            Command = command,
            Symbol = symbol,
            Lots = lots,
            MagicNumber = magic,
            PositionId = position_id
        };

        AllPositions.Enqueue(position);
        var request = $"{position.Change},{position.Command},{position.Symbol},{position.Lots},{position.MagicNumber},{position.PositionId}";
        System.Console.Error.WriteLine($">>>>>>>>>> {request}");
        return Ok(request);
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
                var request = $"{position.Change},{position.Command},{position.Symbol},{position.Lots},{position.MagicNumber},{position.PositionId}";
                System.Console.Error.WriteLine($"<<<<<<<<<< {request}");
                records += $"{request}\n";
            }
        }
        return records;
    }

    public static void StopPolling()
    {
        AllPositions.Clear();
    }
}
