using System;
using System.Windows.Forms;
using System.Drawing;

namespace QuickSpeculatorEA
{
    public partial class TradePanel : Form
    {
#if PANEL_EMBEDDED
        [DllImport("user32.dll")]
        static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);

        [DllImport("user32.dll")]
        private static extern int MoveWindow(IntPtr hwnd, int x, int y, int nWidth, int nHeight, int bRepaint);
#endif
        public IntPtr HandleChart;
        public double Lots;
        public int TakeProfit;
        public int StopLoss;
        public OrderType OrderType;
        public bool Running;

        public int ErrorSetParent;
        public int ErrorMoveWindow;

        public TradePanel()
        {
            InitializeComponent();
        }

        public TradePanel(double lots, int takeProfit, int stopLoss)
        {
            InitializeComponent();

            Lots = lots;
            OrderLots.Value = (decimal)lots;

            TextTakeProfit.Value = TakeProfit = takeProfit;
            TextTakeProfit.ForeColor = TakeProfit < 0 ? Color.Red : Color.Black;
            TextTakeProfit.Text = TakeProfit.ToString("#,0");

            TextStopLoss.Value = StopLoss = stopLoss;
            TextStopLoss.ForeColor = StopLoss < 0 ? Color.Red : Color.Black;
            TextStopLoss.Text = StopLoss.ToString("#,0");
        }

        public void Apply(string panelInfo)
        {
            string[] info = panelInfo.Split(' ');
            TextOrderMargin.Text = FormatInteger(info[(int)PanelInfo.OrderMargin]);
            TextOrderSpreadLoss.Text = FormatInteger(info[(int)PanelInfo.OrderSpreadLoss]);
            TextAccountBalance.Text = FormatInteger(info[(int)PanelInfo.AccountBalance]);
            TextValidMargin.Text = FormatInteger(info[(int)PanelInfo.ValidMargin]);
            TextRequireMargin.Text = FormatInteger(info[(int)PanelInfo.RequireMargin]);
            TextFreeMargin.Text = FormatInteger(info[(int)PanelInfo.FreeMargin]);
            TextMarginLevel.Text = FormatDouble(info[(int)PanelInfo.MarginLevel]) + "%";
            TextTotalLots.Text = FormatDouble(info[(int)PanelInfo.TotalLots]);
            TextTotalLots.ForeColor = TextTotalLots.Text[0] == '-' ? Color.Red : Color.Cyan;
            TextTotalProfit.Text = FormatInteger(info[(int)PanelInfo.TotalProfit]);
            TextTotalProfit.ForeColor = TextTotalProfit.Text[0] == '-' ? Color.Red : Color.Cyan;
        }

        public static string FormatInteger(string valueText)
        {
            int.TryParse(valueText, out int value);
            return value.ToString("#,0");
        }

        public static string FormatDouble(string valueText)
        {
            double.TryParse(valueText, out double value);
            return value.ToString("#,0.00");
        }

        private void TradePanel_Load(object sender, EventArgs e)
        {
#if PANEL_EMBEDDED
            FormBorderStyle = FormBorderStyle.None;

            SetParent(Handle, HandleChart);
            ErrorSetParent = Marshal.GetLastWin32Error();

            MoveWindow(Handle, 5, 15, Size.Width, Size.Height, 1);
            ErrorMoveWindow = Marshal.GetLastWin32Error();
#endif
            Running = true;
        }

        private void OrderLots_Leave(object sender, EventArgs e)
        {
            Lots = (double)OrderLots.Value;
        }

        private void TextTakeProfit_Leave(object sender, EventArgs e)
        {
            TakeProfit = TakeProfit = (int)TextTakeProfit.Value;
            TextTakeProfit.ForeColor = TakeProfit < 0 ? Color.Red : Color.Black;
        }

        private void TextStopLoss_Leave(object sender, EventArgs e)
        {
            StopLoss = (int)TextStopLoss.Value;
            TextStopLoss.ForeColor = StopLoss < 0 ? Color.Red : Color.Black;
        }

        private void ButtonBuy_Click(object sender, EventArgs e)
        {
            OrderType = OrderType.Buy;
        }

        private void ButtonSell_Click(object sender, EventArgs e)
        {
            OrderType = OrderType.Sell;
        }

        private void ButtonSettlement_Click(object sender, EventArgs e)
        {
            OrderType = OrderType.Settlement;
        }
    }

    public enum OrderType
    {
        None = 0,
        Buy = 1,
        Sell = -1,
        Settlement = 2,
    }

    internal enum PanelInfo
    {
        OrderMargin,
        OrderSpreadLoss,
        AccountBalance,
        ValidMargin,
        RequireMargin,
        FreeMargin,
        MarginLevel,
        TotalLots,
        TotalProfit
    }

}
