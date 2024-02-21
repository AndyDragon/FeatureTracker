using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using Windows.UI.Xaml.Data;

namespace FeatureTracker
{
    public class FeatureSortConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            if (value is ObservableCollection<Feature> featuresCollection)
            {
                var hookedFeatures = new List<Feature>();
                var observableCollection = new ObservableCollection<Feature>();
                void PopulateResults()
                {
                    foreach (var feature in featuresCollection.OrderBy(feature => feature, FeatureComparer.DateComparer))
                    {
                        feature.DataChanged += RepopulateResults;
                        hookedFeatures.Add(feature);
                        observableCollection.Add(feature);
                    }
                }
                void RepopulateResults(object sender, EventArgs e)
                {
                    // Should filter this based on sorting

                    foreach (var hookedFeature in hookedFeatures)
                    {
                        hookedFeature.DataChanged -= RepopulateResults;
                    }
                    hookedFeatures.Clear();
                    observableCollection.Clear();
                    PopulateResults();
                };
                PopulateResults();
                featuresCollection.CollectionChanged += RepopulateResults;
                return observableCollection;
            }
            if (value is IEnumerable<Feature> features)
            {
                return features.OrderBy(feature => feature, FeatureComparer.DateComparer);
            }
            return value;
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
                    return DateTime.Compare(y.Date, x.Date);
            }
            return 0;
        }

        private static readonly FeatureComparer dateComparer = new FeatureComparer(CompareMode.Date);
        public static FeatureComparer DateComparer { get => dateComparer; }
    }
}
