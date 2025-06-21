using System;
using System.Collections.Generic;
using System.Windows.Forms;

namespace KazuyaFX_StudentSetup
{
    public partial class StudentSettingsControl : UserControl
    {
        public StudentSettingsControl()
        {
            InitializeComponent();

            // 初期データの追加
            dataGridView1.Rows.Add("山田太郎", 1.0);
            dataGridView1.Rows.Add("佐藤花子", 0.5);
        }

        private void buttonSave_Click(object sender, EventArgs e)
        {
            bool shouldResetMT4 = checkBoxReset.Checked;

            var studentSettings = new List<(string name, double multiplier)>();

            foreach (DataGridViewRow row in dataGridView1.Rows)
            {
                if (row.IsNewRow) continue;

                string name = row.Cells[0].Value?.ToString();
                if (string.IsNullOrWhiteSpace(name)) continue;

                double multiplier;
                if (!double.TryParse(row.Cells[1].Value?.ToString(), out multiplier))
                {
                    MessageBox.Show("ロット倍率の値が不正です。", "エラー", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                studentSettings.Add((name, multiplier));
            }

            // 保存処理
            foreach (var s in studentSettings)
            {
                Console.WriteLine($"{s.name}: {s.multiplier}");
            }

            MessageBox.Show(
                shouldResetMT4 ? "保存しました（MT4ログイン情報は初期化されます）" : "保存しました",
                "完了",
                MessageBoxButtons.OK,
                MessageBoxIcon.Information
            );
        }
    }
}
