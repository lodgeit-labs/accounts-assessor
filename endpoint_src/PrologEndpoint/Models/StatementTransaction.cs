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
        // The following two fields form a discriminated union - exactly one of them
        // must be null at all times. If the second field is non-null, it means that the
        // currency conversions have already been manually done. If the first field is
        // non-null then it means that the system will do an automatic conversion to the
        // specified units.
        public List<String> ExchangedAmountBases { get; set; }
        public List<Coordinate> ExchangedAmountVector { get; set; }
    }
}