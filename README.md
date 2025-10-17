# Traefik Reverse Proxy with Automated HTTPS

This project provides a fully automated, Docker-based reverse proxy using Traefik. It is designed to automatically provide valid, browser-trusted SSL certificates for any web service that is run inside a Docker container on the same host.

## Features

- **Automated Service Discovery:** Uses Traefik's Docker provider to automatically detect and route traffic to new containers.
- **Automated SSL Certificates:** Uses Let's Encrypt with the Cloudflare DNS-01 challenge to automatically issue and renew SSL certificates. This means you don't need to open any ports other than 80 and 443.
- **Secure by Default:** Includes a middleware to automatically redirect all HTTP traffic to HTTPS.
- **Simple to Manage:** Configuration is managed through Docker labels on your application containers.

## Prerequisites

1.  **Docker and Docker Compose:** Must be installed on your machine.
2.  **A Domain Name:** You must own a domain name with its DNS managed by Cloudflare.
3.  **Cloudflare API Token:** You need a Cloudflare API token with specific permissions. See the [Appendix](#appendix-creating-a-cloudflare-api-token) for a step-by-step guide.

---

## Getting Started

### 1. Clone the Repository
Clone this project to a location on your server.

```bash
git clone <repository-url> traefik-proxy
cd traefik-proxy
```

### 2. Configure Environment Variables
Your Cloudflare API token and Let's Encrypt notification email must be stored in an `.env` file. This file is included in `.gitignore` to prevent you from accidentally committing your secrets.

Create the file by copying the example:
```bash
cp .env.example .env
```

Now, edit the `.env` file and add your Cloudflare API token and your email address:
```
CLOUDFLARE_API_TOKEN=your-long-api-token-goes-here
ACME_EMAIL=your-email@example.com
```

---

## Usage

### 1. Start the Traefik Service
Run the following command from within the `traefik-proxy` directory:

```bash
docker-compose up -d
```

This will build and start the Traefik reverse proxy in the background. It is now listening for new Docker containers. You can check that it's running with `docker ps` and view the Traefik Dashboard by opening a browser to `http://localhost:8080`.

### 2. Verify Your Setup (Optional Demo)
This repository includes a simple Nginx webserver in the `demo` directory to help you verify that your Traefik and DNS configuration is working correctly.

**A. Navigate to the Demo Directory:**
```bash
cd demo
```

**B. Configure the Domain:**
The domain for the demo service is configured using an environment variable. In the `demo` directory, create an `.env` file by copying the example:

```bash
cp .env.example .env
```

Now, edit the new `.env` file and set the `DOMAIN_DEMO` variable to a domain you control:

```
DOMAIN_DEMO=your-domain.com
```

**C. Create a DNS Record:**
In your Cloudflare dashboard, create an `A` record for the domain you configured in the `.env` file, pointing to the public IP address of your server.

**D. Run the Demo:**
From within the `demo` directory, run the following command:
```bash
docker-compose up -d
```

After a minute, visit the domain you configured (e.g., `http://your-domain.com`). You should be automatically redirected to `https` and see the test page with a valid SSL certificate. The page will automatically validate the SSL certificate and display a confirmation that your Traefik reverse proxy is correctly configured with a browser-trusted certificate.

**E. Stop the Demo:**
Once you are finished, you can stop and remove the demo container:
```bash
# Run from the demo directory
docker-compose down
```

### 3. Connecting Your Own Services
To connect your own applications, you must run them in Docker on the same host and add specific labels to their `docker-compose.yml`.

**Key Requirements:**
1.  **Shared Network:** Your application's container must be connected to the `traefik_net` external network.
2.  **Traefik Labels:** You must add labels to instruct Traefik how to route traffic to your container.

**Example `docker-compose.yml` for your application:**
```yaml
version: '3.8'

services:
  my-app:
    # This assumes you have a Dockerfile for your app
    build: .
    restart: unless-stopped
    labels:
      # --- Instructions for Traefik ---
      - "traefik.enable=true"

      # --- HTTP Router (for redirection) ---
      - "traefik.http.routers.my-app-http.rule=Host(`app.your-domain.com`)"
      - "traefik.http.routers.my-app-http.entrypoints=web"
      - "traefik.http.routers.my-app-http.middlewares=redirect-to-https"

      # --- HTTPS Router ---
      - "traefik.http.routers.my-app-https.rule=Host(`app.your-domain.com`)"
      - "traefik.http.routers.my-app-https.entrypoints=websecure"
      - "traefik.http.routers.my-app-https.tls=true"
      - "traefik.http.routers.my-app-https.tls.certresolver=cloudflare"
      
      # --- Define the service and port ---
      - "traefik.http.services.my-app-service.loadbalancer.server.port=3000" # CHANGE: Port your app runs on inside the container

# This is critical: your app must be on the same network as Traefik
networks:
  default:
    name: traefik_net
    external: true
```

---

## Managing the Traefik Service

- **To stop the Traefik proxy:**
  ```bash
  # Run this from the /traefik-proxy directory
  docker-compose down
  ```
- **To view logs:**
  ```bash
  docker logs traefik_reverse_proxy
  ```
- **To update Traefik:**
  ```bash
  docker-compose pull
  docker-compose up -d
  ```

---

## Appendix: Creating a Cloudflare API Token

To allow Traefik to perform the DNS-01 challenge, it needs an API token with specific permissions for your domain.

1.  **Log in** to your [Cloudflare Dashboard](https://dash.cloudflare.com).
2.  From the home page, click on your profile icon in the top right and select **"My Profile"**, or navigate directly to the [API Tokens](https://dash.cloudflare.com/profile/api-tokens) page.
3.  Click the **"Create Token"** button.
4.  Find the **"Edit zone DNS"** template and click the **"Use template"** button.
5.  Configure the token with the following settings:
    *   **Token Name:** Give it a descriptive name, like "Traefik DNS Solver".
    *   **Permissions:** The template will automatically add `Zone:DNS:Edit`. You also need to add `Zone:Zone:Read`. Click "+ Add more", select `Zone`, `Zone`, and `Read`.
    *   **Zone Resources:** Select `Include`, `Specific zone`, and then choose the domain you want to use from the dropdown list.
6.  Click **"Continue to summary"**.
7.  Review the permissions to ensure they are correct (`Zone:DNS:Edit` and `Zone:Zone:Read`).
8.  Click **"Create Token"**.
9.  **Important:** Cloudflare will only show you the token once. Copy it immediately and paste it into your `.env` file as the value for `CLOUDFLARE_API_TOKEN`.
