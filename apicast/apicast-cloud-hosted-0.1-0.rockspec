package = "apicast-cloud-hosted"
source = { url = '.' }
version = '0.1-0'
dependencies = {
  'lua-resty-iputils == 0.3.0-1'
}
build = {
  type = "builtin",
  modules = {
    ['cloud_hosted.balancer_blacklist'] = 'balancer_blacklist.lua',
    ['cloud_hosted.module'] = 'module.lua'
  }
}
