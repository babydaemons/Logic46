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

        public void AddTab(string title)
        {
            var tabItem = new TabItem
            {
                Header = title,
                Content = new StudentSettingsControl()
            };
            tabControl.Items.Add(tabItem);
        }
    }
}
