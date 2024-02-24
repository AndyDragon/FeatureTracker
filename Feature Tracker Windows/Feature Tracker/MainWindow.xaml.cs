using MahApps.Metro.Controls;
using System.Diagnostics;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

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

            EditorFrame.Navigate(new BlankPage(blankViewModel));

            if (DataContext is MainViewModel viewModel)
            {
                ConnectViewModel(viewModel);
            }
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