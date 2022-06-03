/*********************************************************************************************
PROJECT  : LoRaWAN ESP32 Gateway V1.x 
 
FILE     : lorawan_esp32_gw.c
 
AUTHOR   : F.Fargon 
 
PURPOSE  : Main program (entry point). 
           Initializes the interrupt driven event loop.
 
FEATURES : 
                  
COMMENTS : This program is designed for execution on ESP32 Module (Dev.C kit). 
           The LoRa radio is implemented with Semtech SX1276 chip (Modtronix inAir9 module)  
           The implementation uses the Espressif IDF V3.0 framework (with RTOS)
*********************************************************************************************/


/*********************************************************************************************
  Espressif framework includes
*********************************************************************************************/

#include "Common.h"
#include "ServerManagerItf.h"

#include <esp_chip_info.h>

/*********************************************************************************************
  Include for module implementation
*********************************************************************************************/

#include "main.h"
#include "Version.h"
#include "esp_spi_flash.h"
//#include "SX1276Itf.h"
#include "LoraNodeManagerItf.h"
#include "LoraServerManagerItf.h"

#include "esp_err.h"
#include "esp_log.h"

#include "nvs_flash.h"
#include "esp_wifi.h"
#include "esp_mac.h"

#include "test_mqtt.h"

/****************************************************************************** 
  Forward declaration
*******************************************************************************/


/****************************************************************************** 
  Implementation 
*******************************************************************************/

static const char *TAG = "qemu-esp32";

// Debug : global variables

ITransceiverManager g_pTransceiverManagerItf = NULL;
IServerManager g_pServerManagerItf = NULL;

TaskHandle_t g_PacketForwarderTask = NULL;

//ILoraTransceiver g_pLoraTransceiverItf = NULL;
//QueueHandle_t g_hEventQueue = NULL;
//CLoraTransceiverItf_EventOb g_Event;

static void initialize_nvs(void)
{
    esp_err_t err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES || err == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        err = nvs_flash_init();
    }
    ESP_ERROR_CHECK(err);
}

esp_netif_ip_info_t ip_info;
/* Initialize wifi with tcp/ip adapter */
static void initialize_wifi(void)
{

    ESP_ERROR_CHECK(esp_netif_init());

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));
    ESP_ERROR_CHECK(esp_wifi_set_storage(WIFI_STORAGE_RAM));
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));

    //esp_netif_set_ip4_addr(&ip_info.ip, 172, 17 , 0, 2);
    //esp_netif_set_ip4_addr(&ip_info.gw, 172, 17 , 0, 1);
    esp_netif_set_ip4_addr(&ip_info.ip, 192, 168 , 128, 252);
    esp_netif_set_ip4_addr(&ip_info.gw, 192, 168 , 128, 254);
    esp_netif_set_ip4_addr(&ip_info.netmask, 255, 255 , 255, 0);

    ESP_LOGI(TAG, "- IPv4 address: " IPSTR, IP2STR(&ip_info.ip));

    esp_wifi_connect();
}
#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT      BIT1

#define EXAMPLE_ESP_WIFI_SSID      "LAPTOP-NEGU2RE3"
#define EXAMPLE_ESP_WIFI_PASS      "qq123456"
#define EXAMPLE_ESP_MAXIMUM_RETRY  3

#define CONFIG_ESP_WIFI_AUTH_WPA2_PSK  1

#if CONFIG_ESP_WIFI_AUTH_OPEN
#define ESP_WIFI_SCAN_AUTH_MODE_THRESHOLD WIFI_AUTH_OPEN
#elif CONFIG_ESP_WIFI_AUTH_WEP
#define ESP_WIFI_SCAN_AUTH_MODE_THRESHOLD WIFI_AUTH_WEP
#elif CONFIG_ESP_WIFI_AUTH_WPA_PSK
#define ESP_WIFI_SCAN_AUTH_MODE_THRESHOLD WIFI_AUTH_WPA_PSK
#elif CONFIG_ESP_WIFI_AUTH_WPA2_PSK
#define ESP_WIFI_SCAN_AUTH_MODE_THRESHOLD WIFI_AUTH_WPA2_PSK
#elif CONFIG_ESP_WIFI_AUTH_WPA_WPA2_PSK
#define ESP_WIFI_SCAN_AUTH_MODE_THRESHOLD WIFI_AUTH_WPA_WPA2_PSK
#elif CONFIG_ESP_WIFI_AUTH_WPA3_PSK
#define ESP_WIFI_SCAN_AUTH_MODE_THRESHOLD WIFI_AUTH_WPA3_PSK
#elif CONFIG_ESP_WIFI_AUTH_WPA2_WPA3_PSK
#define ESP_WIFI_SCAN_AUTH_MODE_THRESHOLD WIFI_AUTH_WPA2_WPA3_PSK
#elif CONFIG_ESP_WIFI_AUTH_WAPI_PSK
#define ESP_WIFI_SCAN_AUTH_MODE_THRESHOLD WIFI_AUTH_WAPI_PSK
#endif

