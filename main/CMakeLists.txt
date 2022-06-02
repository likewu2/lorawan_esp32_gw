set(COMPONENT_REQUIRES )
set(COMPONENT_PRIV_REQUIRES )

set(COMPONENT_SRCS "AppMain.c"
                            "ESP32WifiConnector.c"
                            "LoraNodeManager.c"
                            "LoraRealtimeSender.c"
                            "LoraRealtimeSenderItf.c"
                            "LoraServerManager.c"
                            "LoraTransceiverItf.c"
                            "NetworkServerProtocolItf.c"
                            "SemtechProtocolEngine.c"
                            "ServerConnectorItf.c"
                            "ServerManagerItf.c"
                            "SX1276.c"
                            "TransceiverManagerItf.c"
                            "Utilities.c"
                            #"test_mqtt.c"
                            "test_mqtt_ws.c"
                            #"lwip/src/apps/mqtt/mqtt.c"
                            "connect.c"
                            )
set(COMPONENT_ADD_INCLUDEDIRS "include")

register_component()
