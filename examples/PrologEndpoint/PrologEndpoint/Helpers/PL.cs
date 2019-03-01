using System;
using System.Runtime.InteropServices;
using System.Text;

namespace PrologEndpoint.Helpers
{
    public class PL
    {
        // Location of the Prolog Kernel that comes with every SWI-Prolog distribution
        private const string dllName = "C:\\Program Files\\swipl\\bin\\libswipl.dll";

        /*  Part of SWI-Prolog

        Author:        Jan Wielemaker
        E-mail:        J.Wielemaker@vu.nl
        WWW:           http://www.swi-prolog.org
        Copyright (c)  2008-2017, University of Amsterdam
                                  VU University Amsterdam
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions
        are met:

        1. Redistributions of source code must retain the above copyright
           notice, this list of conditions and the following disclaimer.

        2. Redistributions in binary form must reproduce the above copyright
           notice, this list of conditions and the following disclaimer in
           the documentation and/or other materials provided with the
           distribution.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
        "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
        LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
        FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
        COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
        INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
        BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
        LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
        CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
        LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
        ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
        POSSIBILITY OF SUCH DAMAGE.
    */

        /* PLVERSION: 10000 * <Major> + 100 * <Minor> + <Patch> */
        /* PLVERSION_TAG: a string, normally "", but for example "rc1" */

        public const int PLVERSION = 80001;
        public const string PLVERSION_TAG = "";


        /*******************************
        *	       EXPORT		*
        *******************************/

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        Traditional and ELF-based Unix systems  don't   need  all this, but COFF
        based systems need  to  import  and   export  symbols  explicitely  from
        executables and shared objects (DLL). On some systems (e.g. AIX) this is
        achieved using import/export files, on Windows   this  is achieved using
        special  declarations  on  exported  symbols.  So,  a  symbol  is  local
        (static), shared between the objects building   an executable or DLL (no
        special declaration) or exported from the executable or DLL.

        Both using native Microsoft MSVC as well   as recent Cygwin (tested 1.1)
        compilers support __declspec(...) for exporting symbols.

        As SWI-Prolog.h can be included seperately or together with this file we
        duplicated this stuff.
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

        struct install_t { }


        /*******************************
        *	       TYPES		*
        *******************************/

        public struct IOSTREAM { };
        public struct mpz_t { };
        public struct mpq_t { };
        public struct atom_t { };      /* Prolog atom */
        public struct functor_t { };   /* Name/arity pair */
        public struct module_t { }; /* Prolog module */
        public struct predicate_t { };  /* Prolog procedure */
        public struct record_t { }; /* Prolog recorded term */
        public struct term_t { };      /* opaque term handle */
        public struct qid_t { };       /* opaque query handle */
        public struct fid_t { };    /* opaque foreign context handle */
        public struct control_t { };    /* non-deterministic control arg */
        public struct PL_engine_t { };  /* opaque engine handle */

        public struct PL_atomic_t { };  /* same a word */
        public struct foreign_t { };	/* return type of foreign functions */
        public struct pl_function_t { }; /* foreign language functions */

        /* values for PL_get_term_value() */
        [StructLayout(LayoutKind.Explicit)]
        public unsafe struct term_value_t
        {
            [FieldOffset(0)] public Int64 i; /* PL_INTEGER */
            [FieldOffset(0)] public double f; /* PL_FLOAT */
            [FieldOffset(0)] public char* s; /* PL_STRING */
            [FieldOffset(0)] public atom_t* a;	/* PL_ATOM */
            public struct t_type /* PL_TERM */
            {
                public atom_t* name;
                public UIntPtr arity;
            }
            [FieldOffset(0)]
            public t_type t;
        };

        public const int TRUE = 1;
        public const int FALSE = 0;

        /*******************************
        *      TERM-TYPE CONSTANTS	*
        *******************************/
        /* PL_unify_term() arguments */
        public const int PL_VARIABLE = 1; /* nothing */
        public const int PL_ATOM = 2; /* const char * */
        public const int PL_INTEGER = 3; /* int */
        public const int PL_FLOAT = 4; /* double */
        public const int PL_STRING = 5; /* const char * */
        public const int PL_TERM = 6;
        public const int PL_NIL = 7; /* The constant [] */
        public const int PL_BLOB = 8; /* non-atom blob */
        public const int PL_LIST_PAIR = 9; /* [_|_] term */

        /* PL_unify_term() */
        public const int PL_FUNCTOR = 10; /* functor_t, arg ... */
        public const int PL_LIST = 11; /* length, arg ... */
        public const int PL_CHARS = 12; /* const char * */
        public const int PL_POINTER = 13; /* void * */
                                          /* PlArg::PlArg(text, type) */
        public const int PL_CODE_LIST = 14; /* [ascii...] */
        public const int PL_CHAR_LIST = 15; /* [h,e,l,l,o] */
        public const int PL_BOOL = 16; /* PL_set_prolog_flag() */
        public const int PL_FUNCTOR_CHARS = 17; /* PL_unify_term() */
        public const int _PL_PREDICATE_INDICATOR = 18; /* predicate_t (Procedure) */
        public const int PL_SHORT = 19; /* short */
        public const int PL_INT = 20; /* int */
        public const int PL_LONG = 21; /* long */
        public const int PL_DOUBLE = 22; /* double */
        public const int PL_NCHARS = 23; /* size_t, const char * */
        public const int PL_UTF8_CHARS = 24; /* const char * */
        public const int PL_UTF8_STRING = 25; /* const char * */
        public const int PL_INT64 = 26; /* int64_t */
        public const int PL_NUTF8_CHARS = 27; /* size_t, const char * */
        public const int PL_NUTF8_CODES = 29; /* size_t, const char * */
        public const int PL_NUTF8_STRING = 30; /* size_t, const char * */
        public const int PL_NWCHARS = 31; /* size_t, const wchar_t * */
        public const int PL_NWCODES = 32; /* size_t, const wchar_t * */
        public const int PL_NWSTRING = 33; /* size_t, const wchar_t * */
        public const int PL_MBCHARS = 34; /* const char * */
        public const int PL_MBCODES = 35; /* const char * */
        public const int PL_MBSTRING = 36; /* const char * */
        public const int PL_INTPTR = 37; /* intptr_t */
        public const int PL_CHAR = 38; /* int */
        public const int PL_CODE = 39; /* int */
        public const int PL_BYTE = 40; /* int */
                                       /* PL_skip_list() */
        public const int PL_PARTIAL_LIST = 41; /* a partial list */
        public const int PL_CYCLIC_TERM = 42; /* a cyclic list/term */
        public const int PL_NOT_A_LIST = 43; /* Object is not a list */
                                             /* dicts */
        public const int PL_DICT = 44;
        /* Or'ed flags for PL_set_prolog_flag() */
        /* MUST fit in a short int! */
        public const int FF_READONLY = 0x1000; /* Read-only prolog flag */
        public const int FF_KEEP = 0x2000; /* keep prolog flag if already set */
        public const int FF_NOCREATE = 0x4000; /* Fail if flag is non-existent */
        public const int FF_FORCE = 0x8000; /* Force setting, overwrite READONLY */
        public const int FF_MASK = 0xf000;


        /********************************
		* NON-DETERMINISTIC CALL/RETURN *
		*********************************/

        /*  Note 1: Non-deterministic foreign functions may also use the deterministic
            return methods PL_succeed and PL_fail.

            Note 2: The argument to PL_retry is a sizeof(ptr)-2 bits signed
            integer (use type intptr_t).
        */

