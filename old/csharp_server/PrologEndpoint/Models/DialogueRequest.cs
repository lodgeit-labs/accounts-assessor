using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace PrologEndpoint.Models
{
    public class DialogueRequest
    {
        [JsonProperty("current_state")]
        public List<DialogueRecord> CurrentState { get; set; }
        [JsonProperty("response")]
        public int Response { get; set; }
    }
}