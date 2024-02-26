namespace FeatureTracker
{
    /// <summary>
    /// Interaction logic for FeatureEditor.xaml
    /// </summary>
    public partial class FeatureEditor : System.Windows.Controls.Page
    {
        public FeatureEditor(MainViewModel? viewModel)
        {
            InitializeComponent();
            DataContext = viewModel;
        }
    }
}
