using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.UI.Xaml.Data;

namespace FeatureTracker
{
    public class ArrayCountToStringConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            var valueAsEnumerable = value as IEnumerable<object>;
            var featureLabel = parameter as string;
            if (valueAsEnumerable.Count() != 1)
            {
                featureLabel += "s";
            }
            return $"({valueAsEnumerable.Count()} {featureLabel})";
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }
}
