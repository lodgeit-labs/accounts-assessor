using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

// This program is a demonstration of how a C# console application can run SWI Prolog queries
// using the SWI-Prolog Foreign Language Interface. This program works as follows: SWI-Prolog
// provides a DLL library called libswipl.dll that can load Prolog scripts and execute queries
// on them. The PL class in this document simply declares the functions in the DLL file to the
// rest of this C# program. The Program class at the bottom simply utilizes the DLL files's
// functions to execute a Prolog query.

// Please alter line 38, the location of the Prolog kernel DLL, and line 525, the location of
// main.pl from the labs-accounts-assessor repository to reflect your system's specific setup.

// To run this, open up Microsoft Visual Studio. Go File > New > Project . Under Visual C#
// select Console App (.NET Framework). Press OK. There should be one C# file in this project
// called Program.cs . Replace that file with this document. Now go Project > Properties... >
// Build > General . Set Platform Target to match the target architecture of libswipl.dll, the
// Prolog Kernel DLL. Now go Debug > Start Debugging. The expected output is "Result of
// absolute_day(date(2017, 7, 3), B) is 736513".

// Attention needs to be paid to memory management due to the fact that the functions in
// libswipl.dll are unmanaged. Something that could cause a crash is passing a C# object to
// libswipl.dll, the garbage collector disposing the said C# object, and then libswipl.dll
// trying to do something with the now non-existant C# object.

namespace PrologDemo
{
    // See http://www.swi-prolog.org/pldoc/man?section=foreigninclude for extensive documentation
    // This class is essentially a direct translation of the official swipl\include\SWI-Prolog.h
    // I have only tested it on 64-bit Windows but I believe that it should also work on 32-bit
    class PL
    {
        // Location of the Prolog Kernel that comes with every SWI-Prolog distribution
        private const string dllName = "C:\\Program Files\\swipl\\bin\\libswipl.dll";

        // TERM-TYPE CONSTANTS

        /* PL_unify_term() arguments */
        public const int VARIABLE = 1; /* nothing */
        public const int ATOM = 2; /* const char * */
        public const int INTEGER = 3; /* int */
        public const int FLOAT = 4; /* double */
        public const int STRING = 5; /* const char * */
        public const int TERM = 6;

        public const int NIL = 7; /* The constant [] */
        public const int BLOB = 8; /* non-atom blob */
        public const int LIST_PAIR = 9; /* [_|_] term */

        /* PL_unify_term() */
        public const int FUNCTOR = 10; /* functor_t, arg ... */
        public const int LIST = 11; /* length, arg ... */
        public const int CHARS = 12; /* const char * */
        public const int POINTER = 13; /* void * */
        /* PlArg::PlArg(text, type) */
        public const int CODE_LIST = 14; /* [ascii...] */
        public const int CHAR_LIST = 15; /* [h,e,l,l,o] */
        public const int BOOL = 16; /* PL_set_prolog_flag() */
        public const int FUNCTOR_CHARS = 17; /* PL_unify_term() */
        public const int _PREDICATE_INDICATOR = 18; /* predicate_t (Procedure) */
        public const int SHORT = 19; /* short */
        public const int INT = 20; /* int */
        public const int LONG = 21; /* long */
        public const int DOUBLE = 22; /* double */
        public const int NCHARS = 23; /* size_t, const char * */
        public const int UTF8_CHARS = 24; /* const char * */
        public const int UTF8_STRING = 25; /* const char * */
        public const int INT64 = 26; /* int64_t */
        public const int NUTF8_CHARS = 27; /* size_t, const char * */
        public const int NUTF8_CODES = 29; /* size_t, const char * */
        public const int NUTF8_STRING = 30; /* size_t, const char * */
        public const int NWCHARS = 31; /* size_t, const wchar_t * */
        public const int NWCODES = 32; /* size_t, const wchar_t * */
        public const int NWSTRING = 33; /* size_t, const wchar_t * */
        public const int MBCHARS = 34; /* const char * */
        public const int MBCODES = 35; /* const char * */
        public const int MBSTRING = 36; /* const char * */
        public const int INTPTR = 37; /* intptr_t */
        public const int CHAR = 38; /* int */
        public const int CODE = 39; /* int */
        public const int BYTE = 40; /* int */
        /* PL_skip_list() */
        public const int PARTIAL_LIST = 41; /* a partial list */
        public const int CYCLIC_TERM = 42; /* a cyclic list/term */
        public const int NOT_A_LIST = 43; /* Object is not a list */
        /* dicts */
        public const int DICT = 44;