static EventGroupHandle_t s_wifi_event_group;

static int s_retry_num = 0;

static void event_handler(void* arg, esp_event_base_t event_base,
                                int32_t event_id, void* event_data)
{
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        if (s_retry_num < EXAMPLE_ESP_MAXIMUM_RETRY) {
            esp_wifi_connect();
            s_retry_num++;
            ESP_LOGI(TAG, "retry to connect to the AP");
        } else {
            xEventGroupSetBits(s_wifi_event_group, WIFI_FAIL_BIT);
        }
        ESP_LOGI(TAG,"connect to the AP fail");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;
        ESP_LOGI(TAG, "got ip:" IPSTR, IP2STR(&event->ip_info.ip));
        s_retry_num = 0;
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
    }
}

void wifi_init_sta(void)
{
    s_wifi_event_group = xEventGroupCreate();

    ESP_ERROR_CHECK(esp_netif_init());

    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_sta();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    esp_event_handler_instance_t instance_any_id;
    esp_event_handler_instance_t instance_got_ip;
    ESP_ERROR_CHECK(esp_event_handler_instance_register(WIFI_EVENT,
                                                        ESP_EVENT_ANY_ID,
                                                        &event_handler,
                                                        NULL,
                                                        &instance_any_id));
    ESP_ERROR_CHECK(esp_event_handler_instance_register(IP_EVENT,
                                                        IP_EVENT_STA_GOT_IP,
                                                        &event_handler,
                                                        NULL,
                                                        &instance_got_ip));

    wifi_config_t wifi_config = {
        .sta = {
            .ssid = EXAMPLE_ESP_WIFI_SSID,
            .password = EXAMPLE_ESP_WIFI_PASS,
            /* Setting a password implies station will connect to all security modes including WEP/WPA.
             * However these modes are deprecated and not advisable to be used. Incase your Access point
             * doesn't support WPA2, these mode can be enabled by commenting below line */
       .threshold.authmode = ESP_WIFI_SCAN_AUTH_MODE_THRESHOLD,
        },
    };
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA) );
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config) );
    ESP_ERROR_CHECK(esp_wifi_start() );

    ESP_LOGI(TAG, "wifi_init_sta finished.");

    /* Waiting until either the connection is established (WIFI_CONNECTED_BIT) or connection failed for the maximum
     * number of re-tries (WIFI_FAIL_BIT). The bits are set by event_handler() (see above) */
    EventBits_t bits = xEventGroupWaitBits(s_wifi_event_group,
            WIFI_CONNECTED_BIT | WIFI_FAIL_BIT,
            pdFALSE,
            pdFALSE,
            portMAX_DELAY);

    /* xEventGroupWaitBits() returns the bits before the call returned, hence we can test which event actually
     * happened. */
    if (bits & WIFI_CONNECTED_BIT) {
        ESP_LOGI(TAG, "connected to ap SSID:%s password:%s",
                 EXAMPLE_ESP_WIFI_SSID, EXAMPLE_ESP_WIFI_PASS);
    } else if (bits & WIFI_FAIL_BIT) {
        ESP_LOGI(TAG, "Failed to connect to SSID:%s, password:%s",
                 EXAMPLE_ESP_WIFI_SSID, EXAMPLE_ESP_WIFI_PASS);
    } else {
        ESP_LOGE(TAG, "UNEXPECTED EVENT");
    }
}

