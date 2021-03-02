using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace InsertingNumberServices
{
    /// <summary>
    /// Расположение данных относительно пояснений.
    /// </summary>
    public struct LocationValue
    {
        /// <summary>
        /// Пояснение.
        /// </summary>
        public string caption;
        /// <summary>
        /// Смещение значения относительно пояснения по строке.
        /// </summary>
        public int offestRow;
        /// <summary>
        /// Смещение значения относительно пояснения по столбцу.
        /// </summary>
        public int offestColumn;
        /// <summary>
        /// Значение.
        /// </summary>
        public string value;
    }

    /// <summary>
    /// Парсер листа, на котором располагается информация об одном человеке.
    /// </summary>
    public static class ParserFile
    {
        /////////////////////////////////Public методы/////////////////////////////////

        /// <summary>
        /// Найти значения в файле и установить их.
        /// </summary>
        /// <param name="sheet">Страница</param>
        /// <param name="value">Расположения значений относительно пояснений</par
        public static void setValue(string[,] sheet, ref LocationValue [] value) {

            for (int i = 0; i < value.Length; i++) {
                value[i].value = getValue(sheet, value[i]);
            }
        }

        /////////////////////////////////Private методы/////////////////////////////////
        
        /// <summary>
        /// Получене значения.
        /// </summary>
        /// <param name="sheet">Страница</param>
        /// <param name="value">Расположение значения относительно пояснения</param>
        /// <returns>Значение</returns>
        private static string getValue(string[,] sheet, LocationValue value) {
            for (int i = 0; i < sheet.GetLength(0); i++) {
                for (int j = 0; j > sheet.GetLength(1); j++) {
                    if (sheet[i, j] == value.caption) {
                        if (i + value.offestRow >= 0 && i + value.offestRow < sheet.GetLength(0)) {
                            if (j + value.offestColumn >= 0 && j + value.offestColumn < sheet.GetLength(1)) {
                                return sheet[i, j];
                            }
                        }
                    }
                }
            }
            return "";
        }
    }
}