        // NON-DETERMINISTIC CALL/RETURN
        public const int FIRST_CALL = 0;
        public const int CUTTED = 1; /* deprecated */
        public const int PRUNED = 1;
        public const int REDO = 2;
        
        [DllImport(dllName)] public extern static int PL_foreign_control(IntPtr control_t);
        [DllImport(dllName)] public extern static IntPtr PL_foreign_context(IntPtr control_t);
        [DllImport(dllName)] public extern static IntPtr PL_foreign_context_address(IntPtr control_t);
        [DllImport(dllName)] public extern static IntPtr PL_foreign_context_predicate(IntPtr control_t);

        // REGISTERING FOREIGNS

        public struct PL_extension
        {
            string predicate_name;     /* Name of the predicate */
            short arity;            /* Arity of the predicate */
            IntPtr function;     /* Implementing functions */
            short flags;            /* Or of PL_FA_... */
        }

        public const int FA_NOTRACE = 0x01; /* foreign cannot be traced */
        public const int FA_TRANSPARENT = 0x02; /* foreign is module transparent */
        public const int FA_NONDETERMINISTIC = 0x04; /* foreign is non-deterministic */
        public const int FA_VARARGS = 0x08; /* call using t0, ac, ctx */
        public const int FA_CREF = 0x10; /* Internal: has clause-reference */
        public const int FA_ISO = 0x20; /* Internal: ISO core predicate */
        public const int FA_META = 0x40; /* Additional meta-argument spec */

        [DllImport(dllName)] public extern static void PL_register_extensions(PL_extension[] e);
        [DllImport(dllName)] public extern static void PL_register_extensions_in_module(string module, PL_extension[] e);
        [DllImport(dllName)] public extern static int PL_register_foreign(string name, int arity, IntPtr func, int flags, __arglist);
        [DllImport(dllName)] public extern static int PL_register_foreign_in_module(string module, string name, int arity, IntPtr func, int flags, __arglist);
        [DllImport(dllName)] public extern static void PL_load_extensions(PL_extension[] e);

        // LICENSE

        [DllImport(dllName)] public extern static void PL_license(string license, string module);

        //MODULES

        [DllImport(dllName)] public extern static IntPtr PL_context();
        [DllImport(dllName)] public extern static IntPtr PL_module_name(IntPtr module);
        [DllImport(dllName)] public extern static IntPtr PL_new_module(IntPtr name);
        [DllImport(dllName)] public extern static int PL_strip_module(IntPtr PL_in, ref IntPtr m, IntPtr PL_out);

        // CONSTANTS

        [DllImport(dllName)] public extern static IntPtr[] _PL_atoms(); /* base of reserved (meta-)atoms */
        IntPtr ATOM_nil() { return _PL_atoms()[0]; /* `[]` */ }
        IntPtr ATOM_dot() { return _PL_atoms()[1]; /* `.` */ }

        // CALL-BACK

        public const int Q_NORMAL = 0x0002; /* normal usage */
        public const int Q_NODEBUG = 0x0004; /* use this one */
        public const int Q_CATCH_EXCEPTION = 0x0008; /* handle exceptions in C */
        public const int Q_PASS_EXCEPTION = 0x0010; /* pass to parent environment */
        public const int Q_ALLOW_YIELD = 0x0020; /* Support I_YIELD */
        public const int Q_EXT_STATUS = 0x0040; /* Return extended status */

        /* Q_EXT_STATUS return codes */
        public const int S_EXCEPTION = -1; /* Query raised exception */
        public const int S_FALSE = 0; /* Query failed */
        public const int S_TRUE = 1; /* Query succeeded with choicepoint */
        public const int S_LAST = 2; /* Query succeeded without CP */


        /* Foreign context frames */
        [DllImport(dllName)] public extern static IntPtr PL_open_foreign_frame();
        [DllImport(dllName)] public extern static void PL_rewind_foreign_frame(IntPtr cid);
        [DllImport(dllName)] public extern static void PL_close_foreign_frame(IntPtr cid);
        [DllImport(dllName)] public extern static void PL_discard_foreign_frame(IntPtr cid);

