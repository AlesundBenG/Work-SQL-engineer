using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace InsertingNumberServices
{
    public partial class MainForm : Form
    {
        public MainForm() {
            InitializeComponent();
        }


        /// <summary>
        /// Нажатие кнопки выбора файла.
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void buttonChooseFile_Click(object sender, EventArgs e) {
            if (openFileDialog.ShowDialog() == DialogResult.OK) {
                ReaderXLS reader = new ReaderXLS(openFileDialog.FileName);
                reader.readFile();              //Чтение файла.
                tabControl.SelectedIndex = 1;   //Перемещаемся на следующую вкладку.
            }            
        }



        /*
//Чтение листов.
string[,] sheet1 = reader.getSheet(0);
string[,] sheet2 = reader.getSheet(1);
//Добавлнеие столбцов.
for (int i = 0; i < sheet1.GetLength(1); i++) {
    dataGridViewSheet1.Columns.Add(i.ToString(), i.ToString());
}
for (int i = 0; i < sheet2.GetLength(1); i++) {
    dataGridViewSheet2.Columns.Add(i.ToString(), i.ToString());
}
//Добавление строк.
dataGridViewSheet1.Rows.Add(sheet1.GetLength(0));
dataGridViewSheet2.Rows.Add(sheet2.GetLength(0));
//Отображение содержимого страниц.
for (int i = 0; i < sheet1.GetLength(0); i++) {
    for (int j = 0; j < sheet1.GetLength(1); j++) {
        dataGridViewSheet1.Rows[i].Cells[j].Value = sheet1[i, j];
    }
}
for (int i = 0; i < sheet2.GetLength(0); i++) {
    for (int j = 0; j < sheet2.GetLength(1); j++) {
        dataGridViewSheet2.Rows[i].Cells[j].Value = sheet2[i, j];
    }
}
*/
    }
}
