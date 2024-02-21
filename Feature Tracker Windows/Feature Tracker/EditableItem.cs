using System;
using Windows.UI.Xaml.Media;

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

        private SolidColorBrush foreground = new SolidColorBrush(Windows.UI.Colors.Black);
        public SolidColorBrush Foreground
        {
            get => foreground;
            set => Set(ref foreground, value);
        }

        private Type editorPageType = null;
        public Type EditorPageType
        {
            get => editorPageType;
            set => Set(ref editorPageType, value);
        }
    }
}
