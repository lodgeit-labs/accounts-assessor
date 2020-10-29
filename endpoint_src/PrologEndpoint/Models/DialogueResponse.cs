using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace PrologEndpoint.Models
{
    public class DialogueResponse
    {
        [JsonProperty("question", NullValueHandling = NullValueHandling.Ignore)]
        public String Question { get; set; }
        [JsonProperty("state", NullValueHandling = NullValueHandling.Ignore)]
        public List<DialogueRecord> State { get; set; }
        [JsonProperty("answer", NullValueHandling = NullValueHandling.Ignore)]
        public String Answer { get; set; }
    }
}