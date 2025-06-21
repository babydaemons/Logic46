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

        public StudentSettingsControl()
        {
            InitializeComponent();
            dataGrid.ItemsSource = Students;
            LoadCsvData();
        }

        private void LoadCsvData()
        {
            var filePath = "students.csv";
            if (!File.Exists(filePath)) return;

            using (var reader = new StreamReader(filePath, new UTF8Encoding(false)))
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
            var filePath = "students.csv";
            using (var writer = new StreamWriter(filePath, false, new UTF8Encoding(false)))
            {
                foreach (var student in Students)
                {
                    writer.WriteLine($"{student.StudentName},{student.LotMultiplier}");
                }
            }

            MessageBox.Show("Data saved successfully.");
        }
    }

    public class StudentData
    {
        public string StudentName { get; set; }
        public string LotMultiplier { get; set; }
    }
}
