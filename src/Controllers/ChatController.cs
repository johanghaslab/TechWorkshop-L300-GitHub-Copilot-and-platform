using Microsoft.AspNetCore.Mvc;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using System.Text.Json;
using System.Text;
using Azure;
using Azure.AI.ContentSafety;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ChatController> _logger;

        public ChatController(IHttpClientFactory httpClientFactory, IConfiguration configuration, ILogger<ChatController> logger)
        {
            _httpClientFactory = httpClientFactory;
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
            var isSafe = await IsUserMessageSafeAsync(userMessage);
            if (!isSafe)
            {
                return Json(new { response = "Sorry—I can’t help with that request. Please rephrase and try again." });
            }

            // TODO: Replace with actual Foundry Phi4 endpoint URL
            var endpoint = _configuration["Foundry:Phi4Endpoint"] ?? "https://your-phi4-endpoint-url";
            var client = _httpClientFactory.CreateClient();
            var requestBody = new { input = userMessage };
            var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");
            var response = await client.PostAsync(endpoint, content);
            var responseString = await response.Content.ReadAsStringAsync();
            // Optionally parse responseString if needed
            return Json(new { response = responseString });
        }

        private async Task<bool> IsUserMessageSafeAsync(string userMessage)
        {
            var contentSafetyEndpoint = _configuration["ContentSafety:Endpoint"];
            var contentSafetyApiKey = _configuration["ContentSafety:ApiKey"];

            if (string.IsNullOrWhiteSpace(contentSafetyEndpoint) || string.IsNullOrWhiteSpace(contentSafetyApiKey))
            {
                _logger.LogWarning("Content Safety is not configured; skipping safety check.");
                return true;
            }

            var client = new ContentSafetyClient(new Uri(contentSafetyEndpoint), new AzureKeyCredential(contentSafetyApiKey));
            var result = await client.AnalyzeTextAsync(new AnalyzeTextOptions(userMessage));

            var unsafeCategories = result.Value.CategoriesAnalysis
                .Where(c =>
                    c.Category.ToString().Equals("Hate", StringComparison.OrdinalIgnoreCase) ||
                    c.Category.ToString().Equals("Sexual", StringComparison.OrdinalIgnoreCase) ||
                    c.Category.ToString().Equals("Violence", StringComparison.OrdinalIgnoreCase) ||
                    c.Category.ToString().Equals("SelfHarm", StringComparison.OrdinalIgnoreCase) ||
                    c.Category.ToString().Equals("Jailbreak", StringComparison.OrdinalIgnoreCase))
                .Where(c => c.Severity >= 2)
                .ToList();

            _logger.LogInformation(
                "Content Safety result: {Categories}; decision={Decision}",
                string.Join(", ", result.Value.CategoriesAnalysis.Select(c => $"{c.Category}:{c.Severity}")),
                unsafeCategories.Count == 0 ? "safe" : "unsafe");

            return unsafeCategories.Count == 0;
        }
    }
}
