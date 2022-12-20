module BushSlicer
  class ClusterOperator < ClusterResource
    RESOURCE = "clusteroperators"
    # return the an array of versions for a particular clusteroperator
    def versions(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      rr.dig('status', 'versions').map { |v| v['version'] if v['name'] == 'operator' }.compact
    end
    # given a target_version return true if has matching version else false
    def version_exists?(version:, user: nil, cached: true, quiet: false)
      res = self.versions.select { |v| v == version }
      res.count != 0
    end

    # return an array of related objects
    def related_objects(user: nil, cached: true, quiet: false)
      rr = raw_resource(user: user, cached: cached, quiet: quiet)
      return rr.dig('status', 'relatedObjects')
    end

  end
end

def wait_till_ready(user, seconds)
  res = nil
  iterations = 0
  start_time = monotonic_seconds

  success = wait_for(seconds) {
    res = ready?(user: user, quiet: true)
    iterations = iterations + 1
    break if res
  }
  return res
end

def ready?(user: nil, cached: false, quiet: false)
  self.condition(type: 'Available', cached: false)['status'] == 'True'
end

end
end

