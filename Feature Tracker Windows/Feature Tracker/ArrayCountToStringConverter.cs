using System;
using System.Collections.Generic;
using System.Linq;
using Windows.UI.Xaml.Data;

namespace FeatureTracker
{
    public class ArrayCountToStringConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            var featureLabel = parameter as string;
            if (value is IEnumerable<object> objects)
            {
                if (objects.Count() != 1)
                {
                    featureLabel += "s";
                }
                return $"({objects.Count()} {featureLabel})";
            }
            return "0";
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }
}
