using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace APISwitcher.Converters;

public class ActiveBorderConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        if (value is bool isActive && isActive)
        {
            return new SolidColorBrush(Color.FromRgb(76, 175, 80));
        }
        return new SolidColorBrush(Color.FromRgb(204, 204, 204));
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
