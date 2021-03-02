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
        /// <summary>
        /// Инициализация формы.
        /// </summary>
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
    }
}
