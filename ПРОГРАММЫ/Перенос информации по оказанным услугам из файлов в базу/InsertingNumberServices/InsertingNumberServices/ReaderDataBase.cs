using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient;

namespace InsertingNumberServices
{



    /// <summary>
    /// Чтение из базы данных.
    /// </summary>
    public class ReaderDataBase {
        /////////////////////////////////Параметры/////////////////////////////////

        /// <summary>
        /// Сервер базы данных.
        /// </summary>
        private string _server;
        /// <summary>
        /// Логин подключения.
        /// </summary>
        private string _login;
        /// <summary>
        /// Пароль подключения.
        /// </summary>
        private string _password;
        /// <summary>
        /// База данных.
        /// </summary>
        private string _database;
        /// <summary>
        /// Флаг наличия успешного подключения.
        /// </summary>
        private bool _thereIsConnection;


        /////////////////////////////////Свойства/////////////////////////////////


        /// <summary>
        /// Сервер базы данных.
        /// </summary>
        public string Server {
            get { return _server; }
        }

        /// <summary>
        /// Логин.
        /// </summary>
        public string Login {
            get { return _login; }
        }

        /// <summary>
        /// База данных.
        /// </summary>
        public string DataBase {
            get { return _database; }
        }

        /// <summary>
        /// Флаг подключения к базе данных.
        /// </summary>
        public bool ThereIsConnection {
            get {return _thereIsConnection; }
        }


        /////////////////////////////////Public методы/////////////////////////////////


        /// <summary>
        /// Конструктор.
        /// </summary>
        public ReaderDataBase() {
            _thereIsConnection = false;
        }

        /// <summary>
        /// Конструктор.
        /// </summary>
        /// <param name="server">Сервер</param>
        /// <param name="login">Логин</param>
        /// <param name="password">Пароль</param>
        /// <param name="database">База данных</param>
        public ReaderDataBase(string server, string login, string password, string database) {
            connectDataBase(server, login, password, database);
        }

        /// <summary>
        /// Подключение к базе данных.
        /// </summary>
        /// <param name="server">Сервер</param>
        /// <param name="login">Логин</param>
        /// <param name="password">Пароль</param>
        /// <param name="database">База данных</para
        /// <returns>Флаг успешного подключения</returns>
        public bool connectDataBase(string server, string login, string password, string database) {
            //Параметры подключения.
            _server     = server;
            _login      = login;
            _password   = password;
            _database   = database;

            //Проверка валидности параметров подключения..
            try {
                SqlConnection sqlConnection = new SqlConnection($"server = {_server}; uid = {_login}; pwd = {_password}; database = {_database}");
                sqlConnection.Open();
                sqlConnection.Close();
                _thereIsConnection = true;
            }
            catch {
                _thereIsConnection = false;
            }

            //Результат подключения.
            return _thereIsConnection;
        }

        /// <summary>
        /// Выполнение запроса.
        /// </summary>
        /// <param name="comamndSQL">SQL запрос</param>
        public void executeCommand(string comamndSQL) {
            if (_thereIsConnection) {
                SqlConnection sqlConnection = new SqlConnection($"server = {_server}; uid = {_login}; pwd = {_password}; database = {_database}");
                SqlCommand command = new SqlCommand(comamndSQL, sqlConnection);
                sqlConnection.Open();
                SqlDataReader reader = command.ExecuteReader();
                while (reader.Read()) {
                    for (int i = 0; i < reader.FieldCount; i++) {

                    }
                }
                sqlConnection.Close();
                sqlConnection.Dispose();
            }
            else {

            }
        }



    }
}
