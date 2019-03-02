using System;

namespace PrologEndpoint.Models
{
    public class Transaction
    {
        public DateTime Datetime { get; set; }
        public String Description { get; set; }
        public String Account { get; set; }
        public double Debit { get; set; }
        public double Credit { get; set; }
    }
}