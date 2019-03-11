using System;
using System.Collections.Generic;

namespace PrologEndpoint.Models
{
    public class Transaction
    {
        public DateTime Datetime { get; set; }
        public String Description { get; set; }
        public String Account { get; set; }
        public List<Coordinate> Vector { get; set; }
    }
}