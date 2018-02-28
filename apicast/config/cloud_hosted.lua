local PolicyChain = require('apicast.policy_chain')
local policy_chain = context.policy_chain

if not arg then -- {arg} is defined only when executing the CLI
  policy_chain:insert(PolicyChain.load_policy('cloud_hosted.rate_limit', '0.1', {
    limit = os.getenv('RATE_LIMIT') or 5,
    burst = os.getenv('RATE_LIMIT_BURST') or 50 }), 1)
  policy_chain:insert(PolicyChain.load_policy('cloud_hosted.balancer_blacklist', '0.1'), 1)
  policy_chain:insert(PolicyChain.load_policy('cloud_hosted.metrics', '0.1', { log_level = 'warn' }))
end

return {
  policy_chain = policy_chain,
  ports = { metrics = 9100 },
}
