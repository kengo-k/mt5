using System;
using System.IO;
using System.Text;
using System.Text.Json;
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
        private bool isSaveResultRequired = true;

        [DllImport("kernel32.dll", EntryPoint = "GetPrivateProfileStringW", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern uint GetPrivateProfileString(string lpAppName, string lpKeyName, string lpDefault, StringBuilder lpReturnedString, uint nSize, string lpFileName);

        public MainWindow()
        {
            InitializeComponent();
            InitializeAccountPulldown();
            EnableDragDrop();

            // setup mt5 config file path
            string? tempDir = Environment.GetEnvironmentVariable("TEMP");
            if (tempDir != null)
            {
                this.mt5ConfigPath = $"{tempDir}\\config.ini";
            }

        }

        public void InitializeAccountPulldown()
        {
            ApplicationConfig? configObj = LoadApplicationConfig();
            if (configObj == null)
            {
                return;
            }
            string[] loginIds = configObj.LoginIds;
            ComboBox pulldown1 = this.GetPulldownControl();
            foreach (string loginId in loginIds)
            {
                pulldown1.Items.Add(loginId);
            }
            pulldown1.SelectedIndex = 0;
        }

        private void EnableDragDrop()
        {
            TextBox control = GetTextControl("text1");
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
                    // set dropped file content text control
                    string[] paths = ((string[])e.Data.GetData(DataFormats.FileDrop));
                    using StreamReader sr = new(paths[0], Encoding.GetEncoding("UTF-8"));
                    string content = sr.ReadToEnd();
                    sr.Close();

                    // publish dropped file content in .ini file
                    control.Text = content;
                    PublishMT5Config(content);

                    // set description text
                    TextBox descText = GetTextControl("text2");
                    string currency = GetMT5ConfigValue("Tester", "Symbol");
                    string from = GetMT5ConfigValue("Tester", "FromDate");
                    string to = GetMT5ConfigValue("Tester", "ToDate");
                    descText.Text = $"{currency}_{from.Replace(".", "")}_{to.Replace(".", "")}";
                }
            };
        }

        private void PublishMT5Config(string content)
        {
            using StreamWriter sw = new(this.mt5ConfigPath, false, Encoding.GetEncoding("UTF-8"));
            sw.Write(content);
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            // load application config
            ApplicationConfig? configObj = LoadApplicationConfig();
            if (configObj == null)
            {
                return;
            }

            // publish latest content in .ini file
            TextBox control = GetTextControl("text1");
            PublishMT5Config(control.Text);

            // delete all files in TerminalOutputDir
            foreach(string f in Directory.GetFiles(configObj.TerminalOutputDir))
            {
                FileSystem.DeleteFile(f);
            }

            // run mt5 back test
            RunTest(configObj, this.mt5ConfigPath);
            if (!isSaveResultRequired)
            {
                return;
            }

            // move test result to dest dir
            DateTime dt = DateTime.Now;
            string optimized = GetMT5ConfigValue("Tester", "Optimization");
            TextBox descText = GetTextControl("text2");
            string desc = descText.Text;
            string movedDir = $"{dt.ToString("yyyy-MM-dd_HH-mm-ss")}_{desc}";
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

        private void RunTest(ApplicationConfig appConfig, string mt5ConfigPath)
        {
            ComboBox pulldown = this.GetPulldownControl();
            string? pulldownItem = pulldown.SelectedValue as string;
            if (pulldownItem is null)
            {
                return;
            }

            ProcessStartInfo pInfo = new()
            {
                FileName = appConfig.TerminalPath,
                Arguments = $"/config:{mt5ConfigPath} /login:{pulldownItem.Split(":")[1]}"
            };
            Process? p = Process.Start(pInfo);
            if (p == null)
            {
                return;
            }
            p.WaitForExit();
        }

        string GetMT5ConfigValue(string section, string key, string defaultValue = "")
        {
            StringBuilder sb = new(256);
            GetPrivateProfileString(section, key, "0", sb, Convert.ToUInt32(sb.Capacity), this.mt5ConfigPath);
            return sb.ToString();
        }

        private static ApplicationConfig? LoadApplicationConfig()
        {
            byte[] config = Properties.Resources.config;
            string configStr = Encoding.UTF8.GetString(config);
            ApplicationConfig? configObj = JsonSerializer.Deserialize<ApplicationConfig>(configStr);
            return configObj;
        }

        private TextBox GetTextControl(string name)
        {
            return (TextBox)FindName(name);
        }

        private ComboBox GetPulldownControl()
        {
            return (ComboBox)FindName("pulldown1");
        }

        private void CheckBox_Checked(object sender, RoutedEventArgs e)
        {
            CheckBox? checkBox = sender as CheckBox;
            if (checkBox == null)
            {
                return;
            }
            bool? isChecked = checkBox.IsChecked;
            if (isChecked == null)
            {
                isSaveResultRequired = false;
            } else
            {
                isSaveResultRequired = (bool)isChecked;
            }
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
