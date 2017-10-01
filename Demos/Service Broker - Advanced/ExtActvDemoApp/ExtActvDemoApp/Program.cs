using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using System.Configuration;
using System.IO;
using System.Xml.Linq;
using LinqToTwitter;
using System.Net;

namespace ExtActvDemoApp
{
    class Program
    {
        // Twitter access key
        // Uses LinqToTwitter (linqtotwitter.codeplex.com)
        static private SingleUserAuthorizer twitterAuthorizer = new SingleUserAuthorizer
        {
            CredentialStore = new SingleUserInMemoryCredentialStore
            {
                ConsumerKey = ConfigurationManager.AppSettings["twitter_ConsumerKey"],
                ConsumerSecret = ConfigurationManager.AppSettings["twitter_ConsumerSecret"],
                AccessToken = ConfigurationManager.AppSettings["twitter_AccessToken"],
                AccessTokenSecret = ConfigurationManager.AppSettings["twitter_AccessTokenSecret"]
            }
        };

        static void Main(string[] args)
        {
            string connStr = ConfigurationManager.ConnectionStrings["brokerServer"].ConnectionString;
            using (SqlConnection cnBroker = new SqlConnection(connStr))
            {
                cnBroker.Open();
                ProcessRequest(cnBroker);
            }

            // Wait for a keypress before exiting
            //Console.WriteLine("Press a key to exit");
            //Console.ReadKey();
        }

        static void ProcessRequest(SqlConnection cn)
        {
            Boolean messageReceived = true;

            Guid handle = Guid.Empty;
            string serviceName = string.Empty;
            string messageType = string.Empty;
            XDocument message = null;

            while (messageReceived)
            {
                using (SqlCommand cmdBroker = new SqlCommand("WAITFOR (RECEIVE TOP(1) conversation_handle, service_name, message_type_name, message_body FROM dbo.sqltalk_extQueue), TIMEOUT 5000", cn))
                {
                    using (SqlDataReader brokerMessageReader = cmdBroker.ExecuteReader())
                    {
                        if (brokerMessageReader.Read())
                        {
                            messageReceived = true;

                            handle = brokerMessageReader.GetGuid(0);
                            serviceName = brokerMessageReader.GetString(1);
                            messageType = brokerMessageReader.GetString(2);
                            SqlBinary messageBinary = brokerMessageReader.GetSqlBinary(3);

                            // Convert messageBody to XML
                            using (MemoryStream messageStream = new MemoryStream(messageBinary.Value))
                            {
                                message = XDocument.Load(messageStream);
                            }
                        }
                        else
                        {
                            messageReceived = false;
                        }
                    }

                    if (messageReceived)
                    {
                        switch (messageType)
                        {
                            case "http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog":
                                break;
                            case "http://schemas.microsoft.com/SQL/ServiceBroker/Error":
                                EndConversation(cn, handle);
                                break;
                            default:
                                LogMessage(cn, handle, messageType, message.ToString());
                                ProcessMessage(serviceName, message);
                                SendAcknowledgement(cn, handle);
                                EndConversation(cn, handle);
                                break;
                        }
                    }
                }
            }
        }

        static void ProcessMessage(String service, XDocument message)
        {
            XElement messageRoot = message.Root;
            String destinationTwitterAccount = (String)messageRoot.Attribute("toAccount") ?? "";
            String destinationSmsNumber = (String)messageRoot.Attribute("toNumber") ?? "";
            String messageText = (String)messageRoot ?? "";

            switch (service)
            {
                case "//sqltalk/rcvTweetService":
                    SendTweet(destinationTwitterAccount, messageText);
                    break;
                case "//sqltalk/rcvSmsService":
                    SendSms(destinationSmsNumber, messageText);
                    break;
            }
        }

        // Send a tweet
        // Uses LinqToTwitter (linqtotwitter.codeplex.com)
        static async void SendTweet(String destinationAccount, String message)
        {
            // Generate a random number so our test tweets are unique
            Random generator = new Random();
            string r = generator.Next(0, 1000000).ToString("D6");

            TwitterContext twitterCtx = new TwitterContext(twitterAuthorizer);
            Status tweet = await twitterCtx.TweetAsync("@" + destinationAccount + " " + message + " [" + r + "]");
        }

        static void SendSms(String destinationAccount, String message)
        {
            // Based on code from http://www.hanselman.com/blog/HTTPPOSTsAndHTTPGETsWithWebClientAndCAndFakingAPostBack.aspx
            string jsonRequest = "";
            System.Net.WebRequest req = System.Net.WebRequest.Create(ConfigurationManager.AppSettings["sms_requestUrl"]);
            req.ContentType = "application/json";
            req.Method = "POST";
            jsonRequest = "{\"toNumber\":\"" + destinationAccount + "\",\"message\":\"" + message + "\"}";
            byte[] bytes = System.Text.Encoding.ASCII.GetBytes(jsonRequest);
            req.ContentLength = bytes.Length;
            System.IO.Stream os = req.GetRequestStream();
            os.Write(bytes, 0, bytes.Length);
            os.Close();
        }

        static void SendAcknowledgement(SqlConnection cn, Guid handle)
        {
            using (SqlCommand cmdAck = new SqlCommand("SEND ON CONVERSATION @handle MESSAGE TYPE [//sqltalk/ack]", cn))
            {
                cmdAck.Parameters.Add(new SqlParameter("@handle", SqlDbType.UniqueIdentifier)).Value = handle;
                cmdAck.ExecuteNonQuery();
            }
        }

        static void EndConversation(SqlConnection cn, Guid handle)
        {
            using (SqlCommand cmdEnd = new SqlCommand("END CONVERSATION @handle", cn))
            {
                cmdEnd.Parameters.Add(new SqlParameter("@handle", SqlDbType.UniqueIdentifier)).Value = handle;
                cmdEnd.ExecuteNonQuery();
            }
        }

        static void LogMessage(SqlConnection cn, Guid handle, String messageType, String message)
        {
            using (SqlCommand cmdLog = new SqlCommand("sqltalk_LogMessage", cn))
            {
                cmdLog.CommandType = CommandType.StoredProcedure;

                cmdLog.Parameters.Add(new SqlParameter("@handle", SqlDbType.UniqueIdentifier)).Value = handle;
                cmdLog.Parameters.Add(new SqlParameter("@messageType", SqlDbType.NVarChar, 256)).Value = messageType;
                cmdLog.Parameters.Add(new SqlParameter("@message", SqlDbType.Xml, -1)).Value = message;

                cmdLog.ExecuteNonQuery();
            }
        }
    }
}
