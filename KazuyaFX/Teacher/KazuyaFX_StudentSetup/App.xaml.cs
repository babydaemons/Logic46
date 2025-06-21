using System;
using System.Collections.Generic;
using System.IO;
using System.Windows;

namespace KazuyaFX_StudentSetup
{
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);
            var terminalDirectories = EnumerateTerminalDirectories();
            var links = EnumerateMT4(terminalDirectories);
            
            // MainWindowを開く
            var mainWindow = new MainWindow();
            mainWindow.Show();
        }

        private Dictionary<string, string> EnumerateMT4(Dictionary<string, string> terminalDirectories)
        {
            var links = new Dictionary<string, string>();
            const string desktopPath = @"C:\Users\Public\Desktop";
            var shortcutFiles = Directory.GetFiles(desktopPath, "*.lnk", SearchOption.TopDirectoryOnly);
            foreach (var shortcutFile in shortcutFiles)
            {
                var link = WindowsShortcutFactory.WindowsShortcut.Load(shortcutFile);
                if (string.IsNullOrEmpty(link.Path)) continue;
                if (!link.Path.StartsWith(@"C:\Program Files (x86)\")) continue;
                if (!link.Path.EndsWith(@"terminal.exe")) continue;
                var appName = Path.GetFileNameWithoutExtension(shortcutFile);
                var appPath = Path.GetDirectoryName(link.Path);
                if (string.IsNullOrEmpty(appPath)) continue;
                if (!File.Exists(Path.Combine(appPath, "terminal.ico"))) continue;
                if (!File.Exists(Path.Combine(appPath, "metaeditor.exe"))) continue;
                if (!terminalDirectories.ContainsKey(appPath)) continue;
                links.Add(appName, terminalDirectories[appPath]);
            }
            return links;
        }

        private Dictionary<string, string> EnumerateTerminalDirectories()
        {
            var terminalDirectories = new Dictionary<string, string>();
            var appDataPath = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            var terminalRootPath = Path.Combine(appDataPath, "MetaQuotes", "Terminal");
            var terminalPaths = Directory.GetDirectories(terminalRootPath, "????????????????????????????????", SearchOption.TopDirectoryOnly);
            foreach (var terminalPath in terminalPaths)
            {
                var originText = Path.Combine(terminalPath, "origin.txt");
                if (!File.Exists(originText)) continue;

                var line = File.ReadAllText(originText).Trim();
                if (string.IsNullOrEmpty(line)) continue;
                terminalDirectories.Add(line, terminalPath);
            }
            return terminalDirectories;
        }
    }
}
