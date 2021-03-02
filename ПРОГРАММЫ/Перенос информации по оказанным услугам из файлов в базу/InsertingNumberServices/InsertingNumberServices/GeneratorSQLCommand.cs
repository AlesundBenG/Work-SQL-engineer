using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace InsertingNumberServices
{
    /// <summary>
    /// Класс для формирования SQL запросов.
    /// </summary>
    public static class GeneratorSQLCommand
    {
        /////////////////////////////////Структуры/////////////////////////////////


        /// <summary>
        /// Входной параметр для запроса.
        /// </summary>
        public struct InputParametrs
        {
            /// <summary>
            /// Код параметра.
            /// </summary>
            public string code;
            /// <summary>
            /// Значение параметра.
            /// </summary>
            public string value;
        }


        /////////////////////////////////Public методы/////////////////////////////////


        /// <summary>
        /// Генерация SQl запроса из скрипта.
        /// </summary>
        /// <param name="pathScript">Путь к скрипту</param>
        /// <param name="parametrs">Входные параметры скрипта</param>
        /// <returns>Сгенерированная SQL команда</returns>
        public static string getCommand(string pathScript, InputParametrs [] parametrs) {
            string command = "";
            //Чтение из файла.
            using (FileStream filestream = File.OpenRead(pathScript)) {
                //Преобразуем строку в байты
                byte[] array = new byte[filestream.Length];
                // считываем данные.
                filestream.Read(array, 0, array.Length);
                //Декодируем байты в строку.
                command = Encoding.UTF8.GetString(array);
            }
            //Вставка значений.
            return insertParametrs(command, parametrs); ;
        }


        /////////////////////////////////Private методы/////////////////////////////////


        /// <summary>
        /// Вставка значений параметров.
        /// </summary>
        /// <param name="command">SQL запрос</param>
        /// <param name="parametrs">Входные параметры</param>
        private static string insertParametrs(string command, InputParametrs[] parametrs) {
            for (int i = 0; i < parametrs.Length; i++) {
                command = command.Replace(parametrs[i].code, parametrs[i].value);
            }
            return command;
        }
    }
}
