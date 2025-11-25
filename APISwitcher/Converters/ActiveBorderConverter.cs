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
            return new SolidColorBrush(Color.FromRgb(46, 125, 50)); // 深绿色边框
        }
        return new SolidColorBrush(Color.FromRgb(159, 167, 179)); // 更明显的浅灰边框
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
