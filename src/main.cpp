#include <aws/lambda-runtime/runtime.h>
#include <iostream>
#include <sodium.h>
#include <nlohmann/json.hpp>
#include <sstream>
#include <string>
#include <unordered_map>
#include <curl/curl.h>
#include <cstdlib>

using namespace aws::lambda_runtime;
using json = nlohmann::json;

std::string DISCORD_PUBLIC_KEY = std::getenv("DISCORD_PUBLIC_KEY");
std::string BRAWLSTARS_API_TOKEN = std::getenv("BRAWLSTARS_API_TOKEN");

// Function to parse the raw HTTP request string
std::unordered_map<std::string, std::string> parse_headers(const std::string& request) 
{
    std::unordered_map<std::string, std::string> headers;
    std::istringstream stream(request);
    std::string line;

    // Parse headers
    while (std::getline(stream, line) && !line.empty()) 
    {
        auto delimiter_pos = line.find(':');
        if (delimiter_pos != std::string::npos) {
            std::string header_name = line.substr(0, delimiter_pos);
            std::string header_value = line.substr(delimiter_pos + 1);
            // Trim leading spaces from header values
            header_value.erase(0, header_value.find_first_not_of(" \t"));
            headers[header_name] = header_value;
        }
    }
    
    return headers;
}

// Function to handle the response from the Brawl Stars API
static size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* s) {
    size_t newLength = size * nmemb;
    s->append((char*)contents, newLength);
    return newLength;
}
std::string get_brawl_stars_data() {
    CURL* curl;
    CURLcode res;
    std::string readBuffer;

    curl_global_init(CURL_GLOBAL_DEFAULT);
    curl = curl_easy_init();
    if(curl) {
        struct curl_slist *headers = NULL;
        headers = curl_slist_append(headers, ("Authorization: Bearer " + BRAWLSTARS_API_TOKEN).c_str());
        curl_easy_setopt(curl, CURLOPT_URL, "https://api.brawlstars.com/v1/events/rotation");
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &readBuffer);
        res = curl_easy_perform(curl);
        curl_easy_cleanup(curl);
    }
    curl_global_cleanup();
    return readBuffer;
}

invocation_response CommandHandler(json body)
{
    std::string command = body["data"]["name"];

    if(command == "bleb")
    {
         std::string brawl_data = get_brawl_stars_data();
        json response_json;
        response_json["type"] = 4; 
        response_json["data"]["content"] = brawl_data; 
  
        json response;
        response["statusCode"] = 200;
        response["headers"]["Content-Type"] = "application/json";
        response["body"] = response_json.dump();
        std::cout << response.dump() << std::endl;
        return invocation_response::success(response.dump(), "application/json");
    }
    else
    {
        return invocation_response::failure("unhandled command", "application/json");
    }
}

bool verify_payload(std::string signature, std::string timestamp, std::string body)
{
    std::cout << "Starting payload verification" << std::endl;

    if (sodium_init() < 0) {
        std::cerr << "Failed to initialize sodium" << std::endl;
        return false;
    }

    std::string message = timestamp + body;

    unsigned char sig[64];
    unsigned char pk[32];
    if (sodium_hex2bin(sig, sizeof(sig), signature.c_str(), signature.length(), NULL, NULL, NULL) != 0) 
    {
        std::cerr << "Invalid signature format" << std::endl;
        return false;
    }

    if (sodium_hex2bin(pk, sizeof(pk), DISCORD_PUBLIC_KEY.c_str(), DISCORD_PUBLIC_KEY.length(), NULL, NULL, NULL) != 0) 
    {
        std::cerr << "Invalid public key format" << std::endl;
        return false;
    }

    if (crypto_sign_ed25519_verify_detached(sig, reinterpret_cast<const unsigned char*>(message.c_str()), message.length(), pk) != 0) 
    {
        std::cerr << "Signature verification failed" << std::endl;
        return false;
    }

    std::cout << "Payload verfied" << std::endl;
    return true;
}

invocation_response LambdaHandler(invocation_request const& request) 
{
    std::cout << request.payload << std::endl;

    // Parse JSON payload
    json event;
    event = json::parse(request.payload);

    // Extract headers and body
    std::unordered_map<std::string, std::string> headers;
    headers = event.at("headers").get<std::unordered_map<std::string, std::string>>();
    
    std::string body = event.at("body").get<std::string>();
    std::string signature = headers.at("x-signature-ed25519");
    std::string timestamp = headers.at("x-signature-timestamp");

    if(!verify_payload(signature, timestamp, body))
    {
        return invocation_response::failure("failed signature", "application/json");
    }

    json body_json = json::parse(body);

     // Check if the body type is 1
    if (body_json["type"] == 1) 
    {
        json response_json;
        response_json["type"] = 1;
        return invocation_response::success(response_json.dump(), "application/json");
    }
    else if(body_json["type"] == 2)
    {
        return CommandHandler(body_json);
    }
    else
    {
        return invocation_response::failure("unhandled command", "application/json");
    }
}

int main() {
    run_handler(LambdaHandler);
    return 0;
}
