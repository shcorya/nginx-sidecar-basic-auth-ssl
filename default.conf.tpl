# Upstream
upstream backend {
    server {{ .Env.FORWARD_HOST }}:{{ .Env.FORWARD_PORT }} max_fails=0;
}

# WS Handling
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

# Server Definition
server {
    ssl_certificate     /etc/nginx/server.crt;
    ssl_certificate_key /etc/nginx/server.key;

    ssl_session_cache  builtin:1000  shared:SSL:10m;
    ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    ssl_prefer_server_ciphers on;

    listen {{ .Env.PORT }} ssl;

{{ if .Env.WEBSOCKET_PATH }}
    location {{ .Env.WEBSOCKET_PATH }} {
        proxy_pass http://backend{{ .Env.FORWARD_WEBSOCKET_PATH | default "" }};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
        proxy_read_timeout {{ .Env.PROXY_READ_TIMEOUT }};
        proxy_send_timeout {{ .Env.PROXY_SEND_TIMEOUT }};
    }
{{ end }}

    location / {

        # Basic Auth
        limit_except OPTIONS {
            auth_basic "Restricted";
            auth_basic_user_file "auth.htpasswd";
        }

        # Proxy
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
        proxy_pass http://backend;
        proxy_read_timeout {{ .Env.PROXY_READ_TIMEOUT }};
        proxy_send_timeout {{ .Env.PROXY_SEND_TIMEOUT }};
        client_max_body_size {{ .Env.CLIENT_MAX_BODY_SIZE }};
        proxy_request_buffering {{ .Env.PROXY_REQUEST_BUFFERING }};
        proxy_buffering {{ .Env.PROXY_BUFFERING }};
    }
}
