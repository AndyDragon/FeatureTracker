﻿using System;
using System.Globalization;
using System.Windows.Data;

namespace FeatureTracker
{
    public class ObjectToEditableModelConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return value;
        }

        public object? ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value != null)
            {
                if (value is Page)
                {
                    return value as Page;
                }
                if (value is Feature)
                {
                    return value as Feature;
                }
            }
            return value;
        }
    }
}
