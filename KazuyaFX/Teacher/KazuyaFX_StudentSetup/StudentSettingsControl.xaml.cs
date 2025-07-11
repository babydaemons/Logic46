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
        private readonly string _title;
        private readonly string _terminalDir;
        private readonly string _configDir;
        private string _configPath;

        public StudentSettingsControl(string title, string terminalDir)
        {
            InitializeComponent();
            _title = title ?? throw new ArgumentNullException(nameof(title));
            _terminalDir = terminalDir ?? throw new ArgumentNullException(nameof(terminalDir));
            _configDir = CreateCongigDirectory(_terminalDir);
            dataGrid.ItemsSource = Students;
            LoadCsvData(_configDir);
        }

        private void LoadCsvData(string configDir)
        {
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
                    if (string.IsNullOrWhiteSpace(student.StudentName) || string.IsNullOrWhiteSpace(student.LotMultiplier))
                    {
                        continue;
                    }
                    writer.WriteLine($"{student.StudentName},{student.LotMultiplier}");
                }
            }

            MessageBox.Show("生徒さん毎のロット倍率を保存しました。", _title);
        }

        private string CreateCongigDirectory(string terminalDir)
        {
            var configDir = Path.Combine(terminalDir, "MQL4", "Files", "Config");
            if (!Directory.Exists(configDir))
            {
                try
                {
                    Directory.CreateDirectory(configDir);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"フォルダの作成に失敗しました: {ex.Message}", "エラー", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
            _configPath = Path.Combine(configDir, "Students.csv");
            if (!File.Exists(_configPath))
            {
                using (var writer = new FileStream(_configPath, FileMode.Create, FileAccess.Write, FileShare.None))
                {
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
