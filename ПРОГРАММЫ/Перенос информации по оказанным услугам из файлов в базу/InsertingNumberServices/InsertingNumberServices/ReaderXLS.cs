using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Office.Interop.Excel;


namespace InsertingNumberServices
{
    /// <summary>
    /// Чтец XLS файлов.
    /// </summary>
    public class ReaderXLS
    {
        /////////////////////////////////Параметры/////////////////////////////////

        /// <summary>
        /// Путь к файлу.
        /// </summary>
        private string _pathFile;
        /// <summary>
        /// Страницы файла.
        /// </summary>
        private List<string[,]> _sheetsFile;

        /////////////////////////////////Свойства/////////////////////////////////

        /// <summary>
        /// Путь к файлу.
        /// </summary>
        public string PathFile {
            set {
                _pathFile = value ?? "";
            }
            get {
                return _pathFile;
            }
        }

        /// <summary>
        /// Количество листов в прочтенном файле.
        /// </summary>
        public int CountSheet {
            get {
                return _sheetsFile.Count;
            }
        }

        /////////////////////////////////Public методы/////////////////////////////////

        /// <summary>
        /// Конструктор.
        /// </summary>
        /// <param name="pathFile">Путь к требуемому файлу.</param>
        public ReaderXLS(string pathFile = "") {
            PathFile = pathFile;
        }

        /// <summary>
        /// Чтение файла.
        /// </summary>
        public void readFile() {
            //Запуск экселя.
            Application application = new Application();
            //Класс работы с файлом.
            Workbook workBook = application.Workbooks.Open(_pathFile, 0, true, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
            //Список листов.
            _sheetsFile = new List<string[,]>();
            //Чтение листов.
            for (int iSheet = 1; iSheet <= workBook.Sheets.Count; iSheet++) {
                //Класс работы с листами.
                Worksheet workSheet = (Worksheet)workBook.Sheets[iSheet];
                //Последняя заполненная строка в столбце А.
                int iLastRow = workSheet.Cells[workSheet.Rows.Count, "A"].End[XlDirection.xlUp].Row;
                //Чтение данных с листа.
                var arrData = (object[,])workSheet.Range["A1:J" + iLastRow].Value; 
                //Преобразование данных в строку.
                string[,] sheet = new string[arrData.GetLength(0), arrData.GetLength(1)];
                for (int i = 1; i < sheet.GetLength(0); i++) {
                    for (int j = 1; j < sheet.GetLength(1); j++) {
                        if (arrData[i, j] != null) {
                            sheet[i - 1, j - 1] = arrData[i, j].ToString();
                        }
                        else {
                            sheet[i - 1, j - 1] = "";
                        }

                    }
                }
                //Добавление листа в список листов.
                _sheetsFile.Add(sheet);
            }
            //Закрытие файла не сохраняя.
            workBook.Close(false, Type.Missing, Type.Missing);
            //Выход из экселя.
            application.Quit();
        }

        /// <summary>
        /// Получение данных со страницы файла.
        /// </summary>
        /// <param name="sheetNumber">Страница файла.</param>
        /// <returns></returns>
        public string[,] getSheet(int sheetNumber) {
            //Возвращение результата.
            return _sheetsFile[sheetNumber];
        }
    }
}
