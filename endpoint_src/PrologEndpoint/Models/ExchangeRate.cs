using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace PrologEndpoint.Models
{
    public class ExchangeRate
    {
        public DateTime Date { get; set; }
        public String SrcCurrency { get; set; }
        public String DestCurrency { get; set; }
        public double Rate { get; set; }
    }
}