using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace APISwitcher.Converters;

public class ActiveBackgroundConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        if (value is bool isActive && isActive)
        {
            return new SolidColorBrush(Color.FromRgb(223, 246, 227)); // 柔和的绿色高亮
        }
        return new SolidColorBrush(Color.FromRgb(242, 244, 248)); // 浅灰底方便区分
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
