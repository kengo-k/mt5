using System;

namespace MT5Lib
{
    public class DateUtil
    {
        public static string GetCurrentDate(string format)
        {
            DateTime dt = DateTime.Now;
            string result = dt.ToString(format);
            return result;
        }

        public static string GetCurrentDate()
        {
            return DateUtil.GetCurrentDate("yyyy-MM-dd_HHmm");
        }
    }
}
