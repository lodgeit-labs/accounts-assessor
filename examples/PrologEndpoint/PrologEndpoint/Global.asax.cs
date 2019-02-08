using PrologEndpoint.Helpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Web;
using System.Web.Http;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;

// This program is a demonstration of how a C# web application can run SWI Prolog queries
// using the SWI-Prolog Foreign Language Interface. This program works as follows: SWI-Prolog
// provides a DLL library called libswipl.dll that can load Prolog scripts and execute queries
// on them. The PL class in this document simply declares the functions in the DLL file to the
// rest of this C# program. The controllers in this project simply utilizes the DLL files's
// functions to execute a Prolog query.

// Make sure that the local variable argv of
// PrologEndpoint.WebApiApplication.InitializeProlog contains the correct location of main.pl,
// which is to be found at the root of the labs-account-assessor repository. Make sure that
// PrologEndpoint.Helpers.PL.dllName has the correct location of the Prolog Kernel DLL.

// To run this, open up Microsoft Visual Studio. Go Project > Properties... > Build > General .
// Set Platform Target to match the target architecture of libswipl.dll, the Prolog Kernel DLL.
// Now go Tools > Options > Projects and Solutions > Web Projects >
// Use the 64 bit version of IIS Express for web sites and projects depending on the target
// architecture of the Prolog Kernel DLL. Now go Debug > Start Debugging. To send a request to
// the web application, open up Windows Powershell and enter the following with the port number
// modified appropriately:
//
// Invoke-WebRequest -Uri http://localhost:57417/api/Loan -Body '<?xml version="1.0"?>
// <reports xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
// xmlns:xsd="http://www.w3.org/2001/XMLSchema"><loandetails><generator>
// <date>2017-03-25T05:53:43.887542Z</date><source>ACCRIP</source><author>
// <firstname>waqas</firstname><lastname>awan</lastname><company>Uhudsoft</company></author></generator>
// <company><abn>12345678900</abn><tfn /><clientcode /><anzsic /><notes /><directors /></company>
// <title>Load Sheet</title><period>1 July, 2016 to 30 June, 2023</period><startDate>2016-07-01</startDate>
// <endDate>2023-06-30</endDate><loanAgreement><field name="Loan Creation Year" value="2014" />
// <field name="Full term of loan in years" value="7" />
// <field name="Principal amount of loan" value="75000" />
// <field name="Lodgment day of private company" value="2015-05-15" />
// </loanAgreement><repayments><repayment date="2014-08-31" value="20000" />
// <repayment date="2015-05-30" value="8000" /></repayments></loandetails></reports>'
// -ContentType application/xml -Method POST
//
// You should receive a response, and its Content property should contain a summary of the
// loan balances at year ends. It should start as follows:
//
// <ArrayOfLoanSummary xmlns:i="http://www.w3.org/2001/XMLSchema-instance"
// xmlns="http://schemas.datacontract.org/2004/07/PrologEndpoint.Models">
// <LoanSummary><ClosingBalance>50230.768493150681</ClosingBalance>


namespace PrologEndpoint
{
    public class WebApiApplication : System.Web.HttpApplication
    {
        // Make space for a pool of 10 Prolog engines where 10 is arbitrary. Each engine uses
        // a large amount of memory, so the chosen number of engines should not be too large.
        // The number should also not be to small, otherwise only a small number of HTTP clients
        // will get their queries serviced at a given point in time.
        public static IntPtr[] PrologEngines = new IntPtr[10];

        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            GlobalConfiguration.Configure(WebApiConfig.Register);
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
            InitialiseProlog();
        }

        /* Initialize the Prolog library and a pool of engines. */
        protected void InitialiseProlog()
        {
            // See http://www.swi-prolog.org/pldoc/man?section=cmdline
            // Also see http://www.swi-prolog.org/pldoc/man?CAPI=PL_initialise
            // Create argument vector to Prolog in unmanaged memory as the C code will be holding
            // onto it. I could have just fixed the argument vector in memory though...
            const int argc = 3;
            IntPtr argv = Marshal.AllocHGlobal(argc * IntPtr.Size);
            Marshal.Copy(new IntPtr[argc] {
                Marshal.StringToHGlobalAnsi(System.Reflection.Assembly.GetExecutingAssembly().Location),
                Marshal.StringToHGlobalAnsi("-s"),
                Marshal.StringToHGlobalAnsi("C:\\Users\\murisi\\Mirror\\labs-accounts-assessor\\main.pl")
            }, 0, argv, argc);
            PL.PL_initialise(argc, argv);

            // See http://www.swi-prolog.org/pldoc/man?CAPI=PL_create_engine
            // According to the documentation: "For any field with value `0', the default is used."
            // Hence here we are describing a Prolog thread with a default configuration.
            PL_thread_attr_t ta = new PL_thread_attr_t
            {
                alias = IntPtr.Zero,
                cancel = IntPtr.Zero,
                flags = 0,
                max_queue_size = new UIntPtr(0),
                stack_limit = new UIntPtr(0),
                table_space = new UIntPtr(0)
            };

            // Create a pool of Prolog engines that can be used to service this web application's
            // requests. When it comes time to service a query, we will choose the first currently
            // unused engine from this pool.
            for (int i = 0; i < PrologEngines.Length; i++)
                PrologEngines[i] = PL.PL_create_engine(ref ta);
        }
    }
}
