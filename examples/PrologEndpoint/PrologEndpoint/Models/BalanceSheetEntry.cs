using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Xml.Serialization;

namespace PrologEndpoint.Models
{
    public class BalanceSheetEntry
    {
        [XmlAttribute("account_name")]
        public String AccountName { get; set; }
        [XmlAttribute("account_debit")]
        public double AccountDebit { get; set; }
        [XmlAttribute("account_credit")]
        public double AccountCredit { get; set; }
        [XmlElement("balance_sheet_entry")]
        public List<BalanceSheetEntry> Subentries { get; set; }
    }
}