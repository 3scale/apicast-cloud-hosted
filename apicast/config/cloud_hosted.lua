local PolicyChain = require('apicast.policy_chain')
local policy_chain = context.policy_chain

if not arg then -- {arg} is defined only when executing the CLI
  policy_chain:insert(PolicyChain.load_policy('cloud_hosted.balancer_blacklist', '0.1'), 1)
end

return {
  policy_chain = policy_chain,
  port = { metrics = 9421 },
}
