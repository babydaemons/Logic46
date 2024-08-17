namespace TradeTransmitter;

public class TradeRequestModel
{
    public string? BrokerName { get; set; }
    public ulong AccountNumber { get; set; }
    public string? Symbol { get; set; }
    public string? TradeType { get; set; }
    public double Lots { get; set; }
    public double Price { get; set; }
    public ulong Ticket { get; set; }
}
