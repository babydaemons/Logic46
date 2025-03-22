namespace TradeTransmitter;

public class PositionRequestModel
{
    public string? Command { get; set; }
    public string? Type { get; set; }
    public string? Symbol { get; set; }
    public double Lots { get; set; }
    public string? PositionId { get; set; }
}
