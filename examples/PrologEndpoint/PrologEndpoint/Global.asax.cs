using PrologEndpoint.Helpers;
using System;
using System.Runtime.InteropServices;
using System.Web.Http;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;
using static PrologEndpoint.Helpers.PL;

// This program is a demonstration of how a C# web application can run SWI Prolog queries
// using the SWI-Prolog Foreign Language Interface. This program works as follows: SWI-Prolog
// provides a DLL library called libswipl.dll that can load Prolog scripts and execute queries
// on them. The PL class in this document simply declares the functions in the DLL file to the
// rest of this C# program. The controllers in this project simply utilizes the DLL files's
// functions to execute a Prolog query.


namespace PrologEndpoint
{
    public class WebApiApplication : System.Web.HttpApplication
    {
        // Make space for a pool of 10 Prolog engines where 10 is arbitrary. Each engine uses
        // a large amount of memory, so the chosen number of engines should not be too large.
        // The number should also not be to small, otherwise only a small number of HTTP clients
        // will get their queries serviced at a given point in time.
        public unsafe static PL_engine_t*[] PrologEngines = new PL_engine_t*[10];

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
        protected unsafe void InitialiseProlog()
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
            PL.PL_initialise(argc, (char **) argv);

            // See http://www.swi-prolog.org/pldoc/man?CAPI=PL_create_engine
            // According to the documentation: "For any field with value `0', the default is used."
            // Hence here we are describing a Prolog thread with a default configuration.
            PL_thread_attr_t ta = new PL_thread_attr_t
            {
                alias = null,
                cancel = null,
                flags = new IntPtr(0),
                max_queue_size = new UIntPtr(0),
                stack_limit = new UIntPtr(0),
                table_space = new UIntPtr(0)
            };

            // Create a pool of Prolog engines that can be used to service this web application's
            // requests. When it comes time to service a query, we will choose the first currently
            // unused engine from this pool.
            for (int i = 0; i < PrologEngines.Length; i++)
                PrologEngines[i] = PL.PL_create_engine(&ta);
        }
    }
}
