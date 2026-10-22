# Panopticon

## Licensing

The `deployment-init` phase tries to derive the licensing of Panopticon, from the licensing of RapidMiner AiHub.

The following table shows the Panopticon licensing modes and their AiHub equivalents:

| AiHub licensing | Panopticon Licensing |
| - | - |
| Legacy Rapidminer License | License file |
| ALTAIR_UNIT + altair_one | hosted HWU |
| ALTAIR_UNIT + on_prem | not hosted HWU |

### Altair Unit Hosted (Altair One)

When using `LICENSE_MODE=ALTAIR_UNIT` and `LICENSE_PROXY_MODE=altair_one` licensing, the following settings will be copied over from AiHub:

(This is the mapping from the .env file to the Panopticon.properties file)

| .env | Panopticon.properties |
| - | - |
| LICENSE_PROXY_MODE=altair_one | license.hwu.hosted=true |
| LICENSE_UNIT_MANAGER_USER_NAME | license.hwu.hosted.authorization.username |
| LICENSE_UNIT_MANAGER_PASSWORD | license.hwu.hosted.authorization.password |
| LICENSE_UNIT_MANAGER_AUTH_CODE | license.hwu.hosted.authorization.token |

### Altair Unit On-Prem

When using `LICENSE_MODE=ALTAIR_UNIT` and `LICENSE_PROXY_MODE=on_prem` licensing, the following settings will be copied over from AiHub:

(This is the mapping from the .env file to the Panopticon.properties file)

| .env | Panopticon.properties |
| - | - |
| LICENSE_PROXY_MODE=on_prem | license.hwu.hosted=false |
| ALTAIR_LICENSE_PATH | license.hwu.uri |

In this case you don't need any manual setup, you can start up the deployment as usual.

### Rapidminer legacy and Panopticon file based licensing

When using `LICENSE_MODE=RAPIDMINER`, you need to provide both the `LICENSE` variable containing your legacy RapidMiner license in the .env file and also provide your Panopticon license 
using the filename: `PanopticonLicense.xml` in the `panopticon/AppData` folder.

In this case you don't need any manual setup, you can start up the deployment as usual.

### Other options

If you want to use different licensing for Panopticon and AiHub, set the `PANOPTICON_DETACHED_LICENSE` variable to `true`. 

In this case you can configure Panopticon separately and there's no license related mapping from the .env file. 

Although the Panopticon licensing configuration will be independent from AiHub, there are several settings, that are automatically set up by the deployment-init 
(for example Keycloak configuration).

To start up Panopicon:

- Run the `deployment-init` profile as you would normally.
- Edit the newly created `panopticon/AppData/Panopticon_overide.properties` file according to the official 
Panopticon [documentation](https://help.altair.com/2022.1/panopticon/AltairPanopticon_RealTime_Install_Reference.pdf).
- Start the rest of the platform.
