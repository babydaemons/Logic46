namespace TradeTransmitter;

public class PositionRequestModel
{
    public string? Change { get; set; }
    public string? Command { get; set; }
    public string? Symbol { get; set; }
    public double Lots { get; set; }
    public ulong MagicNumber { get; set; }
    public string? PositionId { get; set; }
}