        public const int PL_FIRST_CALL = 0;
        public const int PL_CUTTED = 1;	/* deprecated */
        public const int PL_PRUNED = 1;
        public const int PL_REDO = 2;

        [DllImport(dllName)] public extern unsafe static foreign_t* _PL_retry(IntPtr a);
        [DllImport(dllName)] public extern unsafe static foreign_t* _PL_retry_address(void* a);
        [DllImport(dllName)] public extern unsafe static int PL_foreign_control(control_t* a);
        [DllImport(dllName)] public extern unsafe static IntPtr PL_foreign_context(control_t* a);
        [DllImport(dllName)] public extern unsafe static void* PL_foreign_context_address(control_t* a);
        [DllImport(dllName)] public extern unsafe static predicate_t* PL_foreign_context_predicate(control_t* a);


        /********************************
        *      REGISTERING FOREIGNS     *
        *********************************/

        [StructLayout(LayoutKind.Sequential)]
        public unsafe struct PL_extension
        {
            public char* predicate_name;     /* Name of the predicate */
            public short arity;            /* Arity of the predicate */
            public pl_function_t* function;     /* Implementing functions */
            public short flags;         /* Or of PL_FA_... */
        }

        public const int PL_FA_NOTRACE = 0x01; /* foreign cannot be traced */
        public const int PL_FA_TRANSPARENT = 0x02; /* foreign is module transparent */
        public const int PL_FA_NONDETERMINISTIC = 0x04; /* foreign is non-deterministic */
        public const int PL_FA_VARARGS = 0x08; /* call using t0, ac, ctx */
        public const int PL_FA_CREF = 0x10; /* Internal: has clause-reference */
        public const int PL_FA_ISO = 0x20; /* Internal: ISO core predicate */
        public const int PL_FA_META = 0x40; /* Additional meta-argument spec */

        [DllImport(dllName)] public extern unsafe static void PL_register_extensions(PL_extension* e);
        [DllImport(dllName)] public extern unsafe static void PL_register_extensions_in_module(char* module, PL_extension* e);
        [DllImport(dllName)] public extern unsafe static int PL_register_foreign(char* name, int arity, pl_function_t func, int flags, __arglist);
        [DllImport(dllName)] public extern unsafe static int PL_register_foreign_in_module(char* module, char* name, int arity, pl_function_t* func, int flags, __arglist);
        [DllImport(dllName)] public extern unsafe static void PL_load_extensions(PL_extension* e);

        /*******************************
        *	      LICENSE		*
        *******************************/

        [DllImport(dllName)] public extern unsafe static void PL_license(char* license, char* module);

        /********************************
        *            MODULES            *
        *********************************/

        [DllImport(dllName)] public extern unsafe static module_t* PL_context();
        [DllImport(dllName)] public extern unsafe static atom_t* PL_module_name(module_t* module);
        [DllImport(dllName)] public extern unsafe static module_t* PL_new_module(atom_t* name);
        [DllImport(dllName)] public extern unsafe static int PL_strip_module(term_t* _in, module_t** m, term_t* _out);

        /*******************************
        *	     CONSTANTS		*
        *******************************/

        [DllImport(dllName)] public extern unsafe static atom_t** _PL_atoms(); /* base of reserved (meta-)atoms */
        public unsafe static atom_t* ATOM_nil() { return _PL_atoms()[0]; } /* `[]` */
        public unsafe static atom_t* ATOM_dot() { return _PL_atoms()[1]; } /* `.` */


        /*******************************
        *	     CALL-BACK		*
        *******************************/

        public const int PL_Q_DEBUG = 0x0001; /* = TRUE for backward compatibility */
        public const int PL_Q_NORMAL = 0x0002; /* normal usage */
        public const int PL_Q_NODEBUG = 0x0004; /* use this one */
        public const int PL_Q_CATCH_EXCEPTION = 0x0008; /* handle exceptions in C */
        public const int PL_Q_PASS_EXCEPTION = 0x0010; /* pass to parent environment */
        public const int PL_Q_ALLOW_YIELD = 0x0020; /* Support I_YIELD */
        public const int PL_Q_EXT_STATUS = 0x0040; /* Return extended status */
        public const int PL_Q_DETERMINISTIC = 0x0100; /* call was deterministic */

        /* PL_Q_EXT_STATUS return codes */
        public const int PL_S_EXCEPTION = -1; /* Query raised exception */
        public const int PL_S_FALSE = 0; /* Query failed */
        public const int PL_S_TRUE = 1; /* Query succeeded with choicepoint */
        public const int PL_S_LAST = 2; /* Query succeeded without CP */


        /* Foreign context frames */
        [DllImport(dllName)] public extern unsafe static fid_t* PL_open_foreign_frame();
        [DllImport(dllName)] public extern unsafe static void PL_rewind_foreign_frame(fid_t* cid);
        [DllImport(dllName)] public extern unsafe static void PL_close_foreign_frame(fid_t* cid);
        [DllImport(dllName)] public extern unsafe static void PL_discard_foreign_frame(fid_t* cid);

        /* Finding predicates */
        [DllImport(dllName)] public extern unsafe static predicate_t* PL_pred(functor_t* f, module_t* m);
        [DllImport(dllName)] public extern unsafe static predicate_t* PL_predicate(char* name, int arity, char* module);
        [DllImport(dllName)] public extern unsafe static int PL_predicate_info(predicate_t* pred, atom_t** name, UIntPtr* arity, module_t** module);

        /* Call-back */
        [DllImport(dllName)] public extern unsafe static qid_t* PL_open_query(module_t* m, int flags, predicate_t* pred, term_t* t0);
        [DllImport(dllName)] public extern unsafe static int PL_next_solution(qid_t* qid);
        [DllImport(dllName)] public extern unsafe static int PL_close_query(qid_t* qid);
        [DllImport(dllName)] public extern unsafe static int PL_cut_query(qid_t* qid);
        [DllImport(dllName)] public extern unsafe static qid_t* PL_current_query();

        /* Simplified (but less flexible) call-back */
        [DllImport(dllName)] public extern unsafe static int PL_call(term_t* t, module_t* m);
        [DllImport(dllName)] public extern unsafe static int PL_call_predicate(module_t* m, int debug, predicate_t* pred, term_t* t0);
        /* Handling exceptions */
        [DllImport(dllName)] public extern unsafe static term_t* PL_exception(qid_t* qid);
        [DllImport(dllName)] public extern unsafe static int PL_raise_exception(term_t* exception);
        [DllImport(dllName)] public extern unsafe static int PL_throw(term_t* exception);
        [DllImport(dllName)] public extern unsafe static void PL_clear_exception();
        /* Engine-based coroutining */
        [DllImport(dllName)] public extern unsafe static term_t* PL_yielded(qid_t* qid);


        /*******************************
        *        TERM-REFERENCES	*
        *******************************/

        /* Creating and destroying term-refs */
        [DllImport(dllName)] public extern unsafe static term_t* PL_new_term_refs(int n);
        [DllImport(dllName)] public extern unsafe static term_t* PL_new_term_ref();
        [DllImport(dllName)] public extern unsafe static term_t* PL_copy_term_ref(term_t* from);
        [DllImport(dllName)] public extern unsafe static void PL_reset_term_refs(term_t* r);

