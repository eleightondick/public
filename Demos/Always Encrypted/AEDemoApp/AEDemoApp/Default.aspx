<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="AEDemoApp.WebForm1" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
    
        Employee #:&nbsp;
        <asp:TextBox ID="TextBox5" runat="server"></asp:TextBox>
    
        <asp:Button ID="Button1" runat="server" OnClick="Button1_Click" Text="Fetch by ID" />
        <br />
        SSN:&nbsp;
        <asp:TextBox ID="TextBox6" runat="server"></asp:TextBox>
        <asp:Button ID="Button2" runat="server" Text="Fetch by SSN" OnClick="Button2_Click" />
        </div>
        <div>
            Results:&nbsp;<asp:TextBox ID="TextBox1" runat="server"></asp:TextBox>
            <asp:TextBox ID="TextBox2" runat="server"></asp:TextBox>
            <asp:TextBox ID="TextBox3" runat="server"></asp:TextBox>
            <asp:TextBox ID="TextBox4" runat="server"></asp:TextBox>
            <asp:Button ID="Button3" runat="server" OnClick="Button3_Click" Text="Clear" />
        </div>
    <hr />
    <div>
        Employee #:&nbsp;<asp:TextBox ID="TextBox7" runat="server"></asp:TextBox>
        <asp:Button ID="Button4" runat="server" OnClick="Button4_Click" Text="Show Pay" />
    </div>
        <div>
            Pay Rate:&nbsp;<asp:TextBox ID="TextBox8" runat="server"></asp:TextBox>
            <asp:Button ID="Button5" runat="server" Text="Clear" OnClick="Button5_Click" />
        </div>
    <hr />
        <div>
            Employee #:&nbsp;<asp:TextBox ID="TextBox9" runat="server"></asp:TextBox>
        </div>
        <div>
            New Pay Rate:&nbsp;<asp:TextBox ID="TextBox10" runat="server"></asp:TextBox>
            <asp:Button ID="Button6" runat="server" Text="Submit" OnClick="Button6_Click" />
        </div>
        <div>
            Results:&nbsp;<asp:TextBox ID="TextBox11" runat="server"></asp:TextBox>
            <asp:Button ID="Button7" runat="server" Text="Clear" OnClick="Button7_Click" />
        </div>
    </form>
    </body>
</html>
