using System.Windows;
using ControlzEx.Theming;

namespace FeatureTracker
{
    /// <summary>
    /// Interaction logic for App.xaml
    /// </summary>
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            var lastThemeName = UserSettings.GetString("theme");
            if (!string.IsNullOrEmpty(lastThemeName))
            {
                ThemeManager.Current.ChangeTheme(this, lastThemeName);
            }
        }
    }
}
