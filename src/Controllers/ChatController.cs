using Azure;
using Azure.AI.ContentSafety;
using Azure.Core;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly ChatService _chatService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ChatController> _logger;
        private const string WarningMessage = "Sorry, I can't help with that request.";
        private const int UnsafeSeverityThreshold = 2;
        private const string PlaceholderEndpoint = "https://your-content-safety-endpoint";
        private const string PlaceholderApiKey = "your-content-safety-api-key";

        public ChatController(ChatService chatService, IConfiguration configuration, ILogger<ChatController> logger)
        {
            _chatService = chatService;
            _configuration = configuration;
            _logger = logger;
        }

        [HttpGet]
        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> SendMessage(string userMessage)
        {
            var safetyCheck = await IsSafeMessageAsync(userMessage);
            if (!safetyCheck.IsSafe)
            {
                return Json(new { response = safetyCheck.WarningMessage });
            }
            var response = await _chatService.SendMessageAsync(userMessage);
            return Json(new { response });
        }

        private async Task<(bool IsSafe, string WarningMessage)> IsSafeMessageAsync(string userMessage)
        {
            try
            {
                var endpoint = _configuration["ContentSafety:Endpoint"];
                var apiKey = _configuration["ContentSafety:ApiKey"];
                if (string.IsNullOrWhiteSpace(endpoint) || string.IsNullOrWhiteSpace(apiKey) ||
                    string.Equals(endpoint, PlaceholderEndpoint, StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(apiKey, PlaceholderApiKey, StringComparison.Ordinal))
                {
                    _logger.LogWarning("Content safety configuration missing.");
                    return (false, WarningMessage);
                }
                var client = new ContentSafetyClient(new Uri(endpoint), new AzureKeyCredential(apiKey));
                using RequestContent content = RequestContent.Create(new
                {
                    text = userMessage,
                    categories = new[] { "Violence", "Sexual", "Hate", "SelfHarm", "Jailbreak" },
                    outputType = "FourSeverityLevels"
                });
                Response response = await client.AnalyzeTextAsync(content);
                if (response.ContentStream is null)
                {
                    _logger.LogWarning("Content safety response missing content stream.");
                    return (false, WarningMessage);
                }
                using var document = JsonDocument.Parse(response.ContentStream);
                if (!document.RootElement.TryGetProperty("categoriesAnalysis", out var categoriesAnalysis))
                {
                    _logger.LogWarning("Content safety response missing categories analysis.");
                    return (false, WarningMessage);
                }
                var isUnsafe = categoriesAnalysis.EnumerateArray()
                    .Any(category => category.GetProperty("severity").GetInt32() >= UnsafeSeverityThreshold);
                _logger.LogInformation("Content safety result: {IsSafe}", !isUnsafe);
                return (!isUnsafe, WarningMessage);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Content safety check failed");
                return (false, WarningMessage);
            }
        }
    }
}
