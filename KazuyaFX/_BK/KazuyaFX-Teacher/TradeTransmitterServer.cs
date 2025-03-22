using System;
using System.Collections.Concurrent;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using MQTTnet;
using MQTTnet.Client.Receiving;
using MQTTnet.Server;
using RGiesecke.DllExport;

public static class TradeTransmitterServer
{
    private static IMqttServer _mqttServer;
    private static ConcurrentQueue<string> _messageQueue = new ConcurrentQueue<string>();

    [DllExport("MQTT_StartBroker", CallingConvention = CallingConvention.StdCall)]
    public static int MQTT_StartBroker()
    {
        try
        {
            ThreadPool.QueueUserWorkItem(_ =>
            {
                var mqttFactory = new MqttFactory();
                var options = new MqttServerOptionsBuilder()
                    .WithDefaultEndpoint()
                    .WithDefaultEndpointPort(1883)
                    .Build();

                _mqttServer = mqttFactory.CreateMqttServer();
                _mqttServer.ApplicationMessageReceivedHandler = new MqttApplicationMessageReceivedHandlerDelegate(e =>
                {
                    string receivedMessage = $"Topic: {e.ApplicationMessage.Topic}, Message: {System.Text.Encoding.UTF8.GetString(e.ApplicationMessage.Payload)}";
                    _messageQueue.Enqueue(receivedMessage);
                    return Task.CompletedTask;
                });

                _mqttServer.StartAsync(options).Wait();
            });

            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            return -1;
        }
    }

    [DllExport("MQTT_StopBroker", CallingConvention = CallingConvention.StdCall)]
    public static int MQTT_StopBroker()
    {
        try
        {
            ThreadPool.QueueUserWorkItem(_ =>
            {
                _mqttServer?.StopAsync().Wait();
            });

            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error: {ex.Message}");
            return -1;
        }
    }

    [DllExport("MQTT_GetNextMessage", CallingConvention = CallingConvention.StdCall)]
    public static bool MQTT_GetNextMessage([MarshalAs(UnmanagedType.LPStr)] out string message)
    {
        return _messageQueue.TryDequeue(out message);
    }
}
