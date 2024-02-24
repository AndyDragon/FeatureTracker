﻿using System;
using System.Globalization;
using System.Windows.Data;

namespace FeatureTracker
{
    public class DateTimeConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return new DateTimeOffset(((DateTime)value).ToUniversalTime());

        }

        public object ConvertBack(object value, Type targetType, object parameter,  CultureInfo culture)
        {
            return ((DateTimeOffset)value).DateTime;
        }
    }
}
