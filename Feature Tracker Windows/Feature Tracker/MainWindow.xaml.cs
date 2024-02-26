namespace FeatureTracker
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow
    {
        public static readonly BlankViewModel blankViewModel = new() { Message = "Select a page from the list" };

        public MainWindow()
        {
            InitializeComponent();

            if (DataContext is MainViewModel viewModel)
            {
                blankViewModel.MainViewModel = viewModel;
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