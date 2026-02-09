2B_B Deliverable (Written Explanation)

“What is my cache key for /api/* and why?”

The cache key for /api/* is just the url. Its intentionally minimal because we are not going to cache anything anyways unless the origin sends the correct header.

 
 “What am I forwarding to origin and why?”

This configuration is forwarding cookies, query strings, headers, and authorizations. These are the minimal requirements for the app to process the request. This will allow for cookies, filtering/pagination, details needed for routing, and authorization. 


