using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Runtime.CompilerServices;

namespace FeatureTracker
{
    public class NotifyDataChangedEventArgs : EventArgs
    {
        public NotifyDataChangedEventArgs(string propertyName) 
        { 
            PropertyName = propertyName;
        }

        public string PropertyName { get; private set; }
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
    }

    public abstract class Model : NotifyPropertyChanged
    {
        public abstract string[] ModelProperties { get; }

        public abstract string[] ModelCollectionProperties { get; }
        
        public abstract IDataManager DataManager { get; set; }

        public void OnDataChanged([CallerMemberName] string propertyName = null)
        {
            DataChanged?.Invoke(this, new NotifyDataChangedEventArgs(propertyName));
        }

        public event NotifyDataChangedEventHandler DataChanged;
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

        public int Compare(Page x, Page y)
        {
            switch (mode)
            {
                case CompareMode.Name:
                    return string.Compare(x.Name, y.Name);
                case CompareMode.Features:
                    if (x.Features.Count != y.Features.Count)
                    {
                        return y.Features.Count - x.Features.Count;
                    }
                    return string.Compare(x.Name, y.Name);
                case CompareMode.Count:
                    if (x.Count != y.Count)
                    {
                        return y.Count - x.Count;
                    }
                    return string.Compare(x.Name, y.Name);
            }
            return 0;
        }

        private static readonly PageComparer nameComparer = new PageComparer(CompareMode.Name);
        public static PageComparer NameComparer { get => nameComparer; }

        private static readonly PageComparer featuresComparer = new PageComparer(CompareMode.Features);
        public static PageComparer FeaturesComparer { get => featuresComparer; }

        private static readonly PageComparer countComparer = new PageComparer(CompareMode.Count);
        public static PageComparer CountComparer { get => countComparer; }
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

        public int Compare(Feature x, Feature y)
        {
            switch (mode)
            {
                case CompareMode.Date:
                    return DateTime.Compare(y.Date, x.Date);
            }
            return 0;
        }

        private static readonly FeatureComparer dateComparer = new FeatureComparer(CompareMode.Date);
        public static FeatureComparer DateComparer { get => dateComparer; }
    }
}
