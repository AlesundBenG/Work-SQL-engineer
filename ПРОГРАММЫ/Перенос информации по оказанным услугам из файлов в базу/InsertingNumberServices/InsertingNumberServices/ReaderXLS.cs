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
        /////////////////////////////////////Структуры/////////////////////////////////////

        /// <summary>
        /// Размер листа.
        /// </summary>
        private struct SizeSheet
        {
            /// <summary>
            /// Количество строк.
            /// </summary>
            public int nLine;
            /// <summary>
            /// Количество столбцов.
            /// </summary>
            public int nColumn;
        }


        /////////////////////////////////////Параметры/////////////////////////////////////
        /// <summary>
        /// Путь к файлу.
        /// </summary>
        private string _pathFile;


        /////////////////////////////////////Свойства/////////////////////////////////////

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



        //////////////////////////////////////////////////////////////////////////////////////////////


        /// <summary>
        /// Конструктор.
        /// </summary>
        /// <param name="pathFile">Путь к требуемому файлу.</param>
        public ReaderXLS(string pathFile = "") {
            PathFile = pathFile;
        }


        /// <summary>
        /// Получение данных со страницы файла.
        /// </summary>
        /// <param name="sheetNumber">Страница файла.</param>
        /// <returns></returns>
        public string[,] getSheet(int sheetNumber) {
            //Запуск экселя.
            Application application = new Application();
            //Класс работы с файлом.
            Workbook workBook = application.Workbooks.Open(_pathFile, 0, true, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing, Type.Missing);
            //Класс работы с листами.
            Worksheet workSheet = (Worksheet)workBook.Sheets[sheetNumber];
            //Размер листа.
            SizeSheet sizeSheet = getSizeSheets(workSheet);
            //Значения листа.
            string[,] sheet = new string[sizeSheet.nLine, sizeSheet.nColumn];
            //Считывание листа.
            for (int i = 0; i < sizeSheet.nLine; i++) {
                for (int j = 0; j < sizeSheet.nColumn; j++) {
                    sheet[i,j] = workSheet.Cells[i + 1, j + 1].Text.ToString();
                }
            }
            //Закрыть не сохраняя.
            workBook.Close(false, Type.Missing, Type.Missing);
            //Выйти из экселя
            application.Quit();
            //Возвращение результата.
            return sheet;
        }


        //////////////////////////////////////////////////////////////////////////////////////////////

        /// <summary>
        /// Получить размер листа.
        /// </summary>
        /// <param name="workSheet">Класс работы с листами</param>
        /// <returns></returns>
        private SizeSheet getSizeSheets(Worksheet workSheet) {
            SizeSheet sizeSheet = new SizeSheet {
                nLine = 0,
                nColumn = 0
            };
            int line = 0;                       //Рассматриваемая строка.
            int column = 0;                     //Рассматриваемый столбец.
            int currentCountEmptyLines = 0;     //Количество подряд идущих пустых строк.
            int currentCountEmptyColumn = 0;    //Количество подряд идущих пустых строк.
            bool lineCompletelyEmpty = false;   //Флаг пустой строки.
            //Обход по строкам.
            while (currentCountEmptyLines < 3) {
                //Обход по столбцам.
                column = 0;
                currentCountEmptyColumn = 0;
                lineCompletelyEmpty = true;
                while (currentCountEmptyColumn < 3) {
                    string value = workSheet.Cells[line + 1, column + 1].Text.ToString();       //Получение значения.
                    if (value == "") {
                        currentCountEmptyColumn++;                                              //Счет пустых столбцов в строке.
                    }
                    else {
                        currentCountEmptyColumn = 0;
                    }
                    if (lineCompletelyEmpty && value != "") {
                        lineCompletelyEmpty = false;                                            //Сброс флага пустой строки, если столбец не пустой.
                    }
                    column++;                                                                   //Переход на следующий солбец.
                }
                if (lineCompletelyEmpty) {
                    currentCountEmptyLines++;                                                   //Счет пустых строк.
                }
                else {
                    currentCountEmptyLines = 0;
                }
                if (sizeSheet.nColumn < column) {
                    sizeSheet.nColumn = column;
                }
                line++;                                                                         //Переход к следующей строке.
            }
            sizeSheet.nLine = line;
            return sizeSheet;
        }
    }
}
