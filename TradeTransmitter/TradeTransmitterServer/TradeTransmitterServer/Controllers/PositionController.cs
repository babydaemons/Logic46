using Microsoft.AspNetCore.Mvc;
using System.Collections.Concurrent;
using System.Text.Json;
namespace TradeTransmitter;

[ApiController]
[Route("api/[controller]")]
public class PositionController : ControllerBase
{
    private static ConcurrentDictionary<string, ConcurrentQueue<PositionRequestModel>> PositionList = new();

    [HttpGet("{brokerSite}/{accountNumber}")]
    public IActionResult SubmitPosition(string brokerSite, string accountNumber, [FromQuery] string trade)
    {
        var json = string.Empty;
        for (var i = 0; i < trade.Length / 2; i++)
        {
            var c1 = trade[2 * i];
            var c0 = trade[2 * i + 1];
            var hex = $"{c1}{c0}";
            var c = (char)Convert.ToInt32(hex, 16);
            json += c;
        }

        try
        {
            var position = JsonSerializer.Deserialize<PositionRequestModel>(json);
            if (position == null)
            {
                Console.Error.WriteLine($">>>>>>>>>> trade is null");
                return ValidationProblem("trade is null");
            }

            var request = $"{brokerSite},{accountNumber},{position.Command},{position.Type},{position.Symbol},{position.Lots},{position.PositionId}";
            var key = $"{brokerSite}/{accountNumber}";
            if (!PositionList.ContainsKey(key))
            {
                PositionList.TryAdd(key, new ConcurrentQueue<PositionRequestModel>());
            }

            if (PositionList.TryGetValue(key, out var positionList))
            {
                positionList.Enqueue(position);
            }

            Console.Error.WriteLine($">>>>>>>>>> {request}");
            return Ok(request);
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($">>>>>>>>>> {ex.Message}");
            return ValidationProblem(ex.Message);
        }
    }

    public static string ExecutePolling(string brokerSite, string accountNumber)
    {
        var key = $"{brokerSite}/{accountNumber}";
        if (PositionList.TryGetValue(key, out var positionList))
        {
            string records = $"{positionList.Count}\n";
            while (!positionList.IsEmpty)
            {
                if (positionList.TryDequeue(out var position))
                {
                    var request = $"{brokerSite},{accountNumber},{position.Command},{position.Type},{position.Symbol},{position.Lots},{position.PositionId}";
                    Console.Error.WriteLine($"<<<<<<<<<< {request}");
                    records += $"{request}\n";
                }
            }
            return records;
        }
        return string.Empty;
    }
}
