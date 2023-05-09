job "bazarr" {
  namespace   = "download"
  datacenters = ["cluster"]
  type        = "service"

  constraint {
    attribute = "${meta.computer.plexable}"
    value     = "false"
  }

  group "bazarr" {
    network {
      mode = "bridge"

      port "envoy_metrics" {
        to = 9102
      }

      port "http" {
        to = 6767
      }
    }

    service {
      name = "bazarr"
      port = 6767

      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }

            upstreams {
              destination_name = "radarr"
              local_bind_port  = 7878
            }

            upstreams {
              destination_name = "sonarr"
              local_bind_port  = 8989
            }
          }
        }

        sidecar_task {
          env {
            ENVOY_UID = "0"
          }
        }
      }

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics}"
      }
    }

    volume "config" {
      type            = "csi"
      source          = "bazarr-config"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "media" {
      type            = "csi"
      source          = "media"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "bazarr" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/bazarr:latest"
        ports = ["http"]

        volumes = [
          "local/config.xml:/config/config/config.ini",
        ]

        privileged = true
      }

      env {
        PUID     = 1000
        PGID     = 1000
        TZ       = "America/Denver"
      }

      resources {
        cpu    = 4000
        memory = 4096
      }

      template {
        data = <<EOF
[general]
ip = 0.0.0.0
port = {{ env "NOMAD_ALLOC_PORT_http" }}
base_url =
path_mappings = [['/media/shows/', '/media/shows/']]
debug = False
branch = master
auto_update = False
single_language = False
minimum_score = 90
use_scenename = True
use_postprocessing = False
postprocessing_cmd =
postprocessing_threshold = 90
use_postprocessing_threshold = False
postprocessing_threshold_movie = 70
use_postprocessing_threshold_movie = False
use_sonarr = True
use_radarr = True
path_mappings_movie = [['/media/movies/', '/media/movies/']]
serie_default_enabled = True
serie_default_profile = 1
movie_default_enabled = True
movie_default_profile = 1
page_size = 25
page_size_manual_search = 10
minimum_score_movie = 70
use_embedded_subs = False
embedded_subs_show_desired = True
utf8_encode = True
ignore_pgs_subs = False
ignore_vobsub_subs = False
ignore_ass_subs = False
adaptive_searching = True
adaptive_searching_delay = 3w
adaptive_searching_delta = 1w
enabled_providers = ['tvsubtitles', 'wizdom', 'yifysubtitles', 'supersubtitles', 'subscenter']
multithreading = True
chmod_enabled = False
chmod = 0640
subfolder = current
subfolder_custom =
upgrade_subs = True
upgrade_frequency = 12
days_to_upgrade_subs = 7
upgrade_manual = True
anti_captcha_provider = None
wanted_search_frequency = 3
wanted_search_frequency_movie = 3
subzero_mods = remove_tags,common
dont_notify_manual_actions = False
hi_extension = hi
flask_secret_key = 1a9b124e83226defcd067be568d913c3

[auth]
type = None
username =
password =
apikey = {{ key "download/bazarr" }}

[backup]
folder = /config/backup
retention = 31
frequency = Weekly
day = 6
hour = 3

[sonarr]
ip = {{ env "NOMAD_UPSTREAM_IP_sonarr" }}
port = {{ env "NOMAD_UPSTREAM_PORT_sonarr" }}
base_url =
ssl = False
apikey = {{ key "download/sonarr" }}
full_update = Daily
full_update_day = 6
full_update_hour = 4
only_monitored = False
series_sync = 60
episodes_sync = 60
excluded_tags = []
excluded_series_types = []
use_ffprobe_cache = True
exclude_season_zero = False
defer_search_signalr = False

[radarr]
ip = {{ env "NOMAD_UPSTREAM_IP_radarr" }}
port = {{ env "NOMAD_UPSTREAM_PORT_radarr" }}
base_url =
ssl = False
apikey = {{ key "download/radarr" }}
full_update = Daily
full_update_day = 6
full_update_hour = 5
only_monitored = False
movies_sync = 60
excluded_tags = []
use_ffprobe_cache = True
defer_search_signalr = False

[proxy]
type = None
url =
port =
username =
password =
exclude = ["localhost","127.0.0.1"]

[opensubtitles]
username =
password =
use_tag_search = False
vip = False
ssl = True
timeout = 15
skip_wrong_fps = False

[opensubtitlescom]
username =
password =
use_hash = True

[addic7ed]
username =
password =
cookies =
user_agent =
vip = False

[podnapisi]
verify_ssl = True

[legendasdivx]
username =
password =
skip_wrong_fps = False

[ktuvit]
email =
hashed_password =

[legendastv]
username =
password =
featured_only = False

[xsubs]
username =
password =

[assrt]
token =

[anticaptcha]
anti_captcha_key =

[deathbycaptcha]
username =
password =

[napisy24]
username =
password =

[subscene]
username =
password =

[betaseries]
token =

[analytics]
enabled = True

[titlovi]
username =
password =

[titulky]
username =
password =
approved_only = False
skip_wrong_fps = False
multithreading = True

[embeddedsubtitles]
included_codecs = []
hi_fallback = False
timeout = 600
include_ass = True
include_srt = True
mergerfs_mode = False

[karagarga]
username =
password =
f_username =
f_password =

[subsync]
use_subsync = False
use_subsync_threshold = False
subsync_threshold = 90
use_subsync_movie_threshold = False
subsync_movie_threshold = 70
debug = False

[series_scores]
hash = 359
series = 180
year = 90
season = 30
episode = 30
release_group = 15
source = 7
audio_codec = 3
resolution = 2
video_codec = 2
hearing_impaired = 1
streaming_service = 0
edition = 0

[movie_scores]
hash = 119
title = 60
year = 30
release_group = 15
source = 7
audio_codec = 3
resolution = 2
video_codec = 2
hearing_impaired = 1
streaming_service = 0
edition = 0
EOF

        destination = "local/config.xml"
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      volume_mount {
        volume      = "media"
        destination = "/media"
      }
    }
  }
}
