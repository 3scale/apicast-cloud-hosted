package = "apicast-cloud-hosted"
source = { url = '.' }
version = '0.1-0'
dependencies = {
  'lua-resty-iputils == 0.3.0-1'
}
build = {
  type = "builtin",
  modules = {
    ['cloud_hosted.module'] = 'blacklist.lua'
  }
}
