using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace FeatureTracker
{
    public class GridLengthRemainingConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            if (values.Length == 2)
            {
                double gridLength = (double)values[0];
                double otherColumnLength = (double)values[1];
                return new GridLength(gridLength - otherColumnLength, GridUnitType.Pixel);
            }
            return new GridLength(1, GridUnitType.Star);
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
