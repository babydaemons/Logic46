using System.Windows;
using System.Windows.Controls;

namespace KazuyaFX_StudentSetup
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        public void AddTab(string title, string terminalDir)
        {
            var tabItem = new TabItem
            {
                Header = title,
                Content = new StudentSettingsControl(title, terminalDir)
            };
            tabControl.Items.Add(tabItem);

            // 最初のタブを選択する
            if (tabControl.Items.Count == 1)
            {
                tabControl.SelectedIndex = 0; // 最初のタブを選択
            }
        }
    }
}
