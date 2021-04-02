using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.KeyVault;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Extensions.Configuration.AzureKeyVault;
using Microsoft.Extensions.Logging;
using WebApplication2.Models;
using Microsoft.Extensions.Configuration;
using System.Net;

namespace WebApplication2.Controllers
{
    public class HomeController : Controller
    {
        readonly IConfiguration _configuration;
        private readonly ILogger<HomeController> _logger;

        //public HomeController(ILogger<HomeController> logger)
        public HomeController(IConfiguration configuration)
        {
            _configuration = configuration;
            //_logger = logger;
        }
        
        public async System.Threading.Tasks.Task<ActionResult> Index()
        {
            AzureServiceTokenProvider azureServiceTokenProvider = new AzureServiceTokenProvider();
            ViewBag.KeyVaultConnectionState = "Cannot get secred";
            ViewBag.SQLEntriesreturn = "null";
            ViewBag.SQLConnectionState = "none";
            ViewBag.Error = "none";
            ViewBag.ErrorMSG = "";

            try
            {
                var keyVaultClient = new KeyVaultClient(
                    new KeyVaultClient.AuthenticationCallback(azureServiceTokenProvider.KeyVaultTokenCallback));

                string[] stringSeparators = new string[] { "/" };
                string[] kvserver = (_configuration["KeyVault"]).ToString().Split(stringSeparators, StringSplitOptions.RemoveEmptyEntries);

                ViewBag.KeyVaultName = kvserver[1];
                ViewBag.KeyVaultIP = Dns.GetHostEntry(kvserver[1]).AddressList[0];

                //KeyVault for PSE
                var secret = await keyVaultClient.GetSecretAsync(_configuration["KeyVault"])
                    .ConfigureAwait(false);                

                SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();

                string connectionstring = secret.Value;
                ViewBag.KeyVaultConnectionState = "Success";

                using (SqlConnection connection = new SqlConnection(connectionstring))
                {
                    try
                    {
                        ViewBag.SQLServerName = connection.DataSource;
                        ViewBag.SQLServerIP = Dns.GetHostEntry(connection.DataSource).AddressList[0];
                        connection.Open();
                        ViewBag.SQLConnectionState = "Success";

                        string sql = "select count(*) from " + _configuration["TableName"];

                        using (SqlCommand command = new SqlCommand(sql, connection))
                        {
                            ViewBag.SQLEntriesreturn = command.ExecuteScalar();
                        }

                        string sqlquery = "SELECT TOP 1 Name,Details FROM " + _configuration["TableName"];                        

                        using (SqlCommand command = new SqlCommand(sqlquery, connection))
                        {
                            SqlDataReader reader = command.ExecuteReader();

                            while (reader.Read())
                            {
                                ViewBag.SQLFirstEntry = reader["Details"].ToString();
                            }

                            reader.Close();
                        }
                    }
                    catch (Exception exp)
                    {
                        ViewBag.Error = "Error";
                        ViewBag.ErrorMSG = $"Cannot connect to Database: {exp.Message}";
                    }

                    connection.Close();
                }

            }
            catch (Exception exp)
            {
                ViewBag.Error = "Error";
                ViewBag.ErrorMSG = $"Something went wrong: {exp.Message}";                
            }

            return View();
        }       

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
