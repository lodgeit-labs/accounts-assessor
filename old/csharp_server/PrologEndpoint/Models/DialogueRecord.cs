using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace PrologEndpoint.Models
{
    public class DialogueRecord
    {
        [JsonProperty("question_id")]
        public int QuestionID { get; set; }
        [JsonProperty("response")]
        public int Response { get; set; }
    }
}