# Prometheus

The cluster runs mimir for all of the Prometheus like needs, however not
everything is updated to work with it. As such, we have a very simple nginx
reverse proxy that redirects everything to the `mimir-gateway:80/prometheus`
route.
