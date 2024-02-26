namespace FeatureTracker
{
    /// <summary>
    /// Interaction logic for PageEditor.xaml
    /// </summary>
    public partial class PageEditor : System.Windows.Controls.Page
    {
        public static readonly BlankViewModel blankViewModel = new() { Message = "Select a feature from the list" };

        public PageEditor(MainViewModel? viewModel)
        {
            InitializeComponent();
            DataContext = viewModel;

            EditorFrame.Navigate(new BlankPage(blankViewModel));

            if (viewModel != null)
            {
                ConnectViewModel(viewModel);
            }
        }

        private void ConnectViewModel(MainViewModel viewModel)
        {
            if (viewModel.SelectedPage == null)
            {
                return;
            }
            viewModel.SelectedPage.PropertyChanged += (sender, e) =>
            {
                if (e.PropertyName == "SelectedFeature")
                {
                    if (viewModel.SelectedPage?.SelectedFeature != null && viewModel.SelectedPage?.SelectedFeature?.EditorPageFactory != null)
                    {
                        EditorFrame.Navigate(viewModel.SelectedPage.SelectedFeature.EditorPageFactory(viewModel));
                        FeatureList.ScrollIntoView(viewModel.SelectedPage.SelectedFeature);
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