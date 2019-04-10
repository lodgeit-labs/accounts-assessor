using System;
using System.Collections.Generic;

namespace PrologEndpoint.Models
{
    public class StatementTransaction
    {
        public DateTime Date { get; set; }
        public String TypeId { get; set; }
        public String Account { get; set; }
        public List<Coordinate> Vector { get; set; }
        public List<String> Bases { get; set; }
    }
}