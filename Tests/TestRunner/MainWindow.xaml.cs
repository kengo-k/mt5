using System;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Windows;
using System.Windows.Controls;
using System.Runtime.InteropServices;
using System.Diagnostics;
using Microsoft.VisualBasic.FileIO;

namespace TestRunner
{

    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {

        private string mt5ConfigPath = "";

        [DllImport("kernel32.dll", EntryPoint = "GetPrivateProfileStringW", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern uint GetPrivateProfileString(string lpAppName, string lpKeyName, string lpDefault, StringBuilder lpReturnedString, uint nSize, string lpFileName);

        public MainWindow()
        {
            InitializeComponent();
            EnableDragDrop();
        }

        private TextBox GetTextControl()
        {
            return (TextBox)FindName("text1");
        }

        private void EnableDragDrop()
        {
            TextBox control = GetTextControl();
            control.AllowDrop = true;
            control.PreviewDragOver += (s, e) =>
            {
                e.Effects = (e.Data.GetDataPresent(DataFormats.FileDrop)) ? DragDropEffects.Copy : e.Effects = DragDropEffects.None;
                e.Handled = true;
            };
            control.PreviewDrop += (s, e) =>
            {
                if (e.Data.GetDataPresent(DataFormats.FileDrop))
                {
                    string[] paths = ((string[])e.Data.GetData(DataFormats.FileDrop));
                    using StreamReader sr = new StreamReader(paths[0], Encoding.GetEncoding("UTF-8"));
                    control.Text = sr.ReadToEnd();
                }
            };
        }

        string getMT5ConfigValue(string section, string key, string defaultValue = "")
        {
            StringBuilder sb = new(256);
            GetPrivateProfileString(section, key, "0", sb, Convert.ToUInt32(sb.Capacity), mt5ConfigPath);
            return sb.ToString();
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            TextBox control = GetTextControl();
            string content = control.Text;
            string? tempDir = Environment.GetEnvironmentVariable("TEMP");
            if (tempDir == null)
            {
                return;
            }

            // output text content in temp dir
            this.mt5ConfigPath = $"{tempDir}\\config.ini";
            using StreamWriter sw = new(this.mt5ConfigPath, false, Encoding.GetEncoding("UTF-8"));
            sw.Write(content);
            sw.Close();

            // load application config
            ApplicationConfig? configObj = LoadApplicationConfig();
            if (configObj == null)
            {
                return;
            }

            // run mt5 back test
            RunTest(configObj, mt5ConfigPath);

            // move test result to dest dir
            DateTime dt = DateTime.Now;
            string optimized = getMT5ConfigValue("Tester", "Optimization");
            string currency = getMT5ConfigValue("Tester", "Symbol");
            string from = getMT5ConfigValue("Tester", "FromDate");
            string to = getMT5ConfigValue("Tester", "ToDate");
            string movedDir = $"{dt.ToString("yyyy-MM-dd_HH-mm-ss")}_{currency}_{from.Replace(".", "")}_{to.Replace(".", "")}";
            if (optimized == "1")
            {
                movedDir = $"{movedDir}_optimize";
                FileSystem.MoveDirectory($"{configObj.CommonTerminalOutputDir}\\OptimizeResult", $"{configObj.TestResultDir}\\{movedDir}");
                FileSystem.MoveFile(this.mt5ConfigPath, $"{configObj.TestResultDir}\\{movedDir}\\config.ini");
                string[] files = Directory.GetFiles(configObj.TerminalOutputDir);
                foreach(string f in files)
                {
                    FileSystem.MoveFile($"{f}", $"{configObj.TestResultDir}\\{movedDir}\\{Path.GetFileName(f)}");
                }
            }
            else if (optimized == "0")
            {
                FileSystem.MoveDirectory($"{configObj.CommonTerminalOutputDir}\\TestResult", $"{configObj.TestResultDir}\\{movedDir}");
                FileSystem.MoveFile(this.mt5ConfigPath, $"{configObj.TestResultDir}\\{movedDir}\\config.ini");
                string[] files = Directory.GetFiles(configObj.TerminalOutputDir);
                foreach (string f in files)
                {
                    FileSystem.MoveFile($"{f}", $"{configObj.TestResultDir}\\{movedDir}\\{Path.GetFileName(f)}");
                }
            }
        }

        private static ApplicationConfig? LoadApplicationConfig()
        {
            byte[] config = Properties.Resources.config;
            string configStr = Encoding.UTF8.GetString(config);
            ApplicationConfig? configObj = JsonSerializer.Deserialize<ApplicationConfig>(configStr);
            return configObj;
        }

        private static void RunTest(ApplicationConfig appConfig, string mt5ConfigPath)
        {
            ProcessStartInfo pInfo = new()
            {
                FileName = appConfig.TerminalPath,
                Arguments = $"/config:{mt5ConfigPath} /login:70276582"
            };
            Process? p = Process.Start(pInfo);
            if (p == null)
            {
                return;
            }
            p.WaitForExit();
        }
    }



    public class ApplicationConfig
    {
        public string TerminalPath { get; set; } = string.Empty;

        public string TerminalOutputDir { get; set; } = string.Empty;

        public string CommonTerminalOutputDir { get; set; } = string.Empty;

        public string TestResultDir { get; set; } = string.Empty;

        public string[] LoginIds { get; set; } = Array.Empty<string>();
    }
}
