using Notification.Wpf;
using System.Collections.ObjectModel;
using System.Runtime.CompilerServices;

namespace FeatureTracker
{
    public class NotifyDataChangedEventArgs(string? propertyName) : EventArgs
    {
        public string? PropertyName { get; private set; } = propertyName;
    }

    public delegate void NotifyDataChangedEventHandler(object sender, NotifyDataChangedEventArgs e);

    public interface IDataManager
    {
        void StartOperation();

        void StopOperation(bool saveData = false);

        void AddModel(Model model);

        void AddModelCollection<T>(ObservableCollection<T> collection) where T : Model;

        void RemoveModel(Model model);

        void RemoveModelCollection<T>(ObservableCollection<T> collection) where T : Model;

        void ShowToast(string title, string message, NotificationType type = NotificationType.Success, TimeSpan? duration = null);
    }

    public abstract class Model : NotifyPropertyChanged
    {
        public abstract string[] ModelProperties { get; }

        public abstract string[] ModelCollectionProperties { get; }

        public abstract IDataManager? DataManager { get; set; }

        public void OnDataChanged([CallerMemberName] string? propertyName = null)
        {
            DataChanged?.Invoke(this, new NotifyDataChangedEventArgs(propertyName));
        }

        public event NotifyDataChangedEventHandler? DataChanged;
    }

    public class SortableModelCollection<T> : ObservableCollection<T> where T : Model
    {
        public void SortBy(IComparer<T> comparer)
        {
            var sortableList = new List<T>(this);
            Clear();
            foreach (var item in sortableList.OrderBy(model => model, comparer))
            {
                Add(item);
            }
        }
    }

    public class PageComparer : IComparer<Page>
    {
        public enum CompareMode
        {
            Name = 0,
            Features,
            Count,
        }

        PageComparer(CompareMode mode)
        {
            this.mode = mode;
        }

        readonly CompareMode mode;

        public int Compare(Page? x, Page? y)
        {
            if (x == null && y == null) return 0;
            if (x == null) return -1;
            if (y == null) return 1;
            return mode switch
            {
                CompareMode.Name => string.Compare(x.Name, y.Name),
                CompareMode.Features => (x.Features.Count != y.Features.Count) ? (y.Features.Count - x.Features.Count) : string.Compare(x.Name, y.Name),
                CompareMode.Count => (x.Count != y.Count) ? (y.Count - x.Count) : string.Compare(x.Name, y.Name),
                _ => 0
            };
        }

        public static PageComparer NameComparer { get; } = new(CompareMode.Name);
        public static PageComparer FeaturesComparer { get; } = new(CompareMode.Features);
        public static PageComparer CountComparer { get; } = new(CompareMode.Count);
    }

    public class FeatureComparer : IComparer<Feature>
    {
        public enum CompareMode
        {
            Date = 0,
        }

        FeatureComparer(CompareMode mode)
        {
            this.mode = mode;
        }

        readonly CompareMode mode;

        public int Compare(Feature? x, Feature? y)
        {
            if (x == null && y == null) return 0;
            if (x == null) return -1;
            if (y == null) return 1;
            return mode switch
            {
                CompareMode.Date => DateTime.Compare(y.Date, x.Date),
                _ => 0,
            };
        }

        public static FeatureComparer DateComparer { get; } = new(CompareMode.Date);
    }
}