        /* Constants */
        [DllImport(dllName)] public extern unsafe static atom_t* PL_new_atom(char* s);
        [DllImport(dllName)] public extern unsafe static atom_t* PL_new_atom_nchars(UIntPtr len, char* s);
        [DllImport(dllName)] public extern unsafe static atom_t* PL_new_atom_wchars(UIntPtr len, UIntPtr* s);
        [DllImport(dllName)] public extern unsafe static atom_t* PL_new_atom_mbchars(int rep, UIntPtr len, char* s);
        [DllImport(dllName)] public extern unsafe static char* PL_atom_chars(atom_t* a);
        [DllImport(dllName)] public extern unsafe static char* PL_atom_nchars(atom_t* a, UIntPtr* len);
        [DllImport(dllName)] public extern unsafe static short* PL_atom_wchars(atom_t* a, UIntPtr* len);

        [DllImport(dllName)] public extern unsafe static void PL_register_atom(atom_t* a);
        [DllImport(dllName)] public extern unsafe static void PL_unregister_atom(atom_t* a);

        [DllImport(dllName)] public extern unsafe static functor_t* PL_new_functor_sz(atom_t* f, UIntPtr a);
        [DllImport(dllName)] public extern unsafe static functor_t* PL_new_functor(atom_t* f, int a);
        [DllImport(dllName)] public extern unsafe static atom_t* PL_functor_name(functor_t* f);
        [DllImport(dllName)] public extern unsafe static int PL_functor_arity(functor_t* f);
        [DllImport(dllName)] public extern unsafe static UIntPtr PL_functor_arity_sz(functor_t* f);

