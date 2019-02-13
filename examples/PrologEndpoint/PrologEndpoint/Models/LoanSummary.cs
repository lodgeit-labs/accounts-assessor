using System.Xml.Serialization;

namespace PrologEndpoint.Models
{
    public class LoanSummary
    {
        [XmlAttribute]
        public int IncomeYear { get; set; }
        [XmlAttribute]
        public double OpeningBalance { get; set; }
        [XmlAttribute]
        public double InterestRate { get; set; }
        [XmlAttribute]
        public double MinYearlyRepayment { get; set; }
        [XmlAttribute]
        public double TotalRepayment { get; set; }
        [XmlAttribute]
        public double TotalInterest { get; set; }
        [XmlAttribute]
        public double TotalPrincipal { get; set; }
        [XmlAttribute]
        public double ClosingBalance { get; set; }
    }
}