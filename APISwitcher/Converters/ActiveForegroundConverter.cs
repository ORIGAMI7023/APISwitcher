using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace APISwitcher.Converters;

public class ActiveForegroundConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        if (value is bool isActive && isActive)
        {
            // 激活状态：深色文字
            return new SolidColorBrush(Color.FromRgb(51, 51, 51));
        }
        // 未激活状态：稍浅的深色文字，确保在白色背景上可见
        return new SolidColorBrush(Color.FromRgb(66, 66, 66));
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