// Test task for LoraNodeManager interface debug
// This task simulates the PacketForwarder task receiving uplink packets
void test_task(void *pvParameter)
{
/*  CServerManagerItf_LoraSessionPacket pLoraSessionPacket;
  CTransceiverManagerItf_SessionEventOb SessionEvent;



  // Attach the PacketForwarder
//printf("Calling ITransceiverManager_Attach\n");
//
//CTransceiverManagerItf_AttachParamsOb AttachParams;
//AttachParams.m_hPacketForwarderTask = xTaskGetCurrentTaskHandle();
//
//ITransceiverManager_Attach(g_pTransceiverManagerItf, &AttachParams);
//
//printf("Return from ITransceiverManager_Attach\n");


  // Start the LoraNodeManager (i.e. receive packets from Nodes)
  printf("Calling ITransceiverManager_Start\n");

  CTransceiverManagerItf_StartParamsOb StartParams;
  StartParams.m_bForce = false;

  ITransceiverManager_Start(g_pTransceiverManagerItf, &StartParams);

  printf("Return from ITransceiverManager_Start\n");


  // Start the LoraServerManager (i.e. transmit packets to network server)
  printf("Calling ITransceiverManager_Start\n");

  CServerManagerItf_StartParamsOb ServerStartParams;
  StartParams.m_bForce = false;

  IServerManager_Start(g_pServerManagerItf, &ServerStartParams);

  printf("Return from IServerManager_Start\n");
*/

  /*while(1) 
  {
    // Wait for notification from LoraNodeManager (packet received)
    if (xTaskNotifyWait(0, 0xFFFFFFFF, &pLoraSessionPacket, pdMS_TO_TICKS(100)) == pdTRUE)
    {
      printf("Test Task : Packet received\n");
    }
  }*/
  

/*

  // Set continuous receive mode and wait for packets
  CLoraTransceiverItf_ReceiveParamsOb ReceiveParams;
  ReceiveParams.m_bForce = false;
  ILoraTransceiver_Receive(g_pLoraTransceiverItf, &ReceiveParams);

  // Back to standby
//CLoraTransceiverItf_StandByParamsOb StandByParams;
//StandByParams.m_bForce = false;
//ILoraTransceiver_StandBy(g_pLoraTransceiverItf, &StandByParams);


  CLoraTransceiverItf_LoraPacket pPacketToSend = NULL;
  CLoraTransceiverItf_SendParamsOb SendParams;

  while(1) 
  {
    if (xQueueReceive(g_hEventQueue, &g_Event, pdMS_TO_TICKS(50)) == pdPASS)
    {
      // Process event
      if (g_Event.m_wEventType == LORATRANSCEIVERITF_EVENT_PACKETRECEIVED)
      {
        printf("Test Task : Packet received, length: %d\n", ((CLoraTransceiverItf_LoraPacket) (g_Event.m_pEventData))->m_dwDataSize);

        pPacketToSend = pvPortMalloc(sizeof(CLoraTransceiverItf_LoraPacketOb) + ((CLoraTransceiverItf_LoraPacket) (g_Event.m_pEventData))->m_dwDataSize);
        pPacketToSend->m_dwTimestamp = 0;
        pPacketToSend->m_dwDataSize = ((CLoraTransceiverItf_LoraPacket) (g_Event.m_pEventData))->m_dwDataSize;
        for (int i = 0; i < pPacketToSend->m_dwDataSize; i++)
        {
          pPacketToSend->m_usData[i] = ((CLoraTransceiverItf_LoraPacket) (g_Event.m_pEventData))->m_usData[i];
        }

        // Set packet read semaphore
        ((CLoraTransceiverItf_LoraPacket) (g_Event.m_pEventData))->m_dwDataSize = 0;

        printf("Test Task : Sending packet\n");

        SendParams.m_pPacketToSend = pPacketToSend;
        ILoraTransceiver_Send(g_pLoraTransceiverItf, &SendParams);
      }
      else if (g_Event.m_wEventType == LORATRANSCEIVERITF_EVENT_PACKETSENT)
      {
        printf("Test Task : Notified Packet sent\n");
        vPortFree(pPacketToSend);

        printf("Test Task : Activating receive mode\n");
        ILoraTransceiver_Receive(g_pLoraTransceiverItf, &ReceiveParams);
      }

    }
    printf("Test Task excuting\n");
  }

*/


/*
  CSX1276 * pSX1276 = CSX1276_New(0);
  
  // Check SPI interface
  CSX1276_ON(pSX1276);

  // Check Receive Packet Lora
  CSX1276_setCR(pSX1276, CR_5);
  CSX1276_setSF(pSX1276, SF_7);
  CSX1276_setBW(pSX1276, BW_125);
  CSX1276_setChannel(pSX1276, CH_18_868);
  CSX1276_setPreambleLength(pSX1276, 8);
//  CSX1276_setCRC_OFF(pSX1276);
//  CSX1276_setHeaderON(pSX1276);

//  CSX1276_setSyncWord(pSX1276, 0x34);
//  CSX1276_getSyncWord(pSX1276);

  CSX1276_getMode(pSX1276);

//CSX1276_cadDetected(pSX1276);

//CSX1276_availableData2(pSX1276, 180000);

CSX1276_receiveAll2(pSX1276, 180000);
*/
  while(1) 
  {
    // Idle loop = debug tests called before entering task main loop
    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }
   
}



