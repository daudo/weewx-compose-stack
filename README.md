# WeeWX Docker Compose Stack 🌩🐳

A nice little Docker Compose stack for [WeeWX](http://weewx.com) weather stations with nginx web serving, EcoWitt GW1000 driver integration, and Portainer compatibility.

Built on: [felddy/weewx-docker](https://github.com/felddy/weewx-docker) - Containerized WeeWX weather station software

Purpose: Easy deployment of WeeWX with modern orchestration, web interface, and EcoWitt weather station support

## Features

This Docker Compose stack provides:

- **EcoWitt GW1000 Driver**: Automatic installation and configuration of the GW1000 driver for WS90/WS3800 and similar weather stations
- **Nginx Web Server**: Serves WeeWX web interface with optimized configuration
- **Portainer Ready**: Complete docker-compose stack for easy deployment in Portainer
- **Environment Configuration**: Full station configuration via environment variables (location, coordinates, altitude, etc.)
- **Unified Initialization**: Streamlined setup process with modular scripts

The primary intention of this project is to make the collected data available on a self-hosted website. I personally have no interest in uploading the data to "the cloud", regardless of the provider, which is why this project is primarily concerned with purely local operation. For my use case, "local operation" means that I run WeeWX with portainer, see [README-PORTAINER.md](README-PORTAINER.md) for more details.

## Quick Start

### For EcoWitt GW1000/WS3800/... Users

If you have for example an EcoWitt WS90 weather station connected to a GW1000 compatible display/gateway (such as a WS3800), use this enhanced setup:

1. **Clone this repository**:

   ```bash
   git clone https://github.com/daudo/weewx-compose-stack.git
   cd weewx-compose-stack
   ```

2. **Deploy using Portainer**: See [README-PORTAINER.md](README-PORTAINER.md) for detailed instructions

3. **Or deploy with Docker Compose**:

   ```bash
   # Copy and edit environment configuration
   cp .env.example .env
   # Edit .env file to set your GW1000 IP, location, coordinates, etc.
   
   # Deploy the stack
   docker compose up -d
   ```

4. **Access your weather station**: Open `http://your-server:8080`

The system will automatically apply your new environment variables to the WeeWX configuration.

### For Standard WeeWX Users

If you need only basic WeeWX without the additional services (nginx, GW1000 driver, environment configuration), use the base image [felddy/weewx-docker](https://github.com/felddy/weewx-docker) repository directly.

## Architecture

This Docker Compose stack provides a 3-container architecture with unified initialization:

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│   weewx-init    │───▶│    weewx     │───▶│     nginx       │
│ (unified setup: │     │ (data gen)   │     │ (web server)    │
│  conf + drivers │     │              │     │                 │
│   + nginx.conf) │     │              │     │                 │
└─────────────────┘     └──────────────┘     └─────────────────┘
         │                     │                     │
         └─────────────────────┼─────────────────────┘
                               ▼
                    ┌─────────────────────┐
                    │   weewx_data        │
                    │   (shared volume)   │
                    └─────────────────────┘
```

**Initialization Features:**

- **Station Configuration**: Environment-driven setup (location, coordinates, altitude)
- **GW1000 Driver**: Automatic installation and configuration for Ecowitt weather stations
- **Web Interface**: Nginx configuration setup for optimized weather data serving
- **Modular Scripts**: Separate initialization scripts for each component

## Supported Hardware

- **EcoWitt stations** supported by the GW1000 driver (such as WS3800)

## Documentation

- **[README-PORTAINER.md](README-PORTAINER.md)** - Complete Portainer deployment guide

## Comparison with Base WeeWX Docker

| Feature | Base WeeWX Docker | This Stack |
|---------|-------------------|------------|
| Deployment | Single container | Multi-service stack |
| Driver Support | Manual installation | Automatic GW1000 driver installation |
| Web Interface | Manual setup required | Built-in nginx web server |
| Station Configuration | Manual weewx.conf editing | Environment variable driven |
| Portainer Support | Basic | Full stack with environment variables |
| EcoWitt GW1000 hardware | Not specifically supported | Native GW1000 support |
| Updates | Manual process | Automatic upstream updates |

## Contributing

Contributions should focus on:

- EcoWitt/GW1000 driver improvements
- Portainer deployment enhancements  
- Documentation updates
- Docker Compose orchestration improvements
- Environment variable configuration enhancements

For improvements to the base WeeWX container, please contribute to the base image repository: <https://github.com/felddy/weewx-docker>

## Automatic Updates

This stack benefits from base image improvements automatically:

- WeeWX version updates
- Security patches
- Base container improvements

Simply pull the latest `felddy/weewx:5` image to get updates.

## License

Except for the GW1000 driver, this project is released as open source under the [MIT license](LICENSE).

All contributions to this project will be released under the same MIT license. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.

The GW1000 driver in the [gw1000 subdirectory](./gw1000/) is copyrighted (C) 2020-2024 Gary Roderick and licensed under
the terms of the GNU General Public License as published by the Free Software Foundation.

## Support

- **Stack Issues**: Check [README-PORTAINER.md](README-PORTAINER.md) troubleshooting section  
- **EcoWitt/GW1000 Issues**: Hardware-specific problems with weather station drivers
- **General WeeWX Issues**: Consult [WeeWX documentation](https://weewx.com/docs/) and forums
- **Base Container Issues**: Report to [base image repository](https://github.com/felddy/weewx-docker/issues)
