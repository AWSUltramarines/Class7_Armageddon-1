2b_Be_A_MANB_3

A 1-paragraph policy:
        “When do we invalidate?”
        “When do we version instead?”
        “Why is /* restricted?”


Invalidation commands should carefully be used to clear stored cache information when the returned data for a URL needs quick and precise updating. Versioning is preferred when files are more likely to be static or not change often. Versioning is proffered because older files continue to work and new deployments are always correct, but you will need a new url every time. Using /* is normally restricted because it is too broad, You could unintentionally erase cached data that you dont removed.