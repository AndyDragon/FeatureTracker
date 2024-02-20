using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.UI.Xaml.Data;

namespace FeatureTracker
{
    public class FeatureSortConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            if (!(value is IEnumerable<Feature> features))
            {
                return value;
            }
            return features.OrderBy(feature => feature, FeatureComparer.DateComparer);
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }

    public class FeatureComparer : IComparer<Feature>
    {
        enum CompareMode
        {
            Date,
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
                    return DateTime.Compare(x.Date, y.Date);
            }
            return 0;
        }

        private static readonly FeatureComparer dateComparer = new FeatureComparer(CompareMode.Date);
        public static FeatureComparer DateComparer { get => dateComparer; }
    }
}
