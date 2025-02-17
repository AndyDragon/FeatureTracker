using System.Globalization;
using System.Windows.Data;
using System.Windows;

namespace FeatureTracker
{
    public class BooleanToVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (!bool.TryParse(parameter as string, out var visibleValue))
            {
                visibleValue = true;
            }
            if (value is bool boolValue)
            {
                return (boolValue == visibleValue) ? Visibility.Visible : Visibility.Collapsed;
            }
            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
