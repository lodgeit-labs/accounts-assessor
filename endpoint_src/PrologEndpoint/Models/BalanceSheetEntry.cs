using System;
using System.Collections.Generic;
using System.Xml.Serialization;

namespace PrologEndpoint.Models
{
    public class BalanceSheetEntry
    {
        [XmlAttribute("account_name")]
        public String AccountName { get; set; }
        [XmlElement("coordinate")]
        public List<Coordinate> AccountVector { get; set; }
        [XmlElement("balance_sheet_entry")]
        public List<BalanceSheetEntry> Subentries { get; set; }
    }
}