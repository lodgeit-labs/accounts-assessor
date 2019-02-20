using System.Xml.Serialization;

namespace PrologEndpoint.Models
{
    public class LoanSummary
    {
        public int IncomeYear { get; set; }
        public double OpeningBalance { get; set; }
        public double InterestRate { get; set; }
        public double MinYearlyRepayment { get; set; }
        public double TotalRepayment { get; set; }
        public double RepaymentShortfall { get; set; }
        public double TotalInterest { get; set; }
        public double TotalPrincipal { get; set; }
        public double ClosingBalance { get; set; }
    }
}