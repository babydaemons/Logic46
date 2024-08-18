namespace TradeTransmitter;

public class TradeRequestModel
{
    public string? BrokerName { get; set; }
    public ulong AccountNumber { get; set; }
    public int Change { get; set; }
    public string? Symbol { get; set; }
    public double Lots { get; set; }
    public double Price { get; set; }
    public ulong Ticket { get; set; }
    public ulong MagicNumber { get; set; }
}
