using System.Windows;

namespace FeatureTracker
{
    /// <summary>
    /// Interaction logic for BlankPage.xaml
    /// </summary>
    public partial class BlankPage : System.Windows.Controls.Page
    {
        public BlankPage(BlankViewModel viewModel)
        {
            InitializeComponent();
            DataContext = viewModel;
        }
    }

    public class BlankViewModel : NotifyPropertyChanged
    {
        public Visibility SummaryVisibility => MainViewModel != null ? Visibility.Visible : Visibility.Collapsed;

        private MainViewModel? mainViewModel;
        public MainViewModel? MainViewModel
        {
            get => mainViewModel;
            set
            {
                if (Set(ref mainViewModel, value))
                {
                    OnPropertyChanged(nameof(SummaryVisibility));
                }
            }
        }

        private string? message;
        public string? Message
        {
            get => message;
            set => Set(ref message, value);
        }
    }
}
