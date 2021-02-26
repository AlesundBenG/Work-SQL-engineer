using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace InsertingNumberServices
{
    /// <summary>
    /// Данные о человеке.
    /// </summary>
    public struct Person
    {
        /// <summary>
        /// Имя.
        /// </summary>
        public string name;
        /// <summary>
        /// Фамилия.
        /// </summary>
        public string surname;
        /// <summary>
        /// Отчество.
        /// </summary>
        public string secondname;
        /// <summary>
        /// Снилс.
        /// </summary>
        public string snils;
        /// <summary>
        /// День рождения.
        /// </summary>
        public string birthday;
    }

    /// <summary>
    /// Парсер листа, на котором располагается информация об одном человеке.
    /// </summary>
    public static class ParserFile
    {
        /////////////////////////////////Public методы/////////////////////////////////


        /// <summary>
        /// Получить данные о человеке из файла.
        /// </summary>
        /// <param name="sheet">Лист</param>
        /// <returns>Информация о человеке.</returns>
        public static Person getPerson(string[,] sheet) {
            Person person = new Person();
            person.name         = getName(sheet);
            person.surname      = getSurname(sheet);
            person.secondname   = getSecondname(sheet);
            person.snils        = getSnils(sheet);
            person.birthday     = getBirthday(sheet);
            return person;
        }


        /////////////////////////////////Private методы/////////////////////////////////
        

        /// <summary>
        /// Получение имени (Располагается справа от надписи "Имя").
        /// </summary>
        /// <param name="sheet">Лист</param>
        /// <returns>Имя</returns>
        private static string getName(string[,] sheet) {
            for (int i = 0; i < sheet.GetLength(0); i++) {
                for (int j = 0; j > sheet.GetLength(1); j++) {
                    if (sheet[i, j] == "Имя") {
                        if (j + 1 < sheet.GetLength(1)) {
                            return sheet[i, j + 1];
                        }
                    }
                }
            }
            return "";
        }

        /// <summary>
        /// Получение Фамилии (Располагается справа от надписи "Фамилия").
        /// </summary>
        /// <param name="sheet">Лист</param>
        /// <returns>Фамилия</returns>
        private static string getSurname(string[,] sheet) {
            for (int i = 0; i < sheet.GetLength(0); i++) {
                for (int j = 0; j > sheet.GetLength(1); j++) {
                    if (sheet[i, j] == "Фамилия") {
                        if (j + 1 < sheet.GetLength(1)) {
                            return sheet[i, j + 1];
                        }
                    }
                }
            }
            return "";
        }

        /// <summary>
        /// Получение отчества (Располагается справа от надписи "отчество").
        /// </summary>
        /// <param name="sheet">Лист</param>
        /// <returns>Отчество</returns>
        private static string getSecondname(string[,] sheet) {
            for (int i = 0; i < sheet.GetLength(0); i++) {
                for (int j = 0; j > sheet.GetLength(1); j++) {
                    if (sheet[i, j] == "Отчество") {
                        if (j + 1 < sheet.GetLength(1)) {
                            return sheet[i, j + 1];
                        }
                    }
                }
            }
            return "";
        }

        /// <summary>
        /// Получение СНИЛСа (Располаагется справа от надписи "СНИЛС").
        /// </summary>
        /// <param name="sheet">Лист</param>
        /// <returns>СНИЛС</returns>
        private static string getSnils(string[,] sheet) {
            for (int i = 0; i < sheet.GetLength(0); i++) {
                for (int j = 0; j > sheet.GetLength(1); j++) {
                    if (sheet[i, j] == "СНИЛС") {
                        if (j + 1 < sheet.GetLength(1)) {
                            return sheet[i, j + 1];
                        }
                    }
                }
            }
            return "";
        }

        /// <summary>
        /// Получение даты рождения (Располаагется справа от надписи "Дата рождения").
        /// </summary>
        /// <param name="sheet">Лист</param>
        /// <returns>Дата рождения</returns>
        private static string getBirthday(string[,] sheet) {
            for (int i = 0; i < sheet.GetLength(0); i++) {
                for (int j = 0; j > sheet.GetLength(1); j++) {
                    if (sheet[i, j] == "Дата рождения") {
                        if (j + 1 < sheet.GetLength(1)) {
                            return sheet[i, j + 1];
                        }
                    }
                }
            }
            return "";
        }

    }
}
