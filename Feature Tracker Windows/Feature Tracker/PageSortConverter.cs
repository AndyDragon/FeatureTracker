using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.UI.Xaml.Data;

namespace FeatureTracker
{
    public class PageSortConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            if (!(value is IEnumerable<Page> pages))
            {
                return value;
            }
            return pages.OrderBy(page => page, PageComparer.FeaturesComparer);
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

        CompareMode mode;

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
