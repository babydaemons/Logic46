#include "stdafx.h"
#include <cwchar>

using namespace System;
using namespace System::IO;
using namespace System::Net;
using namespace System::Net::Http;
using namespace System::Threading::Tasks;
using namespace System::Runtime::InteropServices;

namespace TradeTransmitterReceiver
{
    public ref class MT4
    {
    private:
        static HttpClient^ _httpClient = nullptr;
        static String^ _server;

    public:
        static int TradeTransmitterReceiveStart(String^ server)
        {
            if (_httpClient == nullptr)
            {
                _httpClient = gcnew HttpClient();
                _server = server;
                String^ uri = _server + "/api/polling/start";
                _httpClient->GetAsync(uri)->Wait();
                return 0;
            }
            else
            {
                return -1;
            }
        }

        static void TradeTransmitterReceiveStop()
        {
            if (_httpClient != nullptr)
            {
                String^ uri = _server + "/api/polling/stop";
                _httpClient->GetAsync(uri)->Wait();
                delete _httpClient;
                _httpClient = nullptr;
            }
        }

        static String^ TradeTransmitterReceivePolling()
        {
            if (_httpClient != nullptr)
            {
                String^ uri = _server + "/api/polling/execute";
                Task^ task_response = _httpClient->GetAsync(uri);
                HttpResponseMessage^ response = gcnew HttpResponseMessage();
                task_response->FromResult(response);
                task_response->Wait();
                Task^ task_stream = response->Content->ReadAsStreamAsync();
                task_stream->Wait();
                MemoryStream^ stream = gcnew MemoryStream();
                task_stream->FromResult(stream);
                return stream->ToString();
            }
            else
            {
                return "0";
            }
        }
    };
}

// C-style export functions
extern "C" __declspec(dllexport) int __stdcall TradeTransmitterReceiveStart(const wchar_t* server)
{
    String^ managedUri = gcnew String(server);
    return TradeTransmitterReceiver::MT4::TradeTransmitterReceiveStart(managedUri);
}

extern "C" __declspec(dllexport) void __stdcall TradeTransmitterReceiveStop()
{
    TradeTransmitterReceiver::MT4::TradeTransmitterReceiveStop();
}

extern "C" __declspec(dllexport) void __stdcall TradeTransmitterReceivePolling(char result[], size_t size)
{
    String^ managed_value = TradeTransmitterReceiver::MT4::TradeTransmitterReceivePolling();
    IntPtr ptr = Marshal::StringToHGlobalUni(managed_value);
    wchar_t* unmanaged_value = static_cast<wchar_t*>(ptr.ToPointer());
    for (int i = 0; unmanaged_value[i] != 0; ++i) {
        result[i] = (char)unmanaged_value[i];
    }
    Marshal::FreeHGlobal(ptr);
}
