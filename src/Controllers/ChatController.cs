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
        private readonly ContentSafetyClient? _contentSafetyClient;
        private const string WarningMessage = "Sorry, I can't help with that request.";
        private const int UnsafeSeverityThreshold = 2;
        private const string PlaceholderEndpoint = "https://your-content-safety-endpoint";
        private const string PlaceholderApiKey = "your-content-safety-api-key";
        private const string OutputType = "FourSeverityLevels";
        private static readonly string[] SafetyCategories = { "Violence", "Sexual", "Hate", "SelfHarm", "Jailbreak" };

        public ChatController(ChatService chatService, IConfiguration configuration, ILogger<ChatController> logger)
        {
            _chatService = chatService;
            _configuration = configuration;
            _logger = logger;
            var endpoint = _configuration["ContentSafety:Endpoint"];
            var apiKey = _configuration["ContentSafety:ApiKey"];
            if (!string.IsNullOrWhiteSpace(endpoint) && !string.IsNullOrWhiteSpace(apiKey) &&
                !string.Equals(endpoint, PlaceholderEndpoint, StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(apiKey, PlaceholderApiKey, StringComparison.Ordinal))
            {
                _contentSafetyClient = new ContentSafetyClient(new Uri(endpoint), new AzureKeyCredential(apiKey));
            }
            else
            {
                _logger.LogWarning("Content safety configuration missing.");
            }
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
                if (_contentSafetyClient is null)
                {
                    return (false, WarningMessage);
                }
                using RequestContent content = RequestContent.Create(new
                {
                    text = userMessage,
                    categories = SafetyCategories,
                    outputType = OutputType
                });
                Response response = await _contentSafetyClient.AnalyzeTextAsync(content);
                if (response.Status < 200 || response.Status >= 300)
                {
                    _logger.LogWarning("Content safety request failed with status {Status}.", response.Status);
                    return (false, WarningMessage);
                }
                if (response.ContentStream is null || !response.ContentStream.CanRead)
                {
                    _logger.LogWarning("Content safety response missing content stream.");
                    return (false, WarningMessage);
                }
                if (response.ContentStream.CanSeek)
                {
                    try
                    {
                        response.ContentStream.Position = 0;
                    }
                    catch (IOException ex)
                    {
                        _logger.LogWarning(ex, "Content safety response stream could not be reset.");
                        return (false, WarningMessage);
                    }
                }
                using var document = JsonDocument.Parse(response.ContentStream);
                if (!document.RootElement.TryGetProperty("categoriesAnalysis", out var categoriesAnalysis))
                {
                    _logger.LogWarning("Content safety response missing categories analysis.");
                    return (false, WarningMessage);
                }
                if (categoriesAnalysis.ValueKind != JsonValueKind.Array)
                {
                    _logger.LogWarning("Content safety categories analysis is not an array.");
                    return (false, WarningMessage);
                }
                var hasCategories = false;
                var isUnsafe = false;
                foreach (var category in categoriesAnalysis.EnumerateArray())
                {
                    hasCategories = true;
                    if (!category.TryGetProperty("severity", out var severityElement) ||
                        !severityElement.TryGetInt32(out var severity))
                    {
                        _logger.LogWarning("Content safety response missing severity.");
                        return (false, WarningMessage);
                    }
                    if (severity >= UnsafeSeverityThreshold)
                    {
                        isUnsafe = true;
                        break;
                    }
                }
                if (!hasCategories)
                {
                    _logger.LogWarning("Content safety response had no categories.");
                    return (false, WarningMessage);
                }
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
