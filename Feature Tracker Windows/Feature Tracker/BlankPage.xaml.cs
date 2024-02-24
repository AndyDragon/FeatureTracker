using System;

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
        private string? message;
        public string? Message
        {
            get => message;
            set => Set(ref message, value);
        }
    }
}
