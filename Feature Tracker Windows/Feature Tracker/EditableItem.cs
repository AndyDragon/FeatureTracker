using System.Windows;
using MahApps.Metro.IconPacks;

namespace FeatureTracker
{
    public abstract class EditableModel : Model
    {
        private string icon = "";
        public string Icon
        {
            get => icon;
            set => Set(ref icon, value);
        }

        private string title = "";
        public string Title
        {
            get => title;
            set => Set(ref title, value);
        }

        private string subTitle = "";
        public string SubTitle
        {
            get => subTitle;
            set => Set(ref subTitle, value);
        }

        private string alternativeTitle = "";
        public string AlternativeTitle
        {
            get => alternativeTitle;
            set => Set(ref alternativeTitle, value);
        }

        private PackIconModernKind iconKind = PackIconModernKind.Box;
        public PackIconModernKind IconKind
        {
            get => iconKind;
            set => Set(ref iconKind, value);
        }

        private FontWeight fontWeight = FontWeights.Normal;
        public FontWeight FontWeight
        {
            get => fontWeight;
            set => Set(ref fontWeight, value);
        }

        private Func<object, System.Windows.Controls.Page>? editorPageFactory = null;
        public Func<object, System.Windows.Controls.Page>? EditorPageFactory
        {
            get => editorPageFactory;
            set => Set(ref editorPageFactory, value);
        }
    }
}
