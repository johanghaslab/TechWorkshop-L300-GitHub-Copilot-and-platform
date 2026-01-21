using System.Text;
using System.Text.Json;

namespace ZavaStorefront.Services;

public class ChatService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<ChatService> _logger;
    private readonly string _endpointUrl;
    private readonly string _apiKey;

    public ChatService(HttpClient httpClient, IConfiguration configuration, ILogger<ChatService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
        _endpointUrl = _configuration["Phi4:EndpointUrl"] ?? "https://placeholder-foundry-phi4-endpoint.example.com/api/chat";
        _apiKey = _configuration["Phi4:ApiKey"] ?? "your-api-key-here";
    }

    public async Task<string> SendMessageAsync(string userMessage)
    {
        try
        {
            _logger.LogInformation("Sending message to Phi4 endpoint: {EndpointUrl}", _endpointUrl);

            var requestBody = new
            {
                messages = new[]
                {
                    new { role = "user", content = userMessage }
                }
            };

            var jsonContent = JsonSerializer.Serialize(requestBody);
            var content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

            var request = new HttpRequestMessage(HttpMethod.Post, _endpointUrl)
            {
                Content = content
            };

            if (!string.IsNullOrEmpty(_apiKey) && _apiKey != "your-api-key-here")
            {
                request.Headers.Add("Authorization", $"Bearer {_apiKey}");
            }

            var response = await _httpClient.SendAsync(request);

            if (response.IsSuccessStatusCode)
            {
                var responseContent = await response.Content.ReadAsStringAsync();
                _logger.LogInformation("Received response from Phi4 endpoint");

                // Parse the response - adjust based on actual Phi4 API response format
                var jsonResponse = JsonSerializer.Deserialize<JsonElement>(responseContent);
                
                // Try to extract the message from common response formats
                if (jsonResponse.TryGetProperty("response", out var responseText))
                {
                    return responseText.GetString() ?? "No response from AI";
                }
                else if (jsonResponse.TryGetProperty("message", out var messageText))
                {
                    return messageText.GetString() ?? "No response from AI";
                }
                else if (jsonResponse.TryGetProperty("choices", out var choices) && choices.GetArrayLength() > 0)
                {
                    var firstChoice = choices[0];
                    if (firstChoice.TryGetProperty("message", out var choiceMessage))
                    {
                        if (choiceMessage.TryGetProperty("content", out var content_))
                        {
                            return content_.GetString() ?? "No response from AI";
                        }
                    }
                }

                // If no known format, return raw response
                return responseContent;
            }
            else
            {
                _logger.LogWarning("Phi4 endpoint returned error: {StatusCode}", response.StatusCode);
                return $"Error: Unable to get response from AI (Status: {response.StatusCode})";
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calling Phi4 endpoint");
            return $"Error: {ex.Message}";
        }
    }
}
