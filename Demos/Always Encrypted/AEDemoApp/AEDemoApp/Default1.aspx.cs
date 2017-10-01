using System;
using System.Data.SqlClient;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace AEDemoApp
{
   public partial class _Default : Page
    {
      string _connectionString = "Data Source=aedemoserver; Initial Catalog=AdventureWorks2012; Integrated Security=true; Column Encrypted Setting=enabled;";

      protected void Page_Load(object sender, EventArgs e)
        {
        }
    }
}