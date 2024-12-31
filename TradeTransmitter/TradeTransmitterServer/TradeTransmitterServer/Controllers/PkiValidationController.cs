using Microsoft.AspNetCore.Mvc;
namespace TradeTransmitter;

[ApiController]
[Route(".well-known/pki-validation")]
public class PkiValidationController : ControllerBase
{
    [HttpGet("{fileName}")]
    public IActionResult Download(string fileName)
    {
        var appDir = Path.GetDirectoryName(Environment.ProcessPath) ?? ".";
        var dir = Path.Combine(appDir, ".well-known");
        dir = Path.Combine(dir, "pki-validation");
        var path = Path.Combine(dir, fileName);
        if (Path.Exists(path))
        {
            var content = string.Empty;
            using (var reader = new StreamReader(path))
            {
                content = reader.ReadToEnd();
            }
            return Ok($"{content}");
        }
        else
        {
            return NotFound();
        }
    }
}
