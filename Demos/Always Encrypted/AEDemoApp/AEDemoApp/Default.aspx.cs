using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace AEDemoApp
{
    public partial class WebForm1 : System.Web.UI.Page
    {
        string _connectionString = "Data Source=aedemoserver; Initial Catalog=AdventureWorks2012; Integrated Security=true; Column Encryption Setting=enabled;";

        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            SqlConnection cn = new SqlConnection(_connectionString);
            cn.Open();

            using (SqlCommand cmd = new SqlCommand("SELECT e.BusinessEntityID, e.NationalIDNumber, p.FirstName, p.LastName FROM HumanResources.Employee e INNER JOIN Person.Person p ON p.BusinessEntityID = e.BusinessEntityID WHERE e.BusinessEntityID = @EmployeeID", cn))
            {
                SqlParameter EmployeeID = new SqlParameter("@EmployeeID", SqlDbType.Int);
                EmployeeID.Value = TextBox5.Text;

                cmd.Parameters.Add(EmployeeID);
                SqlDataReader dr = cmd.ExecuteReader();

                dr.Read();
                TextBox1.Text = dr["BusinessEntityID"].ToString();
                TextBox2.Text = dr["NationalIDNumber"].ToString();
                TextBox3.Text = dr["FirstName"].ToString();
                TextBox4.Text = dr["LastName"].ToString();

                dr.Close();
            }
            cn.Close();
            cn.Dispose();
        }

        protected void Button2_Click(object sender, EventArgs e)
        {
            SqlConnection cn = new SqlConnection(_connectionString);
            cn.Open();

            using (SqlCommand cmd = new SqlCommand("SELECT e.BusinessEntityID, e.NationalIDNumber, p.FirstName, p.LastName FROM HumanResources.Employee e INNER JOIN Person.Person p ON p.BusinessEntityID = e.BusinessEntityID WHERE e.NationalIDNumber = @EmployeeSSN", cn))
            {
                SqlParameter EmployeeSSN = new SqlParameter("@EmployeeSSN", SqlDbType.NVarChar, 15);
                EmployeeSSN.Value = TextBox6.Text;

                cmd.Parameters.Add(EmployeeSSN);
                SqlDataReader dr = cmd.ExecuteReader();

                dr.Read();
                if (dr.HasRows)
                {
                    TextBox1.Text = dr["BusinessEntityID"].ToString();
                    TextBox2.Text = dr["NationalIDNumber"].ToString();
                    TextBox3.Text = dr["FirstName"].ToString();
                    TextBox4.Text = dr["LastName"].ToString();
                }

                dr.Close();
            }
            cn.Close();
            cn.Dispose();
        }

        protected void Button3_Click(object sender, EventArgs e)
        {
            TextBox1.Text = string.Empty;
            TextBox2.Text = string.Empty;
            TextBox3.Text = string.Empty;
            TextBox4.Text = string.Empty;
            TextBox5.Text = string.Empty;
            TextBox6.Text = string.Empty;
        }

        protected void Button4_Click(object sender, EventArgs e)
        {
            SqlConnection cn = new SqlConnection(_connectionString);
            cn.Open();

            using (SqlCommand cmd = new SqlCommand("SELECT TOP(1) Rate FROM HumanResources.EmployeePayHistory e WHERE e.BusinessEntityID = @EmployeeID ORDER BY RateChangeDate DESC", cn))
            {
                SqlParameter EmployeeSSN = new SqlParameter("@EmployeeID", SqlDbType.Int);
                EmployeeSSN.Value = TextBox7.Text;

                cmd.Parameters.Add(EmployeeSSN);
                SqlDataReader dr = cmd.ExecuteReader();

                dr.Read();
                if (dr.HasRows)
                {
                    TextBox8.Text = dr["Rate"].ToString();
                }

                dr.Close();
            }
            cn.Close();
            cn.Dispose();
        }

        protected void Button5_Click(object sender, EventArgs e)
        {
            TextBox7.Text = string.Empty;
            TextBox8.Text = string.Empty;
        }

        protected void Button6_Click(object sender, EventArgs e)
        {
            SqlConnection cn = new SqlConnection(_connectionString);
            cn.Open();

            using (SqlCommand cmd = new SqlCommand("HumanResources.spChangePayRate", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;

                SqlParameter EmployeeID = new SqlParameter("@EmployeeID", SqlDbType.Int);
                EmployeeID.Value = TextBox9.Text;
                cmd.Parameters.Add(EmployeeID);

                SqlParameter NewRate = new SqlParameter("@NewRate", SqlDbType.Money);
                NewRate.Value = TextBox10.Text;
                cmd.Parameters.Add(NewRate);

                int rowsAffected = cmd.ExecuteNonQuery();

                TextBox11.Text = rowsAffected.ToString() + " rows added";
            }
            cn.Close();
            cn.Dispose();
        }

        protected void Button7_Click(object sender, EventArgs e)
        {
            TextBox9.Text = string.Empty;
            TextBox10.Text = string.Empty;
            TextBox11.Text = string.Empty;
        }
    }
}