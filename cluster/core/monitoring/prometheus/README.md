# Prometheus

The cluster runs mimir for all of the Prometheus like needs, however not
everything is updated to work with it. As such, we run a very light
prometheus install that just reads from upstream mimir.

See this comment for more details: https://github.com/lensapp/lens/issues/909#issuecomment-2402819075
