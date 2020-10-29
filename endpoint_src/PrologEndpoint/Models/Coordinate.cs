using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Xml.Serialization;

namespace PrologEndpoint.Models
{
    public class Coordinate
    {
        [XmlAttribute("unit")]
        public String Unit { get; set; }
        [XmlAttribute("debit")]
        public double Debit { get; set; }
        [XmlAttribute("credit")]
        public double Credit { get; set; }
    }
}