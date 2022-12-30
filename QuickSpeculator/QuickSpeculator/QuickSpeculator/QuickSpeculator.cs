using System;
using System.Threading;
using System.Windows.Forms;
using QuickSpeculatorEA;

public static class QuickSpeculator
{
    private static TradePanel Instance;

    public static void Show(string panelInfo, long hWndChart, double lots, int takeProfit, int stopLoss)
    {
        Thread thread = new Thread(() =>
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Instance = new TradePanel(lots, takeProfit, stopLoss);
            Instance.HandleChart = (IntPtr)hWndChart;
            Instance.Apply(panelInfo);
            Application.Run(Instance);
        });
        thread.SetApartmentState(ApartmentState.STA);
        thread.Start();
        Thread.Sleep(500);
    }

    public static string Hide()
    {
        try
        {
            Instance.Invoke((MethodInvoker)delegate
            {
                Instance.Dispose();
            });
        }
        catch (Exception e)
        {
            return e.Message;
        }
        return "";
    }

    public static void Update(string panelInfo, out double lots, out int takeProfit, out int stopLoss, out int orderType, out int errorSetParent, out int errorMoveWindow)
    {
        while (Instance == null || !Instance.Running)
        {
            Thread.Sleep(100);
        }

        errorSetParent = Instance.ErrorSetParent;
        errorMoveWindow = Instance.ErrorMoveWindow;

        Instance.Invoke(
            (MethodInvoker)delegate
            {
                Instance.Apply(panelInfo);
            });
        lots = Instance.Lots;
        takeProfit = Instance.TakeProfit;
        stopLoss = Instance.StopLoss;
        orderType = (int)Instance.OrderType;
        Instance.OrderType = OrderType.None;
    }
}
