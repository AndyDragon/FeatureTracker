using System;
using Windows.UI.Xaml.Data;

namespace FeatureTracker
{
    public class ObjectToEditableModelConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, string language)
        {
            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, string language)
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
