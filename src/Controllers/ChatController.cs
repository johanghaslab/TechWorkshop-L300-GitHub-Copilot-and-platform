using Azure;
using Azure.AI.ContentSafety;
using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly ChatService _chatService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ChatController> _logger;

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
                var endpoint = _configuration["ContentSafety:Endpoint"] ?? "https://your-content-safety-endpoint";
                var apiKey = _configuration["ContentSafety:ApiKey"] ?? "your-content-safety-api-key";
                var client = new ContentSafetyClient(new Uri(endpoint), new AzureKeyCredential(apiKey));
                var request = new AnalyzeTextOptions(userMessage)
                {
                    Categories =
                    {
                        TextCategory.Violence,
                        TextCategory.Sexual,
                        TextCategory.Hate,
                        TextCategory.SelfHarm,
                        new TextCategory("Jailbreak")
                    }
                };
                Response<AnalyzeTextResult> response = await client.AnalyzeTextAsync(request);
                var isUnsafe = response.Value.CategoriesAnalysis.Any(category => category.Severity.GetValueOrDefault() >= 2);
                _logger.LogInformation("Content safety result: {IsSafe}", !isUnsafe);
                return (!isUnsafe, "Sorry, I can't help with that request.");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Content safety check failed");
                return (false, "Sorry, I can't help with that request.");
            }
        }
    }
}
