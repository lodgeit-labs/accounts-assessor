using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Xml.Serialization;

namespace PrologEndpoint.Models
{
    public class BalanceSheetEntry
    {
        [XmlAttribute]
        public String AccountName { get; set; }
        [XmlAttribute]
        public double AccountDebit { get; set; }
        [XmlAttribute]
        public double AccountCredit { get; set; }
        [XmlElement("BalanceSheetEntry")]
        public List<BalanceSheetEntry> Subentries { get; set; }
    }
}