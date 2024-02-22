using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Linq;
using Windows.UI.Xaml.Data;

namespace FeatureTracker
{
    public class PageSortConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            if (value is ObservableCollection<Page> pagesCollection)
            {
                //var hookedPages = new List<Page>();
                var observableCollection = new ObservableCollection<Page>();
                void PopulateResults()
                {
                    foreach (var page in pagesCollection.OrderBy(page => page, PageComparer.FeaturesComparer))
                    {
                        //page.DataChanged += RepopulateResults;
                        //page.Features.CollectionChanged += RepopulateResults;
                        //hookedPages.Add(page);
                        observableCollection.Add(page);
                    }
                }
                void RepopulateResults(object sender, EventArgs e)
                {
                    //Debug.WriteLine("Repopulate pages by " + e.GetType().Name);

                    // Should filter this based on sorting

                    //foreach (var hookedPage in hookedPages)
                    //{
                    //    hookedPage.DataChanged -= RepopulateResults;
                    //    hookedPage.Features.CollectionChanged -= RepopulateResults;
                    //}
                    //hookedPages.Clear();
                    observableCollection.Clear();
                    PopulateResults();
                }
                PopulateResults();
                pagesCollection.CollectionChanged += RepopulateResults;
                return observableCollection;
            }
            if (value is IEnumerable<Page> pages)
            {
                return pages.OrderBy(page => page, PageComparer.FeaturesComparer);
            }
            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }

    public class PageComparer : IComparer<Page>
    {
        enum CompareMode
        {
            Name,
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
}
