frame_container = FactlinkJailRoot.$factlinkCoreContainer[0]
iframe = document.createElement('iframe')
frame_container.appendChild(iframe)
FactlinkJailRoot.createReceiverEnvoy FactlinkJailRoot.annotatedSiteReceiver
iframe.id = "factlink-modal-frame"
iframe.src = "#{FactlinkConfig.api}/client/blank"
FactlinkJailRoot.factlinkCoreEnvoy = FactlinkJailRoot.createSenderEnvoy iframe.contentWindow, ['showFactlink', 'prepareNewFactlink' ]

FactlinkJailRoot.openFactlinkModal = FactlinkJailRoot.factlinkCoreEnvoy.showFactlink
