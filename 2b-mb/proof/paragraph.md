A 1-paragraph policy:
        “When do we invalidate?”
        “When do we version instead?”
        “Why is /* restricted?”

Typically we want to prioritize versioning instead of invalidation. Invalidation will be used as last resort where changes are needed fast and frequently. Versioning forces immediate updates without the latency or costs associated with cache clearing. The `/*` aka "wildcard" needlessly depletes the invalidation budget where AWS gives 1000 invalidations for free before they charge 0.005 per invalidation `$$$`. In short versioning comes first, invalidation if all else fails, and we specifically invalidate what we need to save on costs. 