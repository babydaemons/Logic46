using System;
using System.Collections.ObjectModel;
using System.IO;
using System.Text;
using System.Windows;
using System.Windows.Controls;

namespace KazuyaFX_StudentSetup
{
    public partial class StudentSettingsControl : UserControl
    {
        public ObservableCollection<StudentData> Students { get; set; } = new ObservableCollection<StudentData>();
        private string _terminalDir;
        private string _configDir;
        private string _configPath;

        public StudentSettingsControl(string terminalDir)
        {
            InitializeComponent();
            _terminalDir = terminalDir ?? throw new ArgumentNullException(nameof(terminalDir));
            _configDir = CreateCongigDirectory(_terminalDir);
            dataGrid.ItemsSource = Students;
            LoadCsvData(_configDir);
        }

        private void LoadCsvData(string configDir)
        {
            _configPath = Path.Combine(configDir, "Students.csv");
            if (!File.Exists(_configPath)) return;

            using (var reader = new StreamReader(_configPath, new UTF8Encoding(false)))
            {
                Students.Clear();
                string line;
                while ((line = reader.ReadLine()) != null)
                {
                    var parts = line.Split(',');
                    if (parts.Length >= 2)
                    {
                        Students.Add(new StudentData
                        {
                            StudentName = parts[0],
                            LotMultiplier = parts[1]
                        });
                    }
                }
            }
        }

        private void btnSave_Click(object sender, RoutedEventArgs e)
        {
            using (var writer = new StreamWriter(_configPath, false, new UTF8Encoding(false)))
            {
                foreach (var student in Students)
                {
                    writer.WriteLine($"{student.StudentName},{student.LotMultiplier}");
                }
            }

            MessageBox.Show("Data saved successfully.");
        }

        private string CreateCongigDirectory(string terminalDir)
        {
            var configDir = Path.Combine(terminalDir, "Files", "Config");
            if (!Directory.Exists(configDir))
            {
                try
                {
                    Directory.CreateDirectory(configDir);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Error creating directory: {ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
            return configDir;
        }
    }

    public class StudentData
    {
        public string StudentName { get; set; }
        public string LotMultiplier { get; set; }
    }
}
