using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Web;
using static PrologEndpoint.Helpers.PL;

namespace PrologEndpoint.Helpers
{
    public class Utils
    {
        private static unsafe readonly char* DATE = (char*)Marshal.StringToHGlobalAnsi("date");
        private static unsafe readonly char* ABSOLUTE_DAY = (char*)Marshal.StringToHGlobalAnsi("absolute_day");
        private static unsafe readonly char* TERM_STRING = (char*)Marshal.StringToHGlobalAnsi("term_string");

        /* Computes the absolute day of the given date. */
        public static unsafe int ComputeAbsoluteDay(DateTime date)
        {
            // Constructing the term date(date.Year, date.Month, date.Day)
            atom_t* date_atom = PL.PL_new_atom(DATE);
            functor_t* date_functor = PL.PL_new_functor(date_atom, 3);
            term_t* date_year_term = PL.PL_new_term_ref();
            PL.PL_put_integer(date_year_term, date.Year);
            term_t* date_month_term = PL.PL_new_term_ref();
            PL.PL_put_integer(date_month_term, date.Month);
            term_t* date_day_term = PL.PL_new_term_ref();
            PL.PL_put_integer(date_day_term, date.Day);
            term_t* date_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(date_term, date_functor, __arglist(date_year_term, date_month_term, date_day_term));

            // Constructing the query absolute_day(date(date.Year, date.Month, date.Day), B)
            predicate_t* absolute_day_pred = PL.PL_predicate(ABSOLUTE_DAY, 2, null);
            term_t* absolute_day_pred_arg0 = PL.PL_new_term_refs(2);
            PL.PL_put_term(absolute_day_pred_arg0, date_term);
            term_t* absolute_day_pred_arg1 = (term_t*)(1 + (byte*)absolute_day_pred_arg0);
            term_t* absolute_day_term = PL.PL_new_term_ref();
            PL.PL_put_term(absolute_day_pred_arg1, absolute_day_term);
            qid_t* qid = PL.PL_open_query(null, PL.PL_Q_NORMAL, absolute_day_pred, absolute_day_pred_arg0);

            // Getting a solution B to the query and close query
            PL.PL_next_solution(qid);
            int absolute_day;
            PL.PL_get_integer(absolute_day_term, &absolute_day);
            PL.PL_close_query(qid);
            return absolute_day;
        }

        /* Gets the string representation of a Prolog term. */
        public static unsafe String TermString(term_t *term)
        {
            // Constructing the query term.string(Term, String_Term)
            predicate_t* term_string_pred = PL.PL_predicate(TERM_STRING, 2, null);
            term_t* term_string_pred_arg0 = PL.PL_new_term_refs(2);
            PL.PL_put_term(term_string_pred_arg0, term);
            term_t* absolute_day_pred_arg1 = (term_t*)(1 + (byte*)term_string_pred_arg0);
            term_t* string_term = PL.PL_new_term_ref();
            PL.PL_put_term(absolute_day_pred_arg1, string_term);
            qid_t* qid = PL.PL_open_query(null, PL.PL_Q_NORMAL, term_string_pred, term_string_pred_arg0);

            // Getting a solution String_Term to the query and close query
            PL.PL_next_solution(qid);
            char *tstring;
            UIntPtr length;
            PL.PL_get_string(string_term, &tstring, &length);
            PL.PL_close_query(qid);
            return Marshal.PtrToStringAnsi(new IntPtr(tstring), (int) length);
        }
    }
}