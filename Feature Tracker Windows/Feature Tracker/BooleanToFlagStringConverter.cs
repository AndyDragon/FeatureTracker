using System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Data;

namespace FeatureTracker
{
    public class BooleanToFlagStringConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            if ((bool)value)
            {
                return (string)parameter;
            }
            return "";
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
        {
            throw new NotImplementedException();
        }
    }
}
