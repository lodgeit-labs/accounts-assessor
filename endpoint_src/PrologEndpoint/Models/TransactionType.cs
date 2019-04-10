using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace PrologEndpoint.Models
{
    public class TransactionType
    {
        public String Id { get; set; }
        public String ExchangeAccount { get; set; }
        public String TradingAccount { get; set; }
        public String Description { get; set; }
    }
}