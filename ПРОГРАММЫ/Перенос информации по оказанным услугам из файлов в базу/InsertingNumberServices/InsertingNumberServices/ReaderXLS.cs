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
        /////////////////////////////////Структуры/////////////////////////////////


        /// <summary>
        /// Размер листа.
        /// </summary>
        private struct SizeSheet
        {
            /// <summary>
            /// Количество строк.
            /// </summary>
            public int nRow;
            /// <summary>
            /// Количество столбцов.
            /// </summary>
            public int nColumn;
        }


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
            for (int i = 1; i <= workBook.Sheets.Count; i++) {
                //Класс работы с листами.
                Worksheet workSheet = (Worksheet)workBook.Sheets[i];
                //Размер листа.
                SizeSheet sizeSheet = getSizeSheets(workSheet);
                //Значения листа.
                string[,] sheet = new string[sizeSheet.nRow, sizeSheet.nColumn];
                //Считывание листа.
                for (int row = 0; row < sizeSheet.nRow; row++) {
                    for (int column = 0; column < sizeSheet.nColumn; column++) {
                        sheet[row, column] = workSheet.Cells[row + 1, column + 1].Text.ToString();
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


        /////////////////////////////////Private методы/////////////////////////////////


        /// <summary>
        /// Получить размер листа.
        /// </summary>
        /// <param name="workSheet">Класс работы с листами</param>
        /// <returns></returns>
        private SizeSheet getSizeSheets(Worksheet workSheet) {
            int row = 0;                            //Рассматриваемая строка.
            int column = 0;                         //Рассматриваемый столбец.
            int maxIndexColumnNotEmptyCell = -1;    //Максимальный индекс столбца не пустой ячейки.
            int maxIndexRowNotEmptyCell = -1;       //Максимальный индекс строки не пустой ячейки.
            int currentCountEmptyRow = 0;           //Количество подряд идущих пустых строк.
            int currentCountEmptyColumn = 0;        //Количество подряд идущих пустых строк.
            bool rowCompletelyEmpty = false;        //Флаг пустой строки.
            //Обход по строкам.
            while (currentCountEmptyRow <= 3) {
                column = 0;                         //Переходим к первому столбцу.
                currentCountEmptyColumn = 0;        //Сбрасываем счетчик пустых столбцов.
                rowCompletelyEmpty = true;          //Заведомо считаем строку пустой.
                //Обход по столбцам.
                while (currentCountEmptyColumn <= 3) {
                    if (workSheet.Cells[row + 1, column + 1].Text.ToString() == "") {
                        currentCountEmptyColumn++;      //Счет пустых столбцов в строке.
                    }
                    else {
                        currentCountEmptyColumn = 0;    //Сброс счетчика пустых столбцов в строке.
                        rowCompletelyEmpty = false;     //Сброс флага пустой строки, если столбец не пустой.
                        if (maxIndexColumnNotEmptyCell < column) {
                            maxIndexColumnNotEmptyCell = column;    //Фиксация максимального индекса не пустого столбца.
                        }
                    }
                    column++;   //Переход на следующий солбец.
                }
                if (rowCompletelyEmpty) {
                    currentCountEmptyRow++; //Счет пустых строк.
                }
                else {
                    currentCountEmptyRow = 0;       //Сброс пустых строк.
                    maxIndexRowNotEmptyCell = row;  //Фиксация максимального индекса не пустой строки.
                }
                row++;  //Переход к следующей строке.
            }
            //Результат.
            return new SizeSheet {
                nRow = maxIndexRowNotEmptyCell + 1,
                nColumn = maxIndexColumnNotEmptyCell + 1
            };
        }
    }
}
