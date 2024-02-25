using System.Windows;
using ControlzEx.Theming;

namespace FeatureTracker
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow
    {
        public static readonly BlankViewModel blankViewModel = new() { Message = "Select a page" };

        public MainWindow()
        {
            InitializeComponent();

            if (DataContext is MainViewModel viewModel)
            {
                blankViewModel.MainViewModel = viewModel;
                var lastThemeName = UserSettings.GetString("theme");
                if (!string.IsNullOrEmpty(lastThemeName))
                {
                    var theme = ThemeManager.Current.Themes.FirstOrDefault(theme => string.Equals(theme.Name, lastThemeName));
                    if (theme != null)
                    {
                        ThemeManager.Current.ChangeTheme(Application.Current, theme);
                        viewModel.ResetTheme(theme);
                    }
                }

                ConnectViewModel(viewModel);
            }

            EditorFrame.Navigate(new BlankPage(blankViewModel));
        }

        private void ConnectViewModel(MainViewModel viewModel)
        {
            viewModel.PropertyChanged += (sender, e) =>
            {
                if (e.PropertyName == "SelectedPage")
                {
                    if (viewModel.SelectedPage != null && viewModel.SelectedPage.EditorPageFactory != null)
                    {
                        EditorFrame.Navigate(viewModel.SelectedPage.EditorPageFactory(viewModel));
                        PageList.ScrollIntoView(viewModel.SelectedPage);
                    }
                    else
                    {
                        EditorFrame.Navigate(new BlankPage(blankViewModel));
                    }
                }
            };
        }
    }
}