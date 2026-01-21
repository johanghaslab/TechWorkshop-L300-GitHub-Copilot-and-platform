using Microsoft.AspNetCore.Mvc;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using System.Text.Json;
using System.Text;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;

        public ChatController(IHttpClientFactory httpClientFactory, IConfiguration configuration)
        {
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
        }

        [HttpGet]
        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> SendMessage(string userMessage)
        {
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
    }
}
