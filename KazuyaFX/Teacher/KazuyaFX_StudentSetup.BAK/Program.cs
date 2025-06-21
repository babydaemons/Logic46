using System;
using System.Collections.Generic;
using System.IO;
using System.Windows.Forms;
using WindowsShortcutFactory;

namespace KazuyaFX_StudentSetup
{
    internal static class Program
    {
        /// <summary>
        ///  The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            var terminalDirectories = EnumerateTerminalDirectories();
            var links = EnumerateMT4(terminalDirectories);

            // To customize application configuration such as set high DPI settings or default font,
            // see https://aka.ms/applicationconfiguration.
            // ApplicationConfiguration.Initialize();
            Application.Run(new Form1());
        }

        static Dictionary<string, string> EnumerateMT4(Dictionary<string, string> terminalDirectories)
        {
            var links = new Dictionary<string, string>();
            const string desktopPath = @"C:\Users\Public\Desktop";
            var shortcutFiles = Directory.GetFiles(desktopPath, "*.lnk", SearchOption.TopDirectoryOnly);
            foreach (var shortcutFile in shortcutFiles)
            {
                var link = WindowsShortcut.Load(shortcutFile);
                if (string.IsNullOrEmpty(link.Path))
                {
                    continue;
                }
                if (!link.Path.StartsWith(@"C:\Program Files (x86)\"))
                {
                    continue;
                }
                if (!link.Path.EndsWith(@"terminal.exe"))
                {
                    continue;
                }
                var appName = Path.GetFileName(shortcutFile).Replace(".lnk", "");
                var appPath = Path.GetDirectoryName(link.Path);
                if (string.IsNullOrEmpty(appPath))
                {
                    continue;
                }
                if (!File.Exists(Path.Combine(appPath, "terminal.ico")))
                {
                    continue;
                }
                if (!File.Exists(Path.Combine(appPath, "metaeditor.exe")))
                {
                    continue;
                }
                if (!terminalDirectories.ContainsKey(appPath))
                {
                    continue;
                }
                links.Add(appName, terminalDirectories[appPath]);
            }
            return links;
        }

        static Dictionary<string, string> EnumerateTerminalDirectories()
        {
            var terminalDirectories = new Dictionary<string, string>();
            var appDataPath = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
            var terminalRootPath = Path.Combine(appDataPath, "MetaQuotes", "Terminal");
            var terminalPaths = Directory.GetDirectories(terminalRootPath, "????????????????????????????????", SearchOption.TopDirectoryOnly);
            foreach (var terminalPath in terminalPaths)
            {
                var originText = Path.Combine(terminalPath, "origin.txt");
                if (string.IsNullOrEmpty(originText))
                {
                    continue;
                }
                if (!File.Exists(originText))
                {
                    continue;
                }
                var reader = new StreamReader(originText);
                var line = reader.ReadLine();
                if (string.IsNullOrEmpty(line))
                {
                    continue;
                }
                terminalDirectories.Add(line, terminalPath);
            }
            return terminalDirectories;
        }
    }
}