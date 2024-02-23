using System;
using Windows.UI.Xaml.Navigation;

namespace FeatureTracker
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class FeatureEditor : Windows.UI.Xaml.Controls.Page
    {
        public FeatureEditor()
        {
            this.InitializeComponent();
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);

            if (DataContext is MainViewModel viewModel && e.Parameter is Feature feature)
            {
                ConnectFeature(viewModel, feature);
            }
        }

        private void ConnectFeature(MainViewModel viewModel, Feature feature)
        {
            feature.PropertyChanged += (sender, e) =>
            {
            };
        }
    }
}
