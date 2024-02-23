using System;
using Windows.UI.Xaml.Navigation;

namespace FeatureTracker
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class BlankPage : Windows.UI.Xaml.Controls.Page
    {
        public BlankPage()
        {
            this.InitializeComponent();
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);
            DataContext = e.Parameter;
        }
    }

    public class BlankViewModel : NotifyPropertyChanged
    {
        private string message;
        public string Message
        {
            get => message;
            set => Set(ref message, value);
        }
    }
}
