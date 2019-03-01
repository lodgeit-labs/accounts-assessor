using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace PrologEndpoint.Models
{
    public class Transaction
    {
        public DateTime Date { get; set; }
        public String Description { get; set; }
        public String Account { get; set; }
        public double Debit { get; set; }
        public double Credit { get; set; }
    }
}