        /* Get C-values from Prolog terms */
        [DllImport(dllName)] public extern unsafe static int PL_get_atom(term_t* t, atom_t** a);
        [DllImport(dllName)] public extern unsafe static int PL_get_bool(term_t* t, int* value);
        [DllImport(dllName)] public extern unsafe static int PL_get_atom_chars(term_t* t, char** a);
        public unsafe static int PL_get_string_chars(term_t* t, char** s, UIntPtr* len) { return PL_get_string(t, s, len); }
        /* PL_get_string() is deprecated */
        [DllImport(dllName)] public extern unsafe static int PL_get_string(term_t* t, char** s, UIntPtr* len);
        [DllImport(dllName)] public extern unsafe static int PL_get_chars(term_t* t, char** s, uint flags);
        [DllImport(dllName)] public extern unsafe static int PL_get_list_chars(term_t* l, char** s, uint flags);
        [DllImport(dllName)] public extern unsafe static int PL_get_atom_nchars(term_t* t, UIntPtr* len, char** a);
        [DllImport(dllName)] public extern unsafe static int PL_get_list_nchars(term_t* l, UIntPtr* len, char** s, uint flags);
        [DllImport(dllName)] public extern unsafe static int PL_get_nchars(term_t* t, UIntPtr* len, char** s, uint flags);
        [DllImport(dllName)] public extern unsafe static int PL_get_integer(term_t* t, int* i);
        [DllImport(dllName)] public extern unsafe static int PL_get_long(term_t* t, long* i);
        [DllImport(dllName)] public extern unsafe static int PL_get_intptr(term_t* t, IntPtr* i);
        [DllImport(dllName)] public extern unsafe static int PL_get_pointer(term_t* t, void** ptr);
        [DllImport(dllName)] public extern unsafe static int PL_get_float(term_t* t, double* f);
        [DllImport(dllName)] public extern unsafe static int PL_get_functor(term_t* t, functor_t** f);
        [DllImport(dllName)] public extern unsafe static int PL_get_name_arity_sz(term_t* t, atom_t** name, UIntPtr* arity);
        [DllImport(dllName)] public extern unsafe static int PL_get_compound_name_arity_sz(term_t* t, atom_t** name, UIntPtr* arity);
        [DllImport(dllName)] public extern unsafe static int PL_get_name_arity(term_t* t, atom_t** name, int* arity);
        [DllImport(dllName)] public extern unsafe static int PL_get_compound_name_arity(term_t* t, atom_t** name, int* arity);
        [DllImport(dllName)] public extern unsafe static int PL_get_module(term_t* t, module_t** module);
        [DllImport(dllName)] public extern unsafe static int PL_get_arg_sz(UIntPtr index, term_t* t, term_t* a);
        [DllImport(dllName)] public extern unsafe static int PL_get_arg(int index, term_t* t, term_t* a);
        [DllImport(dllName)] public extern unsafe static int PL_get_list(term_t* l, term_t* h, term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_get_head(term_t* l, term_t* h);
        [DllImport(dllName)] public extern unsafe static int PL_get_tail(term_t* l, term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_get_nil(term_t* l);
        [DllImport(dllName)] public extern unsafe static int PL_get_term_value(term_t* t, term_value_t** v);
        [DllImport(dllName)] public extern unsafe static char* PL_quote(int chr, char* data);

        /* Verify types */
        [DllImport(dllName)] public extern unsafe static int PL_term_type(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_variable(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_ground(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_atom(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_integer(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_string(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_float(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_rational(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_compound(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_callable(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_functor(term_t* t, functor_t* f);
        [DllImport(dllName)] public extern unsafe static int PL_is_list(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_pair(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_atomic(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_number(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_is_acyclic(term_t* t);

        /* Assign to term-references */
        [DllImport(dllName)] public extern unsafe static int PL_put_variable(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_put_atom(term_t* t, atom_t* a);
        [DllImport(dllName)] public extern unsafe static int PL_put_bool(term_t* t, int val);
        [DllImport(dllName)] public extern unsafe static int PL_put_atom_chars(term_t* t, char* chars);
        public unsafe static int PL_put_atom_chars(term_t* t, string chars)
        {
            IntPtr str = Marshal.StringToHGlobalAnsi(chars);
            int ret = PL.PL_put_atom_chars(t, (char *) str.ToPointer());
            Marshal.FreeHGlobal(str);
            return ret;
        }
        [DllImport(dllName)] public extern unsafe static int PL_put_string_chars(term_t* t, char* chars);
        public unsafe static int PL_put_string_chars(term_t* t, string chars)
        {
            IntPtr str = Marshal.StringToHGlobalAnsi(chars);
            int ret = PL.PL_put_string_chars(t, (char*)str.ToPointer());
            Marshal.FreeHGlobal(str);
            return ret;
        }
        [DllImport(dllName)] public extern unsafe static int PL_put_chars(term_t* t, int flags, UIntPtr len, char* chars);
        [DllImport(dllName)] public extern unsafe static int PL_put_list_chars(term_t* t, char* chars);
        [DllImport(dllName)] public extern unsafe static int PL_put_list_codes(term_t* t, char* chars);
        [DllImport(dllName)] public extern unsafe static int PL_put_atom_nchars(term_t* t, UIntPtr l, char* chars);
        [DllImport(dllName)] public extern unsafe static int PL_put_string_nchars(term_t* t, UIntPtr len, char* chars);
        [DllImport(dllName)] public extern unsafe static int PL_put_list_nchars(term_t* t, UIntPtr l, char* chars);
        [DllImport(dllName)] public extern unsafe static int PL_put_list_ncodes(term_t* t, UIntPtr l, char* chars);
        [DllImport(dllName)] public extern unsafe static int PL_put_integer(term_t* t, long i);
        [DllImport(dllName)] public extern unsafe static int PL_put_pointer(term_t* t, void* ptr);
        [DllImport(dllName)] public extern unsafe static int PL_put_float(term_t* t, double f);
        [DllImport(dllName)] public extern unsafe static int PL_put_functor(term_t* t, functor_t* functor);
        [DllImport(dllName)] public extern unsafe static int PL_put_list(term_t* l);
        [DllImport(dllName)] public extern unsafe static int PL_put_nil(term_t* l);
        [DllImport(dllName)] public extern unsafe static int PL_put_term(term_t* t1, term_t* t2);

        /* construct a functor or list-cell */
        [DllImport(dllName)] public extern unsafe static int PL_cons_functor(term_t* h, functor_t* f, __arglist);
        [DllImport(dllName)] public extern unsafe static int PL_cons_functor_v(term_t* h, functor_t* fd, term_t* a0);
        [DllImport(dllName)] public extern unsafe static int PL_cons_list(term_t* l, term_t* h, term_t* t);

        /* Unify term-references */
        [DllImport(dllName)] public extern unsafe static int PL_unify(term_t* t1, term_t* t2);
        [DllImport(dllName)] public extern unsafe static int PL_unify_atom(term_t* t, atom_t* a);
        [DllImport(dllName)] public extern unsafe static int PL_unify_atom_chars(term_t* t, char* chars);
        [DllImport(dllName)] public extern unsafe static int PL_unify_list_chars(term_t* t, char* chars);
        [DllImport(dllName)] public extern unsafe static int PL_unify_list_codes(term_t* t, char* chars);
        [DllImport(dllName)] public extern unsafe static int PL_unify_string_chars(term_t* t, char* chars);
        public unsafe static int PL_unify_string_chars(term_t* t, string chars)
        {
            IntPtr str = Marshal.StringToHGlobalAnsi(chars);
            int ret = PL.PL_unify_string_chars(t, (char*)str.ToPointer());
            Marshal.FreeHGlobal(str);
            return ret;
        }
        [DllImport(dllName)] public extern unsafe static int PL_unify_atom_nchars(term_t* t, UIntPtr l, char* s);
        [DllImport(dllName)] public extern unsafe static int PL_unify_list_ncodes(term_t* t, UIntPtr l, char* s);
        [DllImport(dllName)] public extern unsafe static int PL_unify_list_nchars(term_t* t, UIntPtr l, char* s);
        [DllImport(dllName)] public extern unsafe static int PL_unify_string_nchars(term_t* t, UIntPtr len, char* chars);
        [DllImport(dllName)] public extern unsafe static int PL_unify_bool(term_t* t, int n);
        [DllImport(dllName)] public extern unsafe static int PL_unify_integer(term_t* t, IntPtr n);
        [DllImport(dllName)] public extern unsafe static int PL_unify_float(term_t* t, double f);
        [DllImport(dllName)] public extern unsafe static int PL_unify_pointer(term_t* t, void* ptr);
        [DllImport(dllName)] public extern unsafe static int PL_unify_functor(term_t* t, functor_t* f);
        [DllImport(dllName)] public extern unsafe static int PL_unify_compound(term_t* t, functor_t* f);
        [DllImport(dllName)] public extern unsafe static int PL_unify_list(term_t* l, term_t* h, term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_unify_nil(term_t* l);
        [DllImport(dllName)] public extern unsafe static int PL_unify_arg_sz(UIntPtr index, term_t* t, term_t* a);
        [DllImport(dllName)] public extern unsafe static int PL_unify_arg(int index, term_t* t, term_t* a);
        [DllImport(dllName)] public extern unsafe static int PL_unify_term(term_t* t, __arglist);
        [DllImport(dllName)] public extern unsafe static int PL_unify_chars(term_t* t, int flags, UIntPtr len, char* s);

        /*******************************
        *	       LISTS		*
        *******************************/

        [DllImport(dllName)] public extern unsafe static int PL_skip_list(term_t* list, term_t* tail, UIntPtr* len);


        /*******************************
        *    WIDE CHARACTER VERSIONS	*
        *******************************/

        [DllImport(dllName)] public extern unsafe static int PL_unify_wchars(term_t* t, int type, UIntPtr len, short* s);
        [DllImport(dllName)] public extern unsafe static int PL_unify_wchars_diff(term_t* t, term_t* tail, int type, UIntPtr len, short* s);
        [DllImport(dllName)] public extern unsafe static int PL_get_wchars(term_t* l, UIntPtr* length, short** s, uint flags);
        [DllImport(dllName)] public extern unsafe static UIntPtr PL_utf8_strlen(char* s, UIntPtr len);


        /*******************************
        *	   WIDE INTEGERS	*
        *******************************/


        [DllImport(dllName)] public extern unsafe static int PL_get_int64(term_t* t, Int64* i);
        [DllImport(dllName)] public extern unsafe static int PL_unify_int64(term_t* t, Int64 value);
        [DllImport(dllName)] public extern unsafe static int PL_unify_uint64(term_t* t, Int64 value);
        [DllImport(dllName)] public extern unsafe static int PL_put_int64(term_t* t, Int64 i);


        /*******************************
        *     ATTRIBUTED VARIABLES	*
        *******************************/

        [DllImport(dllName)] public extern unsafe static int PL_is_attvar(term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_get_attr(term_t* v, term_t* a);


        /*******************************
        *	      ERRORS		*
        *******************************/

        [DllImport(dllName)] public extern unsafe static int PL_get_atom_ex(term_t* t, atom_t** a);
        [DllImport(dllName)] public extern unsafe static int PL_get_integer_ex(term_t* t, int* i);
        [DllImport(dllName)] public extern unsafe static int PL_get_long_ex(term_t* t, long* i);
        [DllImport(dllName)] public extern unsafe static int PL_get_int64_ex(term_t* t, Int64* i);
        [DllImport(dllName)] public extern unsafe static int PL_get_intptr_ex(term_t* t, Int64* i);
        [DllImport(dllName)] public extern unsafe static int PL_get_size_ex(term_t* t, UIntPtr* i);
        [DllImport(dllName)] public extern unsafe static int PL_get_bool_ex(term_t* t, int* i);
        [DllImport(dllName)] public extern unsafe static int PL_get_float_ex(term_t* t, double* f);
        [DllImport(dllName)] public extern unsafe static int PL_get_char_ex(term_t* t, int* p, int eof);
        [DllImport(dllName)] public extern unsafe static int PL_unify_bool_ex(term_t* t, int val);
        [DllImport(dllName)] public extern unsafe static int PL_get_pointer_ex(term_t* t, void** addrp);
        [DllImport(dllName)] public extern unsafe static int PL_unify_list_ex(term_t* l, term_t* h, term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_unify_nil_ex(term_t* l);
        [DllImport(dllName)] public extern unsafe static int PL_get_list_ex(term_t* l, term_t* h, term_t* t);
        [DllImport(dllName)] public extern unsafe static int PL_get_nil_ex(term_t* l);

        [DllImport(dllName)] public extern unsafe static int PL_instantiation_error(term_t* culprit);
        [DllImport(dllName)] public extern unsafe static int PL_uninstantiation_error(term_t* culprit);
        [DllImport(dllName)] public extern unsafe static int PL_representation_error(char* resource);
        [DllImport(dllName)] public extern unsafe static int PL_type_error(char* expected, term_t* culprit);
        [DllImport(dllName)] public extern unsafe static int PL_domain_error(char* expected, term_t* culprit);
        [DllImport(dllName)] public extern unsafe static int PL_existence_error(char* type, term_t* culprit);
        [DllImport(dllName)] public extern unsafe static int PL_permission_error(char* operation, char* type, term_t* culprit);
        [DllImport(dllName)] public extern unsafe static int PL_resource_error(char* resource);
        [DllImport(dllName)] public extern unsafe static int PL_syntax_error(char* msg, void* _in);

        /*******************************
        *	       BLOBS		*
        *******************************/

        public const uint PL_BLOB_MAGIC_B = 0x75293a00; /* Magic to validate a blob-type */
        public const uint PL_BLOB_VERSION = 1; /* Current version */
        public const uint PL_BLOB_MAGIC = (PL_BLOB_MAGIC_B | PL_BLOB_VERSION);

        public const int PL_BLOB_UNIQUE = 0x01; /* Blob content is unique */
        public const int PL_BLOB_TEXT = 0x02; /* blob contains text */
        public const int PL_BLOB_NOCOPY = 0x04; /* do not copy the data */
        public const int PL_BLOB_WCHAR = 0x08; /* wide character string */

        [StructLayout(LayoutKind.Sequential)]
        public unsafe struct PL_blob_t
        {
            UIntPtr magic;        /* PL_BLOB_MAGIC */
            UIntPtr flags;        /* PL_BLOB_* */
            char* name;     /* name of the type */
            void* release;
            void* compare;
            void* write;

            void* acquire;
            void* save;
            void* load;
            UIntPtr padding;   /* Required 0-padding */
                               /* private */
        }

        [DllImport(dllName)] public extern unsafe static int PL_is_blob(term_t* t, PL_blob_t** type);
        [DllImport(dllName)] public extern unsafe static int PL_unify_blob(term_t* t, void* blob, UIntPtr len, PL_blob_t* type);
        [DllImport(dllName)] public extern unsafe static int PL_put_blob(term_t* t, void* blob, UIntPtr len, PL_blob_t* type);
        [DllImport(dllName)] public extern unsafe static int PL_get_blob(term_t* t, void** blob, UIntPtr* len, PL_blob_t** type);

        [DllImport(dllName)] public extern unsafe static void* PL_blob_data(atom_t* a, UIntPtr* len, PL_blob_t** type);

        [DllImport(dllName)] public extern unsafe static void PL_register_blob_type(PL_blob_t* type);
        [DllImport(dllName)] public extern unsafe static PL_blob_t* PL_find_blob_type(char* name);
        [DllImport(dllName)] public extern unsafe static int PL_unregister_blob_type(PL_blob_t* type);


        /*******************************
        *	       GMP		*
        *******************************/

        [DllImport(dllName)] public extern unsafe static int PL_get_mpz(term_t* t, mpz_t* mpz);
        [DllImport(dllName)] public extern unsafe static int PL_get_mpq(term_t* t, mpq_t* mpq);
        [DllImport(dllName)] public extern unsafe static int PL_unify_mpz(term_t* t, mpz_t* mpz);
        [DllImport(dllName)] public extern unsafe static int PL_unify_mpq(term_t* t, mpq_t* mpq);

        /*******************************
        *	  FILENAME SUPPORT	*
        *******************************/

        public const int PL_FILE_ABSOLUTE = 0x01; /* return absolute path */
        public const int PL_FILE_OSPATH = 0x02; /* return path in OS notation */
        public const int PL_FILE_SEARCH = 0x04; /* use file_search_path */
        public const int PL_FILE_EXIST = 0x08; /* demand file to exist */
        public const int PL_FILE_READ = 0x10; /* demand read-access */
        public const int PL_FILE_WRITE = 0x20; /* demand write-access */
        public const int PL_FILE_EXECUTE = 0x40; /* demand execute-access */
        public const int PL_FILE_NOERRORS = 0x80; /* do not raise exceptions */

        [DllImport(dllName)] public extern unsafe static int PL_get_file_name(term_t* n, char** name, int flags);
        [DllImport(dllName)] public extern unsafe static int PL_get_file_nameW(term_t* n, short** name, int flags);
        [DllImport(dllName)] public extern unsafe static void PL_changed_cwd(); /* foreign code changed CWD */
        [DllImport(dllName)] public extern unsafe static char* PL_cwd(char* buf, UIntPtr buflen);


        /*******************************
        *    QUINTUS/SICSTUS WRAPPER	*
        *******************************/

        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_char(term_t* p, char* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_uchar(term_t* p, byte* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_short(term_t* p, short* s);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_ushort(term_t* p, ushort* s);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_int(term_t* p, int* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_uint(term_t* p, uint* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_long(term_t* p, long* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_ulong(term_t* p, ulong* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_int64(term_t* p, Int64* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_uint64(term_t* p, UInt64* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_size_t(term_t* p, UIntPtr* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_float(term_t* p, double* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_single(term_t* p, float* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_string(term_t* p, char** c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_codes(term_t* p, char** c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_atom(term_t* p, atom_t* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_i_address(term_t* p, void* c);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_o_int64(Int64 c, term_t* p);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_o_float(double c, term_t* p);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_o_single(float c, term_t* p);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_o_string(char* c, term_t* p);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_o_codes(char* c, term_t* p);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_o_atom(atom_t* c, term_t* p);
        [DllImport(dllName)] public extern unsafe static int PL_cvt_o_address(void* address, term_t* p);
        [DllImport(dllName)] public extern unsafe static term_t* PL_new_nil_ref();

        /* set/get encoding for PL_cvt_*_string() functions.  The default
           is UTF-8 (REP_UTF8)
        */

        [DllImport(dllName)] public extern unsafe static int PL_cvt_encoding();
        [DllImport(dllName)] public extern unsafe static int PL_cvt_set_encoding(int enc);
        [DllImport(dllName)] public extern unsafe static void SP_set_state(int state);
        [DllImport(dllName)] public extern unsafe static int SP_get_state();


        /*******************************
        *	     COMPARE		*
        *******************************/

        [DllImport(dllName)] public extern unsafe static int PL_compare(term_t* t1, term_t* t2);
        [DllImport(dllName)] public extern unsafe static int PL_same_compound(term_t* t1, term_t* t2);

        /*******************************
        *	     MESSAGES		*
        *******************************/

        [DllImport(dllName)] public extern unsafe static int PL_warning(char* fmt, __arglist);
        [DllImport(dllName)] public extern unsafe static void PL_fatal_error(char* fmt, __arglist);

        /*******************************
        *      RECORDED DATABASE	*
        *******************************/

        [DllImport(dllName)] public extern unsafe static record_t* PL_record(term_t* term);
        [DllImport(dllName)] public extern unsafe static int PL_recorded(record_t* record, term_t* term);
        [DllImport(dllName)] public extern unsafe static void PL_erase(record_t* record);
        [DllImport(dllName)] public extern unsafe static record_t* PL_duplicate_record(record_t* r);

        [DllImport(dllName)] public extern unsafe static char* PL_record_external(term_t* t, UIntPtr* size);
        [DllImport(dllName)] public extern unsafe static int PL_recorded_external(char* rec, term_t* term);
        [DllImport(dllName)] public extern unsafe static int PL_erase_external(char* rec);

        /*******************************
        *	   PROLOG FLAGS		*
        *******************************/

        [DllImport(dllName)] public extern unsafe static int PL_set_prolog_flag(char* name, int type, __arglist);


        /*******************************
        *	INTERNAL FUNCTIONS	*
        *******************************/

        [DllImport(dllName)] public extern unsafe static PL_atomic_t* _PL_get_atomic(term_t* t);
        [DllImport(dllName)] public extern unsafe static void _PL_put_atomic(term_t* t, PL_atomic_t* a);
        [DllImport(dllName)] public extern unsafe static int _PL_unify_atomic(term_t* t, PL_atomic_t* a);
        [DllImport(dllName)] public extern unsafe static void _PL_get_arg_sz(UIntPtr index, term_t* t, term_t* a);
        [DllImport(dllName)] public extern unsafe static void _PL_get_arg(int index, term_t* t, term_t* a);


        /*******************************
        *	    CHAR BUFFERS	*
        *******************************/

        public const int CVT_ATOM = 0x0001;
        public const int CVT_STRING = 0x0002;
        public const int CVT_LIST = 0x0004;
        public const int CVT_INTEGER = 0x0008;
        public const int CVT_FLOAT = 0x0010;
        public const int CVT_VARIABLE = 0x0020;
        public const int CVT_NUMBER = (CVT_INTEGER | CVT_FLOAT);
        public const int CVT_ATOMIC = (CVT_NUMBER | CVT_ATOM | CVT_STRING);
        public const int CVT_WRITE = 0x0040;
        public const int CVT_WRITE_CANONICAL = 0x0080;
        public const int CVT_WRITEQ = 0x00C0;
        public const int CVT_ALL = (CVT_ATOMIC | CVT_LIST);
        public const int CVT_MASK = 0x00ff;

        public const int BUF_DISCARDABLE = 0x0000;
        public const int BUF_RING = 0x0100;
        public const int BUF_MALLOC = 0x0200;
        public const int BUF_ALLOW_STACK = 0x0400; /* allow pointer into (global) stack */

        public const int CVT_EXCEPTION = 0x10000; /* throw exception on error */
        public const int CVT_VARNOFAIL = 0x20000; /* return 2 if argument is unbound */

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        Output   representation   for   PL_get_chars()     and    friends.   The
        prepresentation type REP_FN is for   PL_get_file_name()  and friends. On
        Windows we use UTF-8 which is translated   by the `XOS' layer to Windows
        UNICODE file functions.
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

        public const int REP_ISO_LATIN_1 = 0x0000; /* output representation */
        public const int REP_UTF8 = 0x1000;
        public const int REP_MB = 0x2000;
        public const int REP_FN = REP_UTF8;

        public const int PL_DIFF_LIST = 0x20000; /* PL_unify_chars() */

        /*******************************
        *	  STREAM SUPPORT	*
        *******************************/

        /* Make IOSTREAM known to Prolog */
        [DllImport(dllName)] public extern unsafe static int PL_unify_stream(term_t* t, IOSTREAM* s);
        [DllImport(dllName)] public extern unsafe static int PL_get_stream_handle(term_t* t, IOSTREAM** s);
        [DllImport(dllName)] public extern unsafe static int PL_get_stream(term_t* t, IOSTREAM** s, int flags);
        [DllImport(dllName)] public extern unsafe static IOSTREAM* PL_acquire_stream(IOSTREAM* s);
        [DllImport(dllName)] public extern unsafe static int PL_release_stream(IOSTREAM* s);
        [DllImport(dllName)] public extern unsafe static int PL_release_stream_noerror(IOSTREAM* s);
        [DllImport(dllName)] public extern unsafe static IOSTREAM* PL_open_resource(module_t* m, char* name, char* rc_class, char* mode);

        [DllImport(dllName)] public extern unsafe static IOSTREAM** _PL_streams();    /* base of streams */

        public unsafe IOSTREAM* Suser_input() { return _PL_streams()[0]; }
        public unsafe IOSTREAM* Suser_output() { return _PL_streams()[1]; }
        public unsafe IOSTREAM* Suser_error() { return _PL_streams()[2]; }
        public unsafe IOSTREAM* Scurrent_input() { return _PL_streams()[3]; }
        public unsafe IOSTREAM* Scurrent_output() { return _PL_streams()[4]; }

        public const int PL_WRT_QUOTED = 0x01; /* quote atoms */
        public const int PL_WRT_IGNOREOPS = 0x02; /* ignore list/operators */
        public const int PL_WRT_NUMBERVARS = 0x04; /* print $VAR(N) as a variable */
        public const int PL_WRT_PORTRAY = 0x08; /* call portray */
        public const int PL_WRT_CHARESCAPES = 0x10; /* Output ISO escape sequences */
        public const int PL_WRT_BACKQUOTED_STRING = 0x20; /* Write strings as `...` */
                                                          /* Write attributed variables */
        public const int PL_WRT_ATTVAR_IGNORE = 0x040; /* Default: just write the var */
        public const int PL_WRT_ATTVAR_DOTS = 0x080;/* Write as Var{...} */
        public const int PL_WRT_ATTVAR_WRITE = 0x100; /* Write as Var{Attributes} */
        public const int PL_WRT_ATTVAR_PORTRAY = 0x200; /* Use Module:portray_attrs/2 */
        public const int PL_WRT_ATTVAR_MASK = (PL_WRT_ATTVAR_IGNORE | PL_WRT_ATTVAR_DOTS | PL_WRT_ATTVAR_WRITE | PL_WRT_ATTVAR_PORTRAY);
        public const int PL_WRT_BLOB_PORTRAY = 0x400; /* Use portray to emit non-text blobs */
        public const int PL_WRT_NO_CYCLES = 0x800; /* Never emit @(Template,Subst) */
        public const int PL_WRT_NEWLINE = 0x2000; /* Add a newline */
        public const int PL_WRT_VARNAMES = 0x4000; /* Internal: variable_names(List)  */
        public const int PL_WRT_BACKQUOTE_IS_SYMBOL = 0x8000; /* ` is a symbol char */
        public const int PL_WRT_DOTLISTS = 0x10000; /* Write lists as .(A,B) */
        public const int PL_WRT_BRACETERMS = 0x20000; /* Write {A} as {}(A) */
        public const int PL_WRT_NODICT = 0x40000; /* Do not write dicts in pretty syntax */
        public const int PL_WRT_NODOTINATOM = 0x80000; /* never write a.b unquoted */

        [DllImport(dllName)] public extern unsafe static int PL_write_term(IOSTREAM* s, term_t* term, int precedence, int flags);

        /* PL_ttymode() results */
        public const int PL_NOTTY = 0; /* -tty in effect */
        public const int PL_RAWTTY = 1; /* get_single_char/1 */
        public const int PL_COOKEDTTY = 2; /* normal input */

        [DllImport(dllName)] public extern unsafe static int PL_ttymode(IOSTREAM* s);

        [DllImport(dllName)] public extern unsafe static int PL_put_term_from_chars(term_t* t, int flags, UIntPtr len, char* s);
        [DllImport(dllName)] public extern unsafe static int PL_chars_to_term(char* chars, term_t* term);
        [DllImport(dllName)] public extern unsafe static int PL_wchars_to_term(short* chars, term_t* term);


        /*******************************
        *	    EMBEDDING		*
        *******************************/

        [DllImport(dllName)] public extern unsafe static int PL_initialise(int argc, char** argv);
        [DllImport(dllName)] public extern unsafe static int PL_is_initialised(int* argc, char*** argv);
        [DllImport(dllName)] public extern unsafe static int PL_set_resource_db_mem(byte* data, UIntPtr size);
        [DllImport(dllName)] public extern unsafe static int PL_toplevel();
        [DllImport(dllName)] public extern unsafe static int PL_cleanup(int status);
        [DllImport(dllName)] public extern unsafe static void PL_cleanup_fork();
        [DllImport(dllName)] public extern unsafe static int PL_halt(int status);

        /*******************************
        *	  DYNAMIC LINKING	*
        *******************************/

        [DllImport(dllName)] public extern unsafe static void* PL_dlopen(char* file, int flags);
        [DllImport(dllName)] public extern unsafe static char* PL_dlerror();
        [DllImport(dllName)] public extern unsafe static void* PL_dlsym(void* handle, char* symbol);
        [DllImport(dllName)] public extern unsafe static int PL_dlclose(void* handle);


        /*******************************
        *      INPUT/PROMPT/ETC	*
        *******************************/

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        NOTE: the functions in this section are   not  documented, as as yet not
        adviced for public usage.  They  are   intended  to  provide an abstract
        interface for the GNU readline  interface   as  defined  in the readline
        package.
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
        /* PL_dispatch() modes */
        public const int PL_DISPATCH_NOWAIT = 0; /* Dispatch only once */
        public const int PL_DISPATCH_WAIT = 1; /* Dispatch till input available */
        public const int PL_DISPATCH_INSTALLED = 2; /* dispatch function installed? */

        [DllImport(dllName)] public extern unsafe static int PL_dispatch(int fd, int wait);
        [DllImport(dllName)] public extern unsafe static void PL_add_to_protocol(char* buf, UIntPtr count);
        [DllImport(dllName)] public extern unsafe static char* PL_prompt_string(int fd);
        [DllImport(dllName)] public extern unsafe static void PL_write_prompt(int dowrite);
        [DllImport(dllName)] public extern unsafe static void PL_prompt_next(int fd);
        [DllImport(dllName)] public extern unsafe static char* PL_atom_generator(char* prefix, int state);
        [DllImport(dllName)] public extern unsafe static short* PL_atom_generator_w(short* pref, short* buffer, UIntPtr buflen, int state);


        /*******************************
        *	MEMORY ALLOCATION	*
        *******************************/

        [DllImport(dllName)] public extern unsafe static void* PL_malloc(UIntPtr size);
        [DllImport(dllName)] public extern unsafe static void* PL_malloc_atomic(UIntPtr size);
        [DllImport(dllName)] public extern unsafe static void* PL_malloc_uncollectable(UIntPtr size);
        [DllImport(dllName)] public extern unsafe static void* PL_malloc_atomic_uncollectable(UIntPtr size);
        [DllImport(dllName)] public extern unsafe static void* PL_realloc(void* mem, UIntPtr size);
        [DllImport(dllName)] public extern unsafe static void* PL_malloc_unmanaged(UIntPtr size);
        [DllImport(dllName)] public extern unsafe static void* PL_malloc_atomic_unmanaged(UIntPtr size);
        [DllImport(dllName)] public extern unsafe static void PL_free(void* mem);
        [DllImport(dllName)] public extern unsafe static int PL_linger(void* mem);


        /********************************
        *             HOOKS		*
        ********************************/

        public const int PL_DISPATCH_INPUT = 0; /* There is input available */
        public const int PL_DISPATCH_TIMEOUT = 1; /* Dispatch timeout */

        public delegate int PL_dispatch_hook_t(int fd);
        public delegate void PL_abort_hook_t();
        public unsafe delegate void PL_initialise_hook_t(int argc, char** argv);
        public delegate int PL_agc_hook_t(atom_t a);

        [DllImport(dllName)] public extern unsafe static PL_dispatch_hook_t PL_dispatch_hook(PL_dispatch_hook_t a);
        [DllImport(dllName)] public extern unsafe static void PL_abort_hook(PL_abort_hook_t a);
        [DllImport(dllName)] public extern unsafe static void PL_initialise_hook(PL_initialise_hook_t a);
        [DllImport(dllName)] public extern unsafe static int PL_abort_unhook(PL_abort_hook_t a);
        [DllImport(dllName)] public extern unsafe static PL_agc_hook_t PL_agc_hook(PL_agc_hook_t a);


        /********************************
        *            SIGNALS            *
        *********************************/

        /* PL_signal() masks (deprecated) */
        public const int PL_SIGSYNC = 0x00010000; /* call handler synchronously */
        public const int PL_SIGNOFRAME = 0x00020000;    /* Do not create a Prolog frame */

        public const int PLSIG_THROW = 0x0002; /* throw signal(num, name) */
        public const int PLSIG_SYNC = 0x0004; /* call synchronously */
        public const int PLSIG_NOFRAME = 0x0008; /* Do not create a Prolog frame */



        public struct sa_cfunction_t { };

        [StructLayout(LayoutKind.Sequential)]
        public unsafe struct pl_sigaction_t
        {
            sa_cfunction_t* sa_cfunction;   /* traditional C function */
            predicate_t* sa_predicate;     /* call a predicate */
            int sa_flags;           /* additional flags */
        }

        public struct PL_signal_t { };
        public struct func_t { };
        [DllImport(dllName)] public extern unsafe static PL_signal_t* PL_signal(int sig, func_t* func);
        [DllImport(dllName)] public extern unsafe static int PL_sigaction(int sig, pl_sigaction_t* act, pl_sigaction_t* old);
        [DllImport(dllName)] public extern unsafe static void PL_interrupt(int sig);
        [DllImport(dllName)] public extern unsafe static int PL_raise(int sig);
        [DllImport(dllName)] public extern unsafe static int PL_handle_signals();
        [DllImport(dllName)] public extern unsafe static int PL_get_signum_ex(term_t* sig, int* n);


        /********************************
        *      PROLOG ACTION/QUERY      *
        *********************************/

        public const int PL_ACTION_TRACE = 1; /* switch to trace mode */
        public const int PL_ACTION_DEBUG = 2; /* switch to debug mode */
        public const int PL_ACTION_BACKTRACE = 3; /* show a backtrace (stack dump) */
        public const int PL_ACTION_BREAK = 4; /* create a break environment */
        public const int PL_ACTION_HALT = 5; /* halt Prolog execution */
        public const int PL_ACTION_ABORT = 6; /* generate a Prolog abort */
                                              /* 7: Obsolete PL_ACTION_SYMBOLFILE */
        public const int PL_ACTION_WRITE = 8; /* write via Prolog i/o buffer */
        public const int PL_ACTION_FLUSH = 9; /* Flush Prolog i/o buffer */
        public const int PL_ACTION_GUIAPP = 10; /* Win32: set when this is a gui */
        public const int PL_ACTION_ATTACH_CONSOLE = 11; /* MT: Attach a console */
        public const int PL_GMP_SET_ALLOC_FUNCTIONS = 12; /* GMP: do not change allocation functions */
        public const int PL_ACTION_TRADITIONAL = 13; /* Set --traditional */

        public const int PL_BT_SAFE = 0x1; /* Do not try to print goals */
        public const int PL_BT_USER = 0x2; /* Only show user-goals */

        public struct f_t { };

        [DllImport(dllName)] public extern unsafe static int PL_action(int a, __arglist);   /* perform some action */
        [DllImport(dllName)] public extern unsafe static void PL_on_halt(f_t f, void* b);
        [DllImport(dllName)] public extern unsafe static void PL_exit_hook(f_t f, void* b);
        [DllImport(dllName)] public extern unsafe static void PL_backtrace(int depth, int flags);
        [DllImport(dllName)] public extern unsafe static char* PL_backtrace_string(int depth, int flags);
        [DllImport(dllName)] public extern unsafe static int PL_check_data(term_t* data);
        [DllImport(dllName)] public extern unsafe static int PL_check_stacks();
        [DllImport(dllName)] public extern unsafe static int PL_current_prolog_flag(atom_t* name, int type, void* ptr);


        /********************************
        *         QUERY PROLOG          *
        *********************************/

        public const int PL_QUERY_ARGC = 1; /* return main() argc */
        public const int PL_QUERY_ARGV = 2; /* return main() argv */
                                            /* 3: Obsolete PL_QUERY_SYMBOLFILE */
                                            /* 4: Obsolete PL_QUERY_ORGSYMBOLFILE*/
        public const int PL_QUERY_GETC = 5; /* Read character from terminal */
        public const int PL_QUERY_MAX_INTEGER = 6; /* largest integer */
        public const int PL_QUERY_MIN_INTEGER = 7; /* smallest integer */
        public const int PL_QUERY_MAX_TAGGED_INT = 8; /* largest tagged integer */
        public const int PL_QUERY_MIN_TAGGED_INT = 9; /* smallest tagged integer */
        public const int PL_QUERY_VERSION = 10; /* 207006 = 2.7.6 */
        public const int PL_QUERY_MAX_THREADS = 11; /* maximum thread count */
        public const int PL_QUERY_ENCODING = 12; /* I/O encoding */
        public const int PL_QUERY_USER_CPU = 13; /* User CPU in milliseconds */
        public const int PL_QUERY_HALTING = 14; /* If TRUE, we are in PL_cleanup() */

        [DllImport(dllName)] public extern unsafe static IntPtr PL_query(int a);  /* get information from Prolog */


        /*******************************
        *	  PROLOG THREADS	*
        *******************************/

        public const int PL_THREAD_NO_DEBUG = 0x01; /* Start thread in nodebug mode */
        public const int PL_THREAD_NOT_DETACHED = 0x02; /* Allow Prolog to join */

        enum rc_cancel
        {
            PL_THREAD_CANCEL_FAILED = FALSE,    /* failed to cancel; try abort */
            PL_THREAD_CANCEL_JOINED = TRUE, /* cancelled and joined */
            PL_THREAD_CANCEL_MUST_JOIN      /* cancelled, must join */
        }

        public struct cancel_t { };

        [StructLayout(LayoutKind.Sequential)]
        public unsafe struct PL_thread_attr_t
        {
            public UIntPtr stack_limit; /* Total stack limit (bytes) */
            public UIntPtr table_space; /* Total tabling space limit (bytes) */
            public char* alias; /* alias name */
            public cancel_t* cancel; /* cancel function */
            public IntPtr flags; /* PL_THREAD_* flags */
            public UIntPtr max_queue_size; /* Max size of associated queue */
        };

        public struct function_t { };
        [DllImport(dllName)] public extern unsafe static int PL_thread_self();  /* Prolog thread id (-1 if none) */
        [DllImport(dllName)] public extern unsafe static int PL_unify_thread_id(term_t t, int i);
        [DllImport(dllName)] public extern unsafe static int PL_get_thread_id_ex(term_t t, int* idp);
        [DllImport(dllName)] public extern unsafe static int PL_get_thread_alias(int tid, atom_t* alias);   /* Locks alias */
        [DllImport(dllName)] public extern unsafe static int PL_thread_attach_engine(PL_thread_attr_t* attr);
        [DllImport(dllName)] public extern unsafe static int PL_thread_destroy_engine();
        [DllImport(dllName)] public extern unsafe static int PL_thread_at_exit(function_t* function, void* closure, int global);
        [DllImport(dllName)] public extern unsafe static int PL_thread_raise(int tid, int sig);

        [DllImport(dllName)] public extern unsafe static int PL_w32thread_raise(UInt32 dwTid, int sig);
        [DllImport(dllName)] public extern unsafe static int PL_wait_for_console_input(void* handle);
        [DllImport(dllName)] public extern unsafe static int PL_w32_wrap_ansi_console();
        [DllImport(dllName)] public extern unsafe static char* PL_w32_running_under_wine();


        /*******************************
        *	 ENGINES (MT-ONLY)	*
        *******************************/

        public unsafe static readonly PL_engine_t *PL_ENGINE_MAIN = (PL_engine_t *) 0x1;
        public unsafe static readonly PL_engine_t *PL_ENGINE_CURRENT = (PL_engine_t*) 0x2;

        public const int PL_ENGINE_SET = 0; /* engine set successfully */
        public const int PL_ENGINE_INVAL = 2; /* engine doesn't exist */
        public const int PL_ENGINE_INUSE = 3; /* engine is in use */

        [DllImport(dllName)] public extern unsafe static PL_engine_t* PL_create_engine(PL_thread_attr_t* attributes);
        [DllImport(dllName)] public extern unsafe static int PL_set_engine(PL_engine_t* engine, PL_engine_t** old);
        [DllImport(dllName)] public extern unsafe static int PL_destroy_engine(PL_engine_t* engine);


        /*******************************
        *	     PROFILER		*
        *******************************/

        public struct unify_t { };
        public struct get_t { };
        public struct activate_t { };

        [StructLayout(LayoutKind.Sequential)]
        public unsafe struct PL_prof_type_t
        {
            unify_t* unify; /* implementation --> Prolog */
            get_t* get; /* Prolog --> implementation */
            activate_t* activate;       /* (de)activate */
            IntPtr magic;                   /* PROFTYPE_MAGIC */
        };

        [DllImport(dllName)] public extern unsafe static int PL_register_profile_type(PL_prof_type_t* type);
        [DllImport(dllName)] public extern unsafe static void* PL_prof_call(void* handle, PL_prof_type_t* type);
        [DllImport(dllName)] public extern unsafe static void PL_prof_exit(void* node);



        /*******************************
        *       FAST XPCE SUPPORT	*
        *******************************/

        [StructLayout(LayoutKind.Sequential)]
        public struct xpceref_t
        {
            public int type;             /* PL_INTEGER or PL_ATOM */
            [StructLayout(LayoutKind.Explicit)]
            public unsafe struct value_t
            {
                [FieldOffset(0)] public UIntPtr i;            /* integer reference value */
                [FieldOffset(0)] public atom_t* a;         /* atom reference value */
            }
            public value_t value;
        };

        [DllImport(dllName)] public extern unsafe static int _PL_get_xpce_reference(term_t* t, xpceref_t* _ref);
        [DllImport(dllName)] public extern unsafe static int _PL_unify_xpce_reference(term_t* t, xpceref_t* _ref);
        [DllImport(dllName)] public extern unsafe static int _PL_put_xpce_reference_i(term_t* t, UIntPtr r);
        [DllImport(dllName)] public extern unsafe static int _PL_put_xpce_reference_a(term_t* t, atom_t* name);



        /*******************************
        *         TRACE SUPPORT	*
        *******************************/

        struct QueryFrame { };
        struct LocalFrame { };
        struct Code { };

        [StructLayout(LayoutKind.Sequential)]
        public unsafe struct pl_context_t
        {
            PL_engine_t* ld;         /* Engine */
            QueryFrame qf;          /* Current query */
            LocalFrame fr;          /* Current localframe */
            Code pc;            /* Code pointer */
        }


        [DllImport(dllName)] public extern unsafe static int PL_get_context(pl_context_t* c, int thead_id);
        [DllImport(dllName)] public extern unsafe static int PL_step_context(pl_context_t* c);
        [DllImport(dllName)] public extern unsafe static int PL_describe_context(pl_context_t* c, char* buf, UIntPtr len);



    }
}