        /* Finding predicates */
        [DllImport(dllName)] public extern static IntPtr PL_pred(IntPtr f, IntPtr m);
        [DllImport(dllName)] public extern static IntPtr PL_predicate(string name, int arity, string module);
        [DllImport(dllName)] public extern static int PL_predicate_info(IntPtr pred, out IntPtr name, out UIntPtr arity, out IntPtr module);

        /* Call-back */
        [DllImport(dllName)] public extern static IntPtr PL_open_query(IntPtr m, int flags, IntPtr pred, IntPtr t0);
        [DllImport(dllName)] public extern static int PL_next_solution(IntPtr qid);
        [DllImport(dllName)] public extern static int PL_close_query(IntPtr qid);
        [DllImport(dllName)] public extern static int PL_cut_query(IntPtr qid);
        [DllImport(dllName)] public extern static IntPtr PL_current_query();

        /* Simplified (but less flexible) call-back */
        [DllImport(dllName)] public extern static int PL_call(IntPtr t, IntPtr m);
        [DllImport(dllName)] public extern static int PL_call_predicate(IntPtr m, int debug, IntPtr pred, IntPtr t0);
        /* Handling exceptions */
        [DllImport(dllName)] public extern static IntPtr PL_exception(IntPtr qid);
        [DllImport(dllName)] public extern static int PL_raise_exception(IntPtr exception);
        [DllImport(dllName)] public extern static int PL_throw(IntPtr exception);
        [DllImport(dllName)] public extern static void PL_clear_exception();
        /* Engine-based coroutining */
        [DllImport(dllName)] public extern static IntPtr PL_yielded(IntPtr qid);

        // TERM-REFERENCES	*

        /* Creating and destroying term-refs */
        [DllImport(dllName)] public extern static IntPtr PL_new_term_refs(int n);
        [DllImport(dllName)] public extern static IntPtr PL_new_term_ref();
        [DllImport(dllName)] public extern static IntPtr PL_copy_term_ref(IntPtr from);
        [DllImport(dllName)] public extern static void PL_reset_term_refs(IntPtr r);

        /* Constants */
        [DllImport(dllName)] public extern static IntPtr PL_new_atom(string s);
        [DllImport(dllName)] public extern static IntPtr PL_new_atom_nchars(UIntPtr len, string s);
        [DllImport(dllName)] public extern static IntPtr PL_new_atom_wchars(UIntPtr len, string s);
        [DllImport(dllName)] public extern static IntPtr PL_new_atom_mbchars(int rep, UIntPtr len, string s);
        [DllImport(dllName)] public extern static string PL_atom_chars(IntPtr a);
        [DllImport(dllName)] public extern static string PL_atom_nchars(IntPtr a, out UIntPtr len);
        [DllImport(dllName)] public extern static string PL_atom_wchars(IntPtr a, out UIntPtr len);
        [DllImport(dllName)] public extern static void PL_register_atom(IntPtr a);
        [DllImport(dllName)] public extern static void PL_unregister_atom(IntPtr a);
        [DllImport(dllName)] public extern static IntPtr PL_new_functor_sz(IntPtr f, UIntPtr a);
        [DllImport(dllName)] public extern static IntPtr PL_new_functor(IntPtr f, int a);
        [DllImport(dllName)] public extern static IntPtr PL_functor_name(IntPtr f);
        [DllImport(dllName)] public extern static int PL_functor_arity(IntPtr f);
        [DllImport(dllName)] public extern static UIntPtr PL_functor_arity_sz(IntPtr f);

        /* Get C-values from Prolog terms */
        [DllImport(dllName)] public extern static int PL_get_atom(IntPtr t, out IntPtr a);
        [DllImport(dllName)] public extern static int PL_get_bool(IntPtr t, out int value);
        [DllImport(dllName)] public extern static int PL_get_atom_chars(IntPtr t, out string a);
        /* get_string() is deprecated */
        [DllImport(dllName)] public extern static int PL_get_string(IntPtr t, out string s, out UIntPtr len);
        [DllImport(dllName)] public extern static int PL_get_chars(IntPtr t, out string s, uint flags);
        [DllImport(dllName)] public extern static int PL_get_list_chars(IntPtr l, out string s, uint flags);
        [DllImport(dllName)] public extern static int PL_get_atom_nchars(IntPtr t, out UIntPtr len, out string a);
        [DllImport(dllName)] public extern static int PL_get_list_nchars(IntPtr l, out UIntPtr len, out string s, uint flags);
        [DllImport(dllName)] public extern static int PL_get_nchars(IntPtr t, out UIntPtr len, out string s, uint flags);
        [DllImport(dllName)] public extern static int PL_get_integer(IntPtr t, out int i);
        [DllImport(dllName)] public extern static int PL_get_long(IntPtr t, out long i);
        [DllImport(dllName)] public extern static int PL_get_intptr(IntPtr t, out IntPtr i);
        [DllImport(dllName)] public extern static int PL_get_pointer(IntPtr t, out IntPtr ptr);
        [DllImport(dllName)] public extern static int PL_get_float(IntPtr t, out double f);
        [DllImport(dllName)] public extern static int PL_get_functor(IntPtr t, out IntPtr f);
        [DllImport(dllName)] public extern static int PL_get_name_arity_sz(IntPtr t, out IntPtr name, out UIntPtr arity);
        [DllImport(dllName)] public extern static int PL_get_compound_name_arity_sz(IntPtr t, out IntPtr name, out UIntPtr arity);
        [DllImport(dllName)] public extern static int PL_get_name_arity(IntPtr t, out IntPtr name, out int arity);
        [DllImport(dllName)] public extern static int PL_get_compound_name_arity(IntPtr t, out IntPtr name, out int arity);
        [DllImport(dllName)] public extern static int PL_get_module(IntPtr t, out IntPtr module);
        [DllImport(dllName)] public extern static int PL_get_arg_sz(UIntPtr index, IntPtr t, IntPtr a);
        [DllImport(dllName)] public extern static int PL_get_arg(int index, IntPtr t, IntPtr a);
        [DllImport(dllName)] public extern static int PL_get_list(IntPtr l, IntPtr h, IntPtr t);
        [DllImport(dllName)] public extern static int PL_get_head(IntPtr l, IntPtr h);
        [DllImport(dllName)] public extern static int PL_get_tail(IntPtr l, IntPtr t);
        [DllImport(dllName)] public extern static int PL_get_nil(IntPtr l);
        [DllImport(dllName)] public extern static int PL_get_term_value(IntPtr t, out IntPtr v);
        [DllImport(dllName)] public extern static string PL_quote(int chr, string data);

        /* Verify types */
        [DllImport(dllName)] public extern static int PL_term_type(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_variable(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_ground(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_atom(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_integer(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_string(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_float(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_rational(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_compound(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_callable(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_functor(IntPtr t, IntPtr f);
        [DllImport(dllName)] public extern static int PL_is_list(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_pair(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_atomic(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_number(IntPtr t);
        [DllImport(dllName)] public extern static int PL_is_acyclic(IntPtr t);

        /* Assign to term-references */
        [DllImport(dllName)] public extern static int PL_put_variable(IntPtr t);
        [DllImport(dllName)] public extern static int PL_put_atom(IntPtr t, IntPtr a);
        [DllImport(dllName)] public extern static int PL_put_bool(IntPtr t, int val);
        [DllImport(dllName)] public extern static int PL_put_atom_chars(IntPtr t, string chars);
        [DllImport(dllName)] public extern static int PL_put_string_chars(IntPtr t, string chars);
        [DllImport(dllName)] public extern static int PL_put_chars(IntPtr t, int flags, UIntPtr len, string chars);
        [DllImport(dllName)] public extern static int PL_put_list_chars(IntPtr t, string chars);
        [DllImport(dllName)] public extern static int PL_put_list_codes(IntPtr t, string chars);
        [DllImport(dllName)] public extern static int PL_put_atom_nchars(IntPtr t, UIntPtr l, string chars);
        [DllImport(dllName)] public extern static int PL_put_string_nchars(IntPtr t, UIntPtr len, string chars);
        [DllImport(dllName)] public extern static int PL_put_list_nchars(IntPtr t, UIntPtr l, string chars);
        [DllImport(dllName)] public extern static int PL_put_list_ncodes(IntPtr t, UIntPtr l, string chars);
        [DllImport(dllName)] public extern static int PL_put_integer(IntPtr t, long i);
        [DllImport(dllName)] public extern static int PL_put_pointer(IntPtr t, IntPtr ptr);
        [DllImport(dllName)] public extern static int PL_put_float(IntPtr t, double f);
        [DllImport(dllName)] public extern static int PL_put_functor(IntPtr t, IntPtr functor);
        [DllImport(dllName)] public extern static int PL_put_list(IntPtr l);
        [DllImport(dllName)] public extern static int PL_put_nil(IntPtr l);
        [DllImport(dllName)] public extern static int PL_put_term(IntPtr t1, IntPtr t2);

        /* construct a functor or list-cell */
        [DllImport(dllName)] public extern static int PL_cons_functor(IntPtr h, IntPtr f, __arglist);
        [DllImport(dllName)] public extern static int PL_cons_functor_v(IntPtr h, IntPtr fd, IntPtr a0);
        [DllImport(dllName)] public extern static int PL_cons_list(IntPtr l, IntPtr h, IntPtr t);

        /* Unify term-references */
        [DllImport(dllName)] public extern static int PL_unify(IntPtr t1, IntPtr t2);
        [DllImport(dllName)] public extern static int PL_unify_atom(IntPtr t, IntPtr a);
        [DllImport(dllName)] public extern static int PL_unify_atom_chars(IntPtr t, string chars);
        [DllImport(dllName)] public extern static int PL_unify_list_chars(IntPtr t, string chars);
        [DllImport(dllName)] public extern static int PL_unify_list_codes(IntPtr t, string chars);
        [DllImport(dllName)] public extern static int PL_unify_string_chars(IntPtr t, string chars);
        [DllImport(dllName)] public extern static int PL_unify_atom_nchars(IntPtr t, UIntPtr l, string s);
        [DllImport(dllName)] public extern static int PL_unify_list_ncodes(IntPtr t, UIntPtr l, string s);
        [DllImport(dllName)] public extern static int PL_unify_list_nchars(IntPtr t, UIntPtr l, string s);
        [DllImport(dllName)] public extern static int PL_unify_string_nchars(IntPtr t, UIntPtr len, string chars);
        [DllImport(dllName)] public extern static int PL_unify_bool(IntPtr t, int n);
        [DllImport(dllName)] public extern static int PL_unify_integer(IntPtr t, IntPtr n);
        [DllImport(dllName)] public extern static int PL_unify_float(IntPtr t, double f);
        [DllImport(dllName)] public extern static int PL_unify_pointer(IntPtr t, IntPtr ptr);
        [DllImport(dllName)] public extern static int PL_unify_functor(IntPtr t, IntPtr f);
        [DllImport(dllName)] public extern static int PL_unify_compound(IntPtr t, IntPtr f);
        [DllImport(dllName)] public extern static int PL_unify_list(IntPtr l, IntPtr h, IntPtr t);
        [DllImport(dllName)] public extern static int PL_unify_nil(IntPtr l);
        [DllImport(dllName)] public extern static int PL_unify_arg_sz(UIntPtr index, IntPtr t, IntPtr a);
        [DllImport(dllName)] public extern static int PL_unify_arg(int index, IntPtr t, IntPtr a);
        [DllImport(dllName)] public extern static int PL_unify_term(IntPtr t, __arglist);
        [DllImport(dllName)] public extern static int PL_unify_chars(IntPtr t, int flags, UIntPtr len, string s);

        // LISTS

        [DllImport(dllName)] public extern static int PL_skip_list(IntPtr list, IntPtr tail, out UIntPtr len);


        // WIDE CHARACTER VERSIONS

        [DllImport(dllName)] public extern static int PL_unify_wchars(IntPtr t, int type, UIntPtr len, string s);
        [DllImport(dllName)] public extern static int PL_unify_wchars_diff(IntPtr t, IntPtr tail, int type, UIntPtr len, string s);
        [DllImport(dllName)] public extern static int PL_get_wchars(IntPtr l, out UIntPtr length, out string s, uint flags);
        [DllImport(dllName)] public extern static UIntPtr PL_utf8_strlen(string s, UIntPtr len);

        // WIDE INTEGERS

        [DllImport(dllName)] public extern static int PL_get_int64(IntPtr t, out Int64 i);
        [DllImport(dllName)] public extern static int PL_unify_int64(IntPtr t, Int64 value);
        [DllImport(dllName)] public extern static int PL_unify_uint64(IntPtr t, UInt64 value);
        [DllImport(dllName)] public extern static int PL_put_int64(IntPtr t, Int64 i);


        // ATTRIBUTED VARIABLES

        [DllImport(dllName)] public extern static int PL_is_attvar(IntPtr t);
        [DllImport(dllName)] public extern static int PL_get_attr(IntPtr v, IntPtr a);


        // ERRORS

        [DllImport(dllName)] public extern static int PL_get_atom_ex(IntPtr t, out IntPtr a);
        [DllImport(dllName)] public extern static int PL_get_integer_ex(IntPtr t, out int i);
        [DllImport(dllName)] public extern static int PL_get_long_ex(IntPtr t, out long i);
        [DllImport(dllName)] public extern static int PL_get_int64_ex(IntPtr t, out Int64 i);
        [DllImport(dllName)] public extern static int PL_get_intptr_ex(IntPtr t, out IntPtr i);
        [DllImport(dllName)] public extern static int PL_get_size_ex(IntPtr t, out UIntPtr i);
        [DllImport(dllName)] public extern static int PL_get_bool_ex(IntPtr t, out int i);
        [DllImport(dllName)] public extern static int PL_get_float_ex(IntPtr t, out double f);
        [DllImport(dllName)] public extern static int PL_get_char_ex(IntPtr t, out int p, int eof);
        [DllImport(dllName)] public extern static int PL_unify_bool_ex(IntPtr t, int val);
        [DllImport(dllName)] public extern static int PL_get_pointer_ex(IntPtr t, out IntPtr addrp);
        [DllImport(dllName)] public extern static int PL_unify_list_ex(IntPtr l, IntPtr h, IntPtr t);
        [DllImport(dllName)] public extern static int PL_unify_nil_ex(IntPtr l);
        [DllImport(dllName)] public extern static int PL_get_list_ex(IntPtr l, IntPtr h, IntPtr t);
        [DllImport(dllName)] public extern static int PL_get_nil_ex(IntPtr l);

        [DllImport(dllName)] public extern static int PL_instantiation_error(IntPtr culprit);
        [DllImport(dllName)] public extern static int PL_uninstantiation_error(IntPtr culprit);
        [DllImport(dllName)] public extern static int PL_representation_error(string resource);
        [DllImport(dllName)] public extern static int PL_type_error(string expected, IntPtr culprit);
        [DllImport(dllName)] public extern static int PL_domain_error(string expected, IntPtr culprit);
        [DllImport(dllName)] public extern static int PL_existence_error(string type, IntPtr culprit);
        [DllImport(dllName)] public extern static int PL_permission_error(string operation, string type, IntPtr culprit);
        [DllImport(dllName)] public extern static int PL_resource_error(string resource);
        [DllImport(dllName)] public extern static int PL_syntax_error(string msg, IntPtr PL_in);

        // BLOBS

        public const uint BLOB_MAGIC_B = 0x75293a00; /* Magic to validate a blob-type */
        public const uint BLOB_VERSION = 1; /* Current version */
        public const uint BLOB_MAGIC = BLOB_MAGIC_B | BLOB_VERSION;

        public const uint BLOB_UNIQUE = 0x01; /* Blob content is unique */
        public const uint BLOB_TEXT = 0x02; /* blob contains text */
        public const uint BLOB_NOCOPY = 0x04; /* do not copy the data */
        public const uint BLOB_WCHAR = 0x08; /* wide character string */

        public struct PL_blob_t
        {
            UIntPtr magic;        /* PL_BLOB_MAGIC */
            UIntPtr flags;        /* PL_BLOB_* */
            string name;     /* name of the type */
            public delegate int PL_blob_t_delegate0(IntPtr a, IntPtr b);
            PL_blob_t_delegate0 release;
            PL_blob_t_delegate0 compare;
            public delegate int PL_blob_t_delegate1(IntPtr s, IntPtr a, int flags);
            PL_blob_t_delegate1 write;
            public delegate void PL_blob_t_delegate2(IntPtr a);
            PL_blob_t_delegate2 acquire;
        }

        [DllImport(dllName)] public extern static int PL_is_blob(IntPtr t, out IntPtr type);
        [DllImport(dllName)] public extern static int PL_unify_blob(IntPtr t, IntPtr blob, UIntPtr len, ref PL_blob_t type);
        [DllImport(dllName)] public extern static int PL_put_blob(IntPtr t, IntPtr blob, UIntPtr len, ref PL_blob_t type);
        [DllImport(dllName)] public extern static int PL_get_blob(IntPtr t, out IntPtr blob, out UIntPtr len, out IntPtr type);
        [DllImport(dllName)] public extern static IntPtr PL_blob_data(IntPtr a, out UIntPtr len, out IntPtr type);

        [DllImport(dllName)] public extern static void PL_register_blob_type(ref PL_blob_t type);
        [DllImport(dllName)] public extern static ref PL_blob_t PL_find_blob_type(string name);
        [DllImport(dllName)] public extern static int PL_unregister_blob_type(ref PL_blob_t type);

        // GMP

        [DllImport(dllName)] public extern static int PL_get_mpz(IntPtr t, IntPtr mpz);
        [DllImport(dllName)] public extern static int PL_get_mpq(IntPtr t, IntPtr mpq);
        [DllImport(dllName)] public extern static int PL_unify_mpz(IntPtr t, IntPtr mpz);
        [DllImport(dllName)] public extern static int PL_unify_mpq(IntPtr t, IntPtr mpq);

        // FILENAME SUPPORT

        public const int FILE_ABSOLUTE = 0x01;	/* return absolute path */
        public const int FILE_OSPATH = 0x02;	/* return path in OS notation */
        public const int FILE_SEARCH = 0x04; /* use file_search_path */
        public const int FILE_EXIST = 0x08; /* demand file to exist */
        public const int FILE_READ = 0x10; /* demand read-access */
        public const int FILE_WRITE = 0x20; /* demand write-access */
        public const int FILE_EXECUTE = 0x40; /* demand execute-access */
        public const int FILE_NOERRORS = 0x80; /* do not raise exceptions */

        [DllImport(dllName)] public extern static int PL_get_file_name(IntPtr n, out string name, int flags);
        [DllImport(dllName)] public extern static int PL_get_file_nameW(IntPtr n, out string name, int flags);
        [DllImport(dllName)] public extern static void PL_changed_cwd(); /* foreign code changed CWD */
        [DllImport(dllName)] public extern static string PL_cwd(StringBuilder buf, UIntPtr buflen);

        // COMPARE

        [DllImport(dllName)] public extern static int PL_compare(IntPtr t1, IntPtr t2);
        [DllImport(dllName)] public extern static int PL_same_compound(IntPtr t1, IntPtr t2);

        // MESSAGES

        [DllImport(dllName)] public extern static int PL_warning(string fmt, __arglist);
        [DllImport(dllName)] public extern static void PL_fatal_error(string fmt, __arglist);

        // RECORDED DATABASE

        [DllImport(dllName)] public extern static IntPtr PL_record(IntPtr term);
        [DllImport(dllName)] public extern static int PL_recorded(IntPtr record, IntPtr term);
        [DllImport(dllName)] public extern static void PL_erase(IntPtr record);
        [DllImport(dllName)] public extern static IntPtr PL_duplicate_record(IntPtr r);

        [DllImport(dllName)] public extern static string PL_record_external(IntPtr t, out UIntPtr size);
        [DllImport(dllName)] public extern static int PL_recorded_external(string rec, IntPtr term);
        [DllImport(dllName)] public extern static int PL_erase_external(string rec);

        // PROLOG FLAGS

        [DllImport(dllName)] public extern static int PL_set_prolog_flag(string name, int type, __arglist);


        // INTERNAL FUNCTIONS

        [DllImport(dllName)] public extern static IntPtr _PL_get_atomic(IntPtr t);
        [DllImport(dllName)] public extern static void _PL_put_atomic(IntPtr t, IntPtr a);
        [DllImport(dllName)] public extern static int _PL_unify_atomic(IntPtr t, IntPtr a);
        [DllImport(dllName)] public extern static void _PL_get_arg_sz(UIntPtr index, IntPtr t, IntPtr a);
        [DllImport(dllName)] public extern static void _PL_get_arg(int index, IntPtr t, IntPtr a);


        // CHAR BUFFERS

        public const uint CVT_ATOM = 0x0001;
        public const uint CVT_STRING = 0x0002;
        public const uint CVT_LIST = 0x0004;
        public const uint CVT_INTEGER = 0x0008;
        public const uint CVT_FLOAT = 0x0010;
        public const uint CVT_VARIABLE = 0x0020;
        public const uint CVT_NUMBER = (CVT_INTEGER | CVT_FLOAT);
        public const uint CVT_ATOMIC = (CVT_NUMBER | CVT_ATOM | CVT_STRING);
        public const uint CVT_WRITE = 0x0040;
        public const uint CVT_WRITE_CANONICAL = 0x0080;
        public const uint CVT_WRITEQ = 0x00C0;
        public const uint CVT_ALL = (CVT_ATOMIC | CVT_LIST);
        public const uint CVT_MASK = 0x00ff;

        public const uint BUF_DISCARDABLE = 0x0000;
        public const uint BUF_RING = 0x0100;
        public const uint BUF_MALLOC = 0x0200;
        public const uint BUF_ALLOW_STACK = 0x0400;	/* allow pointer into (global) stack */

        public const uint CVT_EXCEPTION = 0x10000; /* throw exception on error */
        public const uint CVT_VARNOFAIL = 0x20000; /* return 2 if argument is unbound */

        /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        Output   representation   for   PL_get_chars()     and    friends.   The
        prepresentation type REP_FN is for   PL_get_file_name()  and friends. On
        Windows we use UTF-8 which is translated   by the `XOS' layer to Windows
        UNICODE file functions.
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

        public const uint REP_ISO_LATIN_1 = 0x0000; /* output representation */
        public const uint REP_UTF8 = 0x1000;
        public const uint REP_MB = 0x2000;
        public const uint REP_FN = REP_UTF8;

        public const uint PL_DIFF_LIST = 0x20000; /* PL_unify_chars() */

        [DllImport(dllName)] public extern static int PL_put_term_from_chars(IntPtr t, int flags, UIntPtr len, string s);
        [DllImport(dllName)] public extern static int PL_chars_to_term(string chars, IntPtr term);
        [DllImport(dllName)] public extern static int PL_wchars_to_term(string chars, IntPtr term);

        // EMBEDDING

        [DllImport(dllName)] public extern static int PL_initialise(int argc, string[] argv);
        [DllImport(dllName)] public extern static int PL_is_initialised(out int argc, out string[] argv);
        [DllImport(dllName)] public extern static int PL_set_resource_db_mem(byte[] data, UIntPtr size);
        [DllImport(dllName)] public extern static int PL_toplevel();
        [DllImport(dllName)] public extern static int PL_cleanup(int status);
        [DllImport(dllName)] public extern static void PL_cleanup_fork();
        [DllImport(dllName)] public extern static int PL_halt(int status);
    }
    class Program
    {
        // Our program executes the following query: absolute_day(date(2017, 7, 3), B).
        // The query simply serves to convert a Gregorian date into an absolute day, the
        // internal representation of time in the accounting system.

        static void Main(string[] args)
        {
            // See http://www.swi-prolog.org/pldoc/man?section=cmdline
            // Also see http://www.swi-prolog.org/pldoc/man?CAPI=PL_initialise
            string[] argv = new string[3];
            argv[0] = System.Reflection.Assembly.GetExecutingAssembly().Location;
            argv[1] = "-s";
            argv[2] = "C:\\Users\\murisi\\Mirror\\labs-accounts-assessor\\main.pl";
            PL.PL_initialise(argv.Length, argv);

            // Constructing the term date(2017, 7, 3)
            IntPtr date_atom = PL.PL_new_atom("date");
            IntPtr date_functor = PL.PL_new_functor(date_atom, 3);
            IntPtr date_year_term = PL.PL_new_term_ref();
            PL.PL_put_integer(date_year_term, 2017);
            IntPtr date_month_term = PL.PL_new_term_ref();
            PL.PL_put_integer(date_month_term, 7);
            IntPtr date_day_term = PL.PL_new_term_ref();
            PL.PL_put_integer(date_day_term, 3);
            IntPtr date_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(date_term, date_functor, __arglist(date_year_term, date_month_term, date_day_term));

            // Constructing the variable B
            IntPtr absolute_day_term = PL.PL_new_term_ref();

            // Constructing the query absolute_day(date(2017, 7, 3), B)
            IntPtr absolute_day_pred = PL.PL_predicate("absolute_day", 2, null);
            IntPtr absolute_day_pred_arg0 = PL.PL_new_term_refs(2);
            PL.PL_put_term(absolute_day_pred_arg0, date_term);
            IntPtr absolute_day_pred_arg1 = absolute_day_pred_arg0 + 1;
            PL.PL_put_term(absolute_day_pred_arg1, absolute_day_term);
            IntPtr qid = PL.PL_open_query(IntPtr.Zero, PL.Q_NORMAL, absolute_day_pred, absolute_day_pred_arg0);

            // Getting a solution B to the query
            PL.PL_next_solution(qid);
            PL.PL_get_integer(absolute_day_term, out int absolute_day);
            Console.WriteLine("Result of absolute_day(date(2017, 7, 3), B) is " + absolute_day);

            // Close query and wait key press to exit
            PL.PL_close_query(qid);
            Console.Read();
        }
    }
}
