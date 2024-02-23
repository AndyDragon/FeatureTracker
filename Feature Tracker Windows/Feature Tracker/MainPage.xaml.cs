using System;
using Windows.UI.Xaml.Media.Animation;
using Windows.UI.Xaml.Navigation;

namespace FeatureTracker
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class MainPage : Windows.UI.Xaml.Controls.Page
    {
        public static readonly BlankViewModel blankViewModel = new BlankViewModel { Message = "Select a page" };

        public MainPage()
        {
            this.InitializeComponent();
            EditorFrame.Navigate(typeof(BlankPage), blankViewModel, new DrillInNavigationTransitionInfo());
        }

        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            base.OnNavigatedTo(e);

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
                    if (viewModel.SelectedPage != null && viewModel.SelectedPage.EditorPageType != null)
                    {
                        EditorFrame.Navigate(viewModel.SelectedPage.EditorPageType, viewModel.SelectedPage, new DrillInNavigationTransitionInfo());
                        MenuList.ScrollIntoView(viewModel.SelectedPage);
                    }
                    else
                    {
                        EditorFrame.Navigate(typeof(BlankPage), blankViewModel, new DrillInNavigationTransitionInfo());
                    }
                }
            };
        }
    }
}