/*********************************************************************************************
FUNCTION  : void app_main(void)

ARGUMENTS : None.

RETURN    : None.

PURPOSE   : User application entry point. 
            The function starts the application tasks and enters the event driven loop.
 
COMMENTS  : None. 
*********************************************************************************************/
void app_main()
{
  printf("LoRaWAN Gateway version:%s\n", g_szVersionString);

  /* Print chip information */
  esp_chip_info_t chip_info;
  esp_chip_info(&chip_info);
  printf("This is ESP32 chip with %d CPU cores, WiFi%s%s, ",
          chip_info.cores,
          (chip_info.features & CHIP_FEATURE_BT) ? "/BT" : "",
          (chip_info.features & CHIP_FEATURE_BLE) ? "/BLE" : "");

  printf("silicon revision %d, ", chip_info.revision);

  printf("%dMB %s flash\n", spi_flash_get_chip_size() / (1024 * 1024),
          (chip_info.features & CHIP_FEATURE_EMB_FLASH) ? "embedded" : "external");



  // configMINIMAL_STACK_SIZE = 768 -> stack overflow !!!!
  //xTaskCreate(&test_task, "test_task", configMINIMAL_STACK_SIZE, NULL, 5, NULL);


  // Create the LoraNodeManager

/*  printf("Calling CLoraNodeManager_CreateInstance\n");

  g_pTransceiverManagerItf = CLoraNodeManager_CreateInstance(1);

  printf("Return from CLoraNodeManager_CreateInstance\n");

  // Create the LoraServerManager

  printf("Calling CLoraServerManager_CreateInstance\n");

  g_pServerManagerItf = CLoraServerManager_CreateInstance(1, 0, SERVERMANAGER_PROTOCOL_SEMTECH);

  printf("Return from CLoraServerManager_CreateInstance\n");


  // Initialize the LoraNodeManager

  printf("Calling ITransceiverManager_Initialize\n");

  CTransceiverManagerItf_InitializeParamsOb InitializeParams;
  InitializeParams.m_pServerManagerItf = g_pServerManagerItf;
  InitializeParams.m_bUseBuiltinSettings = true;

  ITransceiverManager_Initialize(g_pTransceiverManagerItf, &InitializeParams);

  printf("Return from ITransceiverManager_Initialize\n");


  // Initialize the LoraServerManager

  printf("Calling IServerManager_Initialize\n");

//CServerManagerItf_LoraServerSettingsOb LoraServerSettings;
//strcpy(LoraServerSettings.ConnectorSettings[0].m_szNetworkName, "");
//strcpy(LoraServerSettings.ConnectorSettings[0].m_szNetworkPassword, "");
//strcpy(LoraServerSettings.ConnectorSettings[0].m_szNetworkUser, "");
//
//LoraServerSettings.m_wNetworkServerProtocol = SERVERMANAGER_PROTOCOL_SEMTECH;
//strcpy(LoraServerSettings.m_szNetworkServerUrl, "");
//strcpy(LoraServerSettings.m_szNetworkServerUser, "");
//strcpy(LoraServerSettings.m_szNetworkServerPassword, "");

  CServerManagerItf_InitializeParamsOb InitializeServerParams;
  InitializeServerParams.m_bUseBuiltinSettings = true;
//InitializeServerParams.pLoraServerSettings = &LoraServerSettings;
  InitializeServerParams.pTransceiverManagerItf = g_pTransceiverManagerItf;

  IServerManager_Initialize(g_pServerManagerItf, &InitializeServerParams);

  printf("Return from IServerManager_Initialize\n");
*/


//// Attach the PacketForwarder
//printf("Calling ITransceiverManager_Attach\n");
//
//CTransceiverManagerItf_AttachParamsOb AttachParams;
//AttachParams.m_hPacketForwarderTask = NULL;
//
//ITransceiverManager_Attach(g_pTransceiverManagerItf, &AttachParams);
//
//printf("Return from ITransceiverManager_Attach\n");
//
//
//// Start the LoraNodeManager (i.e. receive packets from Nodes)
//printf("Calling ITransceiverManager_Start\n");
//
//CTransceiverManagerItf_StartParamsOb StartParams;
//StartParams.m_bForce = false;
//
//ITransceiverManager_Start(g_pTransceiverManagerItf, &StartParams);
//
//printf("Return from ITransceiverManager_Start\n");




/* Test_APP_1 = direct use of CSX1276 

  // Initialize CSX1276

  printf("Calling CSX1276_CreateInstance");

  g_pLoraTransceiverItf = CSX1276_CreateInstance();

  printf("Return from CSX1276_CreateCSX1276Instance");

  g_hEventQueue = xQueueCreate(5, sizeof(CLoraTransceiverItf_EventOb));

  CLoraTransceiverItf_InitializeParamsOb InitializeParams;

  InitializeParams.m_hEventNotifyQueue = g_hEventQueue;
  InitializeParams.pLoraMAC = NULL;
  InitializeParams.pLoraMode = NULL;
  InitializeParams.pPowerMode = NULL;
  InitializeParams.pFreqChannel = NULL;

  printf("Calling ILoraTransceiver_Initialize");

  ILoraTransceiver_Initialize(g_pLoraTransceiverItf, &InitializeParams);

  printf("Return from ILoraTransceiver_Initialize");

  // TO DO -> full configuration
  CLoraTransceiverItf_SetLoraModeParamsOb SetLoraModeParams;
  SetLoraModeParams.m_bForce = false;
  SetLoraModeParams.m_usBandwidth = LORATRANSCEIVERITF_BANDWIDTH_125;
  SetLoraModeParams.m_usCodingRate = LORATRANSCEIVERITF_CR_5;
  SetLoraModeParams.m_usSpreadingFactor = LORATRANSCEIVERITF_SF_7;
  SetLoraModeParams.m_usLoraMode = LORATRANSCEIVERITF_LORAMODE_NONE;

  ILoraTransceiver_SetLoraMode(g_pLoraTransceiverItf, &SetLoraModeParams);

  CLoraTransceiverItf_SetFreqChannelParamsOb SetFreqChannelParams;
  SetFreqChannelParams.m_bForce = false;
  SetFreqChannelParams.m_usFreqChannel = LORATRANSCEIVERITF_FREQUENCY_CHANNEL_18;

  ILoraTransceiver_SetFreqChannel(g_pLoraTransceiverItf, &SetFreqChannelParams);

  CLoraTransceiverItf_SetPowerModeParamsOb SetPowerModeParams;
  SetPowerModeParams.m_bForce = false;
  SetPowerModeParams.m_usPowerMode = LORATRANSCEIVERITF_POWER_MODE_LOW;
  SetPowerModeParams.m_usPowerLevel = LORATRANSCEIVERITF_POWER_LEVEL_NONE;
  SetPowerModeParams.m_usOcpRate = LORATRANSCEIVERITF_OCP_NONE;

  ILoraTransceiver_SetPowerMode(g_pLoraTransceiverItf, &SetPowerModeParams);

*/

  printf("\ninitializing wifi\n");
  uint8_t mac_addr[8] = {0x02, 0x00, 0x00, 0xBE, 0xEE, 0xEF};
  esp_base_mac_addr_set(mac_addr);

  initialize_nvs();

  //initialize_wifi();
  ESP_LOGI(TAG, "ESP_WIFI_MODE_STA");
  wifi_init_sta();

  printf("\nSTART TEST mqtt\n");
  START_TEST();

  // Start task to process events
  xTaskCreate(&test_task, "test_task", 3072, NULL, 5, &g_PacketForwarderTask);

}
