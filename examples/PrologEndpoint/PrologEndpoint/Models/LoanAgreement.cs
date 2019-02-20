using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace PrologEndpoint.Models
{
    public class LoanAgreement
    {
        public int ContractNumber { get; set; }
        public double PrincipalAmount { get; set; }
        public DateTime LodgementDate { get; set; }
        public int CreationIncomeYear { get; set; }
        public int Term { get; set; }
        public int ComputationYear { get; set; }
        public double ComputationOpeningBalance { get; set; }
        public LoanRepayment[] Repayments { get; set; }
    }
}