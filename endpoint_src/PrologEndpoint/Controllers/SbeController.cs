using PrologEndpoint.Helpers;
using PrologEndpoint.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Runtime.InteropServices;
using System.Runtime.Serialization.Json;
using System.Threading.Tasks;
using System.Web.Http;
using System.Xml;
using System.Xml.Linq;
using System.Xml.XPath;
using static PrologEndpoint.Helpers.PL;

namespace PrologEndpoint.Controllers
{
    public class SbeController : ApiController
    {
        private unsafe readonly char* COMMA = (char*)Marshal.StringToHGlobalAnsi(",");
        private unsafe readonly char* NEXT_STATE = (char*)Marshal.StringToHGlobalAnsi("sbe_next_state");

        private unsafe PL.term_t *ConstructRecord(DialogueRecord record)
        {
            // Constructing the term (record.QuestionID, record.Response)
            atom_t* record_atom = PL.PL_new_atom(COMMA);
            functor_t* record_functor = PL.PL_new_functor(record_atom, 2);
            term_t* question_id_term = PL.PL_new_term_ref();
            PL.PL_put_integer(question_id_term, record.QuestionID);
            term_t* response_term = PL.PL_new_term_ref();
            PL.PL_put_integer(response_term, record.Response);
            term_t* record_term = PL.PL_new_term_ref();
            PL.PL_cons_functor(record_term, record_functor, __arglist(question_id_term, response_term));
            return record_term;
        }

        private unsafe PL.term_t *ConstructState(List<DialogueRecord> records)
        {
            term_t* records_term = PL.PL_new_term_ref();
            PL.PL_put_nil(records_term);
            // We go backwards through the array because Prolog lists are constructed by consing.
            for (int i = records.Count - 1; i >= 0; i--)
            {
                // Constructing term [Record | Records] where
                // Record is the Prolog term corresponding to records[i] and
                // Records is the list constructed so far.
                PL.PL_cons_list(records_term, ConstructRecord(records[i]), records_term);
            }
            return records_term;
        }

        private unsafe void NextState(List<DialogueRecord> current_state, int current_question_id, out int next_question_id, out String next_question_prompt)
        {
            // Mark the current state of memory
            fid_t* fid = PL.PL_open_foreign_frame();
            // Make a place for storing query results
            term_t* next_question_id_term = PL.PL_new_term_ref();
            term_t* next_question_prompt_term = PL.PL_new_term_ref();

            // Query for the next state.
            predicate_t* next_state_pred = PL.PL_predicate(NEXT_STATE, 4, null);
            term_t* next_state_pred_arg0 = PL.PL_new_term_refs(4);
            PL.PL_put_term(next_state_pred_arg0, ConstructState(current_state));
            term_t* next_state_pred_arg1 = (term_t*)(1 + (byte*)next_state_pred_arg0);
            PL.PL_put_integer(next_state_pred_arg1, current_question_id);
            term_t* next_state_pred_arg2 = (term_t*)(2 + (byte*)next_state_pred_arg0);
            PL.PL_put_term(next_state_pred_arg2, next_question_id_term);
            term_t* next_state_pred_arg3 = (term_t*)(3 + (byte*)next_state_pred_arg0);
            PL.PL_put_term(next_state_pred_arg3, next_question_prompt_term);
            qid_t* qid = PL.PL_open_query(null, PL.PL_Q_NORMAL, next_state_pred, next_state_pred_arg0);
            PL.PL_next_solution(qid);

            // Extract the results of the query
            int _next_question_id;
            PL.PL_get_integer(next_question_id_term, &_next_question_id);
            next_question_id = _next_question_id;
            next_question_prompt = PL.PL_get_string_chars(next_question_prompt_term);

            // Close the query
            PL.PL_close_query(qid);
            PL.PL_discard_foreign_frame(fid);
        }

        // POST api/<controller>
        [HttpPost]
        public DialogueResponse Post([FromBody] DialogueRequest dreq)
        {
        	/*
        		dreq == 
        		{
        			response = 0 or 1;
        			current_state = [
	        		{
	        			response = 1;
	        			question_id = 7;
	        		},
	        		{
	        			response = 0;
	        			question_id = 6;
	        		}..]
	        		
	        	}
        			
        	
        	*/
            // 0 is the question id before any questions are asked.
            int current_question_id = -1;
            // Note the unanswered question in the received CurrentState.
            // Put the received response as an answer to the unanswered question.
            foreach (DialogueRecord x in dreq.CurrentState)
            {
                if (x.Response == -1)
                {
                    x.Response = dreq.Response;
                    current_question_id = x.QuestionID;
                    break;
                }
            }
            // Use a Prolog Engine to get the next question id and prompt
            WebApiApplication.ObtainEngine();

            NextState(dreq.CurrentState, current_question_id, out int next_question_id, out String next_question_prompt);

            WebApiApplication.ReleaseEngine();

            // Give a final answer or update the state in preparation for the next question.
            DialogueResponse dres = new DialogueResponse();
            if (next_question_id == -1) dres.Answer = "No";
            else if (next_question_id == -2) dres.Answer = "Yes";
            else
            {
                dres.Question = next_question_prompt;
                dres.State = dreq.CurrentState;
                dres.State.Add(new DialogueRecord() { QuestionID = next_question_id, Response = -1 });
            }
            return dres;
        }
    }
}

/* todo refactor with ResidencyController.cs */