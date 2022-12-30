namespace QuickSpeculatorEA
{
    partial class TradePanel
    {
        /// <summary>
        /// 必要なデザイナー変数です。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// 使用中のリソースをすべてクリーンアップします。
        /// </summary>
        /// <param name="disposing">マネージド リソースを破棄する場合は true を指定し、その他の場合は false を指定します。</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows フォーム デザイナーで生成されたコード

        /// <summary>
        /// デザイナー サポートに必要なメソッドです。このメソッドの内容を
        /// コード エディターで変更しないでください。
        /// </summary>
        private void InitializeComponent()
        {
            this.PanelTrade = new System.Windows.Forms.Panel();
            this.PanelOrderLots = new System.Windows.Forms.Panel();
            this.OrderLots = new System.Windows.Forms.NumericUpDown();
            this.TableLayoutPanelTrade = new System.Windows.Forms.TableLayoutPanel();
            this.TextTakeProfit = new System.Windows.Forms.NumericUpDown();
            this.LabelTakeProfit = new System.Windows.Forms.Label();
            this.TextTotalProfit = new System.Windows.Forms.Label();
            this.TextOrderSpreadLoss = new System.Windows.Forms.Label();
            this.LabelTotalProfit = new System.Windows.Forms.Label();
            this.LabelStopLoss = new System.Windows.Forms.Label();
            this.TextTotalLots = new System.Windows.Forms.Label();
            this.LabelOrderSpreadLoss = new System.Windows.Forms.Label();
            this.LabelTotalLots = new System.Windows.Forms.Label();
            this.LabelOrderMargin = new System.Windows.Forms.Label();
            this.TextFreeMargin = new System.Windows.Forms.Label();
            this.TextMarginLevel = new System.Windows.Forms.Label();
            this.TextOrderMargin = new System.Windows.Forms.Label();
            this.LabelMarginLevel = new System.Windows.Forms.Label();
            this.TextRequireMargin = new System.Windows.Forms.Label();
            this.LabelAccountBalance = new System.Windows.Forms.Label();
            this.TextValidMargin = new System.Windows.Forms.Label();
            this.TextAccountBalance = new System.Windows.Forms.Label();
            this.LabelFreeMargin = new System.Windows.Forms.Label();
            this.LabelValidMargin = new System.Windows.Forms.Label();
            this.LabelRequireMargin = new System.Windows.Forms.Label();
            this.TextStopLoss = new System.Windows.Forms.NumericUpDown();
            this.ButtonSettlement = new System.Windows.Forms.Button();
            this.ButtonSell = new System.Windows.Forms.Button();
            this.ButtonBuy = new System.Windows.Forms.Button();
            this.PanelTrade.SuspendLayout();
            this.PanelOrderLots.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.OrderLots)).BeginInit();
            this.TableLayoutPanelTrade.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.TextTakeProfit)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.TextStopLoss)).BeginInit();
            this.SuspendLayout();
            // 
            // PanelTrade
            // 
            this.PanelTrade.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(64)))));
            this.PanelTrade.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.PanelTrade.Controls.Add(this.PanelOrderLots);
            this.PanelTrade.Controls.Add(this.TableLayoutPanelTrade);
            this.PanelTrade.Controls.Add(this.ButtonSettlement);
            this.PanelTrade.Controls.Add(this.ButtonSell);
            this.PanelTrade.Controls.Add(this.ButtonBuy);
            this.PanelTrade.ForeColor = System.Drawing.Color.Cyan;
            this.PanelTrade.Location = new System.Drawing.Point(1, 1);
            this.PanelTrade.Margin = new System.Windows.Forms.Padding(0);
            this.PanelTrade.Name = "PanelTrade";
            this.PanelTrade.Size = new System.Drawing.Size(284, 287);
            this.PanelTrade.TabIndex = 2;
            // 
            // PanelOrderLots
            // 
            this.PanelOrderLots.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(220)))));
            this.PanelOrderLots.Controls.Add(this.OrderLots);
            this.PanelOrderLots.Location = new System.Drawing.Point(97, 2);
            this.PanelOrderLots.Margin = new System.Windows.Forms.Padding(0);
            this.PanelOrderLots.Name = "PanelOrderLots";
            this.PanelOrderLots.Size = new System.Drawing.Size(86, 22);
            this.PanelOrderLots.TabIndex = 0;
            // 
            // OrderLots
            // 
            this.OrderLots.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.OrderLots.DecimalPlaces = 2;
            this.OrderLots.Increment = new decimal(new int[] {
            1,
            0,
            0,
            131072});
            this.OrderLots.Location = new System.Drawing.Point(2, 2);
            this.OrderLots.Margin = new System.Windows.Forms.Padding(0);
            this.OrderLots.Maximum = new decimal(new int[] {
            99999,
            0,
            0,
            131072});
            this.OrderLots.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            131072});
            this.OrderLots.Name = "OrderLots";
            this.OrderLots.Size = new System.Drawing.Size(82, 18);
            this.OrderLots.TabIndex = 1;
            this.OrderLots.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            this.OrderLots.Value = new decimal(new int[] {
            99999,
            0,
            0,
            131072});
            this.OrderLots.Leave += new System.EventHandler(this.OrderLots_Leave);
            // 
            // TableLayoutPanelTrade
            // 
            this.TableLayoutPanelTrade.ColumnCount = 2;
            this.TableLayoutPanelTrade.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 50F));
            this.TableLayoutPanelTrade.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 50F));
            this.TableLayoutPanelTrade.Controls.Add(this.TextTakeProfit, 1, 0);
            this.TableLayoutPanelTrade.Controls.Add(this.LabelTakeProfit, 0, 0);
            this.TableLayoutPanelTrade.Controls.Add(this.TextTotalProfit, 1, 10);
            this.TableLayoutPanelTrade.Controls.Add(this.TextOrderSpreadLoss, 1, 3);
            this.TableLayoutPanelTrade.Controls.Add(this.LabelTotalProfit, 0, 10);
            this.TableLayoutPanelTrade.Controls.Add(this.LabelStopLoss, 0, 1);
            this.TableLayoutPanelTrade.Controls.Add(this.TextTotalLots, 1, 9);
            this.TableLayoutPanelTrade.Controls.Add(this.LabelOrderSpreadLoss, 0, 3);
            this.TableLayoutPanelTrade.Controls.Add(this.LabelTotalLots, 0, 9);
            this.TableLayoutPanelTrade.Controls.Add(this.LabelOrderMargin, 0, 2);
            this.TableLayoutPanelTrade.Controls.Add(this.TextFreeMargin, 1, 7);
            this.TableLayoutPanelTrade.Controls.Add(this.TextMarginLevel, 1, 8);
            this.TableLayoutPanelTrade.Controls.Add(this.TextOrderMargin, 1, 2);
            this.TableLayoutPanelTrade.Controls.Add(this.LabelMarginLevel, 0, 8);
            this.TableLayoutPanelTrade.Controls.Add(this.TextRequireMargin, 1, 6);
            this.TableLayoutPanelTrade.Controls.Add(this.LabelAccountBalance, 0, 4);
            this.TableLayoutPanelTrade.Controls.Add(this.TextValidMargin, 1, 5);
            this.TableLayoutPanelTrade.Controls.Add(this.TextAccountBalance, 1, 4);
            this.TableLayoutPanelTrade.Controls.Add(this.LabelFreeMargin, 0, 7);
            this.TableLayoutPanelTrade.Controls.Add(this.LabelValidMargin, 0, 5);
            this.TableLayoutPanelTrade.Controls.Add(this.LabelRequireMargin, 0, 6);
            this.TableLayoutPanelTrade.Controls.Add(this.TextStopLoss, 1, 1);
            this.TableLayoutPanelTrade.Location = new System.Drawing.Point(3, 36);
            this.TableLayoutPanelTrade.Margin = new System.Windows.Forms.Padding(0, 2, 0, 0);
            this.TableLayoutPanelTrade.Name = "TableLayoutPanelTrade";
            this.TableLayoutPanelTrade.RowCount = 11;
            this.TableLayoutPanelTrade.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 24F));
            this.TableLayoutPanelTrade.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 24F));
            this.TableLayoutPanelTrade.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 18F));
            this.TableLayoutPanelTrade.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 18F));
            this.TableLayoutPanelTrade.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 18F));
            this.TableLayoutPanelTrade.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 18F));
            this.TableLayoutPanelTrade.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 18F));
            this.TableLayoutPanelTrade.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 18F));
            this.TableLayoutPanelTrade.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 18F));
            this.TableLayoutPanelTrade.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 18F));
            this.TableLayoutPanelTrade.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 18F));
            this.TableLayoutPanelTrade.Size = new System.Drawing.Size(276, 210);
            this.TableLayoutPanelTrade.TabIndex = 3;
            // 
            // TextTakeProfit
            // 
            this.TextTakeProfit.Dock = System.Windows.Forms.DockStyle.Fill;
            this.TextTakeProfit.Location = new System.Drawing.Point(141, 3);
            this.TextTakeProfit.Maximum = new decimal(new int[] {
            100000000,
            0,
            0,
            0});
            this.TextTakeProfit.Minimum = new decimal(new int[] {
            100000000,
            0,
            0,
            -2147483648});
            this.TextTakeProfit.Name = "TextTakeProfit";
            this.TextTakeProfit.Size = new System.Drawing.Size(132, 22);
            this.TextTakeProfit.TabIndex = 2;
            this.TextTakeProfit.ThousandsSeparator = true;
            this.TextTakeProfit.Value = new decimal(new int[] {
            200000,
            0,
            0,
            0});
            this.TextTakeProfit.Leave += new System.EventHandler(this.TextTakeProfit_Leave);
            // 
            // LabelTakeProfit
            // 
            this.LabelTakeProfit.AutoSize = true;
            this.LabelTakeProfit.Dock = System.Windows.Forms.DockStyle.Fill;
            this.LabelTakeProfit.ForeColor = System.Drawing.Color.Cyan;
            this.LabelTakeProfit.Location = new System.Drawing.Point(2, 3);
            this.LabelTakeProfit.Margin = new System.Windows.Forms.Padding(2, 3, 2, 5);
            this.LabelTakeProfit.Name = "LabelTakeProfit";
            this.LabelTakeProfit.Size = new System.Drawing.Size(134, 16);
            this.LabelTakeProfit.TabIndex = 3;
            this.LabelTakeProfit.Text = "利確金額";
            this.LabelTakeProfit.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // TextTotalProfit
            // 
            this.TextTotalProfit.AutoSize = true;
            this.TextTotalProfit.Dock = System.Windows.Forms.DockStyle.Fill;
            this.TextTotalProfit.ForeColor = System.Drawing.Color.Cyan;
            this.TextTotalProfit.Location = new System.Drawing.Point(140, 192);
            this.TextTotalProfit.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.TextTotalProfit.Name = "TextTotalProfit";
            this.TextTotalProfit.Size = new System.Drawing.Size(136, 18);
            this.TextTotalProfit.TabIndex = 0;
            this.TextTotalProfit.Text = "1,234,567";
            this.TextTotalProfit.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // TextOrderSpreadLoss
            // 
            this.TextOrderSpreadLoss.AutoSize = true;
            this.TextOrderSpreadLoss.Dock = System.Windows.Forms.DockStyle.Fill;
            this.TextOrderSpreadLoss.ForeColor = System.Drawing.Color.Red;
            this.TextOrderSpreadLoss.Location = new System.Drawing.Point(140, 66);
            this.TextOrderSpreadLoss.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.TextOrderSpreadLoss.Name = "TextOrderSpreadLoss";
            this.TextOrderSpreadLoss.Size = new System.Drawing.Size(136, 18);
            this.TextOrderSpreadLoss.TabIndex = 15;
            this.TextOrderSpreadLoss.Text = "-5,678";
            this.TextOrderSpreadLoss.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // LabelTotalProfit
            // 
            this.LabelTotalProfit.AutoSize = true;
            this.LabelTotalProfit.Dock = System.Windows.Forms.DockStyle.Fill;
            this.LabelTotalProfit.ForeColor = System.Drawing.Color.Cyan;
            this.LabelTotalProfit.Location = new System.Drawing.Point(2, 192);
            this.LabelTotalProfit.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.LabelTotalProfit.Name = "LabelTotalProfit";
            this.LabelTotalProfit.Size = new System.Drawing.Size(136, 18);
            this.LabelTotalProfit.TabIndex = 13;
            this.LabelTotalProfit.Text = "全損益";
            this.LabelTotalProfit.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // LabelStopLoss
            // 
            this.LabelStopLoss.AutoSize = true;
            this.LabelStopLoss.Dock = System.Windows.Forms.DockStyle.Fill;
            this.LabelStopLoss.ForeColor = System.Drawing.Color.Cyan;
            this.LabelStopLoss.Location = new System.Drawing.Point(2, 27);
            this.LabelStopLoss.Margin = new System.Windows.Forms.Padding(2, 3, 2, 5);
            this.LabelStopLoss.Name = "LabelStopLoss";
            this.LabelStopLoss.Size = new System.Drawing.Size(134, 16);
            this.LabelStopLoss.TabIndex = 4;
            this.LabelStopLoss.Text = "損切金額";
            this.LabelStopLoss.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // TextTotalLots
            // 
            this.TextTotalLots.AutoSize = true;
            this.TextTotalLots.Dock = System.Windows.Forms.DockStyle.Fill;
            this.TextTotalLots.ForeColor = System.Drawing.Color.Cyan;
            this.TextTotalLots.Location = new System.Drawing.Point(140, 174);
            this.TextTotalLots.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.TextTotalLots.Name = "TextTotalLots";
            this.TextTotalLots.Size = new System.Drawing.Size(136, 18);
            this.TextTotalLots.TabIndex = 21;
            this.TextTotalLots.Text = "123.45";
            this.TextTotalLots.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // LabelOrderSpreadLoss
            // 
            this.LabelOrderSpreadLoss.AutoSize = true;
            this.LabelOrderSpreadLoss.Dock = System.Windows.Forms.DockStyle.Fill;
            this.LabelOrderSpreadLoss.ForeColor = System.Drawing.Color.Cyan;
            this.LabelOrderSpreadLoss.Location = new System.Drawing.Point(2, 66);
            this.LabelOrderSpreadLoss.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.LabelOrderSpreadLoss.Name = "LabelOrderSpreadLoss";
            this.LabelOrderSpreadLoss.Size = new System.Drawing.Size(136, 18);
            this.LabelOrderSpreadLoss.TabIndex = 6;
            this.LabelOrderSpreadLoss.Text = "発注スプレッド損失";
            this.LabelOrderSpreadLoss.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // LabelTotalLots
            // 
            this.LabelTotalLots.AutoSize = true;
            this.LabelTotalLots.Dock = System.Windows.Forms.DockStyle.Fill;
            this.LabelTotalLots.ForeColor = System.Drawing.Color.Cyan;
            this.LabelTotalLots.Location = new System.Drawing.Point(2, 174);
            this.LabelTotalLots.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.LabelTotalLots.Name = "LabelTotalLots";
            this.LabelTotalLots.Size = new System.Drawing.Size(136, 18);
            this.LabelTotalLots.TabIndex = 12;
            this.LabelTotalLots.Text = "全ロット数";
            this.LabelTotalLots.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // LabelOrderMargin
            // 
            this.LabelOrderMargin.AutoSize = true;
            this.LabelOrderMargin.Dock = System.Windows.Forms.DockStyle.Fill;
            this.LabelOrderMargin.ForeColor = System.Drawing.Color.Cyan;
            this.LabelOrderMargin.Location = new System.Drawing.Point(2, 48);
            this.LabelOrderMargin.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.LabelOrderMargin.Name = "LabelOrderMargin";
            this.LabelOrderMargin.Size = new System.Drawing.Size(136, 18);
            this.LabelOrderMargin.TabIndex = 5;
            this.LabelOrderMargin.Text = "発注証拠金";
            this.LabelOrderMargin.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // TextFreeMargin
            // 
            this.TextFreeMargin.AutoSize = true;
            this.TextFreeMargin.Dock = System.Windows.Forms.DockStyle.Fill;
            this.TextFreeMargin.ForeColor = System.Drawing.Color.Cyan;
            this.TextFreeMargin.Location = new System.Drawing.Point(140, 138);
            this.TextFreeMargin.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.TextFreeMargin.Name = "TextFreeMargin";
            this.TextFreeMargin.Size = new System.Drawing.Size(136, 18);
            this.TextFreeMargin.TabIndex = 19;
            this.TextFreeMargin.Text = "987,654";
            this.TextFreeMargin.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // TextMarginLevel
            // 
            this.TextMarginLevel.AutoSize = true;
            this.TextMarginLevel.Dock = System.Windows.Forms.DockStyle.Fill;
            this.TextMarginLevel.ForeColor = System.Drawing.Color.Cyan;
            this.TextMarginLevel.Location = new System.Drawing.Point(140, 156);
            this.TextMarginLevel.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.TextMarginLevel.Name = "TextMarginLevel";
            this.TextMarginLevel.Size = new System.Drawing.Size(136, 18);
            this.TextMarginLevel.TabIndex = 20;
            this.TextMarginLevel.Text = "1,999.99%";
            this.TextMarginLevel.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // TextOrderMargin
            // 
            this.TextOrderMargin.AutoSize = true;
            this.TextOrderMargin.Dock = System.Windows.Forms.DockStyle.Fill;
            this.TextOrderMargin.ForeColor = System.Drawing.Color.Cyan;
            this.TextOrderMargin.Location = new System.Drawing.Point(140, 48);
            this.TextOrderMargin.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.TextOrderMargin.Name = "TextOrderMargin";
            this.TextOrderMargin.Size = new System.Drawing.Size(136, 18);
            this.TextOrderMargin.TabIndex = 14;
            this.TextOrderMargin.Text = "45,678";
            this.TextOrderMargin.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // LabelMarginLevel
            // 
            this.LabelMarginLevel.AutoSize = true;
            this.LabelMarginLevel.Dock = System.Windows.Forms.DockStyle.Fill;
            this.LabelMarginLevel.ForeColor = System.Drawing.Color.Cyan;
            this.LabelMarginLevel.Location = new System.Drawing.Point(2, 156);
            this.LabelMarginLevel.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.LabelMarginLevel.Name = "LabelMarginLevel";
            this.LabelMarginLevel.Size = new System.Drawing.Size(136, 18);
            this.LabelMarginLevel.TabIndex = 11;
            this.LabelMarginLevel.Text = "証拠金維持率";
            this.LabelMarginLevel.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // TextRequireMargin
            // 
            this.TextRequireMargin.AutoSize = true;
            this.TextRequireMargin.Dock = System.Windows.Forms.DockStyle.Fill;
            this.TextRequireMargin.ForeColor = System.Drawing.Color.Cyan;
            this.TextRequireMargin.Location = new System.Drawing.Point(140, 120);
            this.TextRequireMargin.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.TextRequireMargin.Name = "TextRequireMargin";
            this.TextRequireMargin.Size = new System.Drawing.Size(136, 18);
            this.TextRequireMargin.TabIndex = 18;
            this.TextRequireMargin.Text = "123,456";
            this.TextRequireMargin.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // LabelAccountBalance
            // 
            this.LabelAccountBalance.AutoSize = true;
            this.LabelAccountBalance.Dock = System.Windows.Forms.DockStyle.Fill;
            this.LabelAccountBalance.ForeColor = System.Drawing.Color.Cyan;
            this.LabelAccountBalance.Location = new System.Drawing.Point(2, 84);
            this.LabelAccountBalance.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.LabelAccountBalance.Name = "LabelAccountBalance";
            this.LabelAccountBalance.Size = new System.Drawing.Size(136, 18);
            this.LabelAccountBalance.TabIndex = 7;
            this.LabelAccountBalance.Text = "口座残高";
            this.LabelAccountBalance.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // TextValidMargin
            // 
            this.TextValidMargin.AutoSize = true;
            this.TextValidMargin.Dock = System.Windows.Forms.DockStyle.Fill;
            this.TextValidMargin.ForeColor = System.Drawing.Color.Cyan;
            this.TextValidMargin.Location = new System.Drawing.Point(140, 102);
            this.TextValidMargin.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.TextValidMargin.Name = "TextValidMargin";
            this.TextValidMargin.Size = new System.Drawing.Size(136, 18);
            this.TextValidMargin.TabIndex = 17;
            this.TextValidMargin.Text = "1,123,456";
            this.TextValidMargin.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // TextAccountBalance
            // 
            this.TextAccountBalance.AutoSize = true;
            this.TextAccountBalance.Dock = System.Windows.Forms.DockStyle.Fill;
            this.TextAccountBalance.ForeColor = System.Drawing.Color.Cyan;
            this.TextAccountBalance.Location = new System.Drawing.Point(140, 84);
            this.TextAccountBalance.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.TextAccountBalance.Name = "TextAccountBalance";
            this.TextAccountBalance.Size = new System.Drawing.Size(136, 18);
            this.TextAccountBalance.TabIndex = 16;
            this.TextAccountBalance.Text = "1,000,000";
            this.TextAccountBalance.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // LabelFreeMargin
            // 
            this.LabelFreeMargin.AutoSize = true;
            this.LabelFreeMargin.Dock = System.Windows.Forms.DockStyle.Fill;
            this.LabelFreeMargin.ForeColor = System.Drawing.Color.Cyan;
            this.LabelFreeMargin.Location = new System.Drawing.Point(2, 138);
            this.LabelFreeMargin.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.LabelFreeMargin.Name = "LabelFreeMargin";
            this.LabelFreeMargin.Size = new System.Drawing.Size(136, 18);
            this.LabelFreeMargin.TabIndex = 10;
            this.LabelFreeMargin.Text = "余剰証拠金";
            this.LabelFreeMargin.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // LabelValidMargin
            // 
            this.LabelValidMargin.AutoSize = true;
            this.LabelValidMargin.Dock = System.Windows.Forms.DockStyle.Fill;
            this.LabelValidMargin.ForeColor = System.Drawing.Color.Cyan;
            this.LabelValidMargin.Location = new System.Drawing.Point(2, 102);
            this.LabelValidMargin.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.LabelValidMargin.Name = "LabelValidMargin";
            this.LabelValidMargin.Size = new System.Drawing.Size(136, 18);
            this.LabelValidMargin.TabIndex = 8;
            this.LabelValidMargin.Text = "有効証拠金";
            this.LabelValidMargin.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // LabelRequireMargin
            // 
            this.LabelRequireMargin.AutoSize = true;
            this.LabelRequireMargin.Dock = System.Windows.Forms.DockStyle.Fill;
            this.LabelRequireMargin.ForeColor = System.Drawing.Color.Cyan;
            this.LabelRequireMargin.Location = new System.Drawing.Point(2, 120);
            this.LabelRequireMargin.Margin = new System.Windows.Forms.Padding(2, 0, 0, 0);
            this.LabelRequireMargin.Name = "LabelRequireMargin";
            this.LabelRequireMargin.Size = new System.Drawing.Size(136, 18);
            this.LabelRequireMargin.TabIndex = 9;
            this.LabelRequireMargin.Text = "必要証拠金";
            this.LabelRequireMargin.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // TextStopLoss
            // 
            this.TextStopLoss.Dock = System.Windows.Forms.DockStyle.Fill;
            this.TextStopLoss.Location = new System.Drawing.Point(141, 27);
            this.TextStopLoss.Maximum = new decimal(new int[] {
            100000000,
            0,
            0,
            0});
            this.TextStopLoss.Minimum = new decimal(new int[] {
            100000000,
            0,
            0,
            -2147483648});
            this.TextStopLoss.Name = "TextStopLoss";
            this.TextStopLoss.Size = new System.Drawing.Size(132, 22);
            this.TextStopLoss.TabIndex = 3;
            this.TextStopLoss.ThousandsSeparator = true;
            this.TextStopLoss.Value = new decimal(new int[] {
            100000,
            0,
            0,
            -2147483648});
            this.TextStopLoss.Leave += new System.EventHandler(this.TextStopLoss_Leave);
            // 
            // ButtonSettlement
            // 
            this.ButtonSettlement.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(255)))), ((int)(((byte)(220)))), ((int)(((byte)(128)))));
            this.ButtonSettlement.FlatAppearance.BorderColor = System.Drawing.Color.FromArgb(((int)(((byte)(255)))), ((int)(((byte)(180)))), ((int)(((byte)(88)))));
            this.ButtonSettlement.FlatAppearance.BorderSize = 2;
            this.ButtonSettlement.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.ButtonSettlement.ForeColor = System.Drawing.Color.Red;
            this.ButtonSettlement.Location = new System.Drawing.Point(3, 250);
            this.ButtonSettlement.Margin = new System.Windows.Forms.Padding(0);
            this.ButtonSettlement.Name = "ButtonSettlement";
            this.ButtonSettlement.Size = new System.Drawing.Size(276, 32);
            this.ButtonSettlement.TabIndex = 6;
            this.ButtonSettlement.Text = "全決済";
            this.ButtonSettlement.UseVisualStyleBackColor = false;
            this.ButtonSettlement.Click += new System.EventHandler(this.ButtonSettlement_Click);
            // 
            // ButtonSell
            // 
            this.ButtonSell.BackColor = System.Drawing.Color.LightSteelBlue;
            this.ButtonSell.FlatAppearance.BorderColor = System.Drawing.Color.RoyalBlue;
            this.ButtonSell.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.ButtonSell.ForeColor = System.Drawing.Color.Blue;
            this.ButtonSell.Location = new System.Drawing.Point(142, 3);
            this.ButtonSell.Margin = new System.Windows.Forms.Padding(0);
            this.ButtonSell.Name = "ButtonSell";
            this.ButtonSell.Size = new System.Drawing.Size(138, 32);
            this.ButtonSell.TabIndex = 5;
            this.ButtonSell.Text = "Sell";
            this.ButtonSell.UseVisualStyleBackColor = false;
            this.ButtonSell.Click += new System.EventHandler(this.ButtonSell_Click);
            // 
            // ButtonBuy
            // 
            this.ButtonBuy.BackColor = System.Drawing.Color.Pink;
            this.ButtonBuy.FlatAppearance.BorderColor = System.Drawing.Color.Red;
            this.ButtonBuy.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.ButtonBuy.ForeColor = System.Drawing.Color.Red;
            this.ButtonBuy.Location = new System.Drawing.Point(3, 3);
            this.ButtonBuy.Margin = new System.Windows.Forms.Padding(0);
            this.ButtonBuy.Name = "ButtonBuy";
            this.ButtonBuy.Size = new System.Drawing.Size(138, 32);
            this.ButtonBuy.TabIndex = 4;
            this.ButtonBuy.Text = "Buy";
            this.ButtonBuy.UseVisualStyleBackColor = false;
            this.ButtonBuy.Click += new System.EventHandler(this.ButtonBuy_Click);
            // 
            // TradePanel
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(10F, 15F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(286, 289);
            this.ControlBox = false;
            this.Controls.Add(this.PanelTrade);
            this.Font = new System.Drawing.Font("BIZ UDPゴシック", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(128)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            this.Name = "TradePanel";
            this.ShowInTaskbar = false;
            this.SizeGripStyle = System.Windows.Forms.SizeGripStyle.Hide;
            this.Text = "QuickSpeculator";
            this.TopMost = true;
            this.Load += new System.EventHandler(this.TradePanel_Load);
            this.PanelTrade.ResumeLayout(false);
            this.PanelOrderLots.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.OrderLots)).EndInit();
            this.TableLayoutPanelTrade.ResumeLayout(false);
            this.TableLayoutPanelTrade.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.TextTakeProfit)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.TextStopLoss)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion
        private System.Windows.Forms.Panel PanelTrade;
        private System.Windows.Forms.Label TextFreeMargin;
        private System.Windows.Forms.Label TextRequireMargin;
        private System.Windows.Forms.Label TextValidMargin;
        private System.Windows.Forms.Label TextAccountBalance;
        private System.Windows.Forms.Label TextOrderMargin;
        private System.Windows.Forms.Button ButtonSell;
        private System.Windows.Forms.Label TextMarginLevel;
        private System.Windows.Forms.Label LabelMarginLevel;
        private System.Windows.Forms.Button ButtonBuy;
        private System.Windows.Forms.Label LabelFreeMargin;
        private System.Windows.Forms.Label LabelRequireMargin;
        private System.Windows.Forms.Label LabelValidMargin;
        private System.Windows.Forms.Label LabelAccountBalance;
        private System.Windows.Forms.Label LabelOrderMargin;
        private System.Windows.Forms.Button ButtonSettlement;
        private System.Windows.Forms.Label TextTotalProfit;
        private System.Windows.Forms.Label LabelTotalProfit;
        private System.Windows.Forms.Label TextTotalLots;
        private System.Windows.Forms.Label LabelTotalLots;
        private System.Windows.Forms.Label TextOrderSpreadLoss;
        private System.Windows.Forms.Label LabelOrderSpreadLoss;
        private System.Windows.Forms.TableLayoutPanel TableLayoutPanelTrade;
        private System.Windows.Forms.Label LabelTakeProfit;
        private System.Windows.Forms.Label LabelStopLoss;
        private System.Windows.Forms.Panel PanelOrderLots;
        private System.Windows.Forms.NumericUpDown OrderLots;
        private System.Windows.Forms.NumericUpDown TextTakeProfit;
        private System.Windows.Forms.NumericUpDown TextStopLoss;
    }
}

