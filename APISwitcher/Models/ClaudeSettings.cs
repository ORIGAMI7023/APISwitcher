using System.Text.Json;
using System.Text.Json.Serialization;

namespace APISwitcher.Models;

public class ClaudeSettings
{
    [JsonExtensionData]
    public Dictionary<string, JsonElement>? ExtensionData { get; set; }
}
