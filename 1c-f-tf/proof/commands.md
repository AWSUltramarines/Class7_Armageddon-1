Change password to generate error:
```rb
aws secretsmanager update-secret \
  --secret-id lab/rds/mysql \
  --secret-string "{\"username\":\"devsecopsengineer\",\"password\":\"WRONG_PASSWORD_FOR_LAB\",\"host\":\"$(terraform output -raw db_endpoint)\",\"port\":3306,\"dbname\":\"labdb\"}" \
  --region us-east-2
```

Correct password:
```rb
X:+[)nMFnW8I#6<)$#)1%Tn7xC
```

___

A6 modified Query:
```rb
fields @timestamp, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter uri =~ /wp-login|xmlrpc|.env|admin|phpmyadmin|.git|login/
| stats count() as hits by clientIp, uri
| sort hits desc
| limit 50
```

A7 modified Query:
```rb
fields @timestamp, httpRequest.clientIp as clientIp, httpRequest.uri as uri 
| filter uri =~ /wp-login|xmlrpc|.env|admin|phpmyadmin|.git|login/
| stats count() as hits by clientIp, uri 
| sort hits desc 
| limit 50
```

B1 modified Query:
```rb
fields @timestamp, @message
| filter @message like /ERROR/ or @message like /Exception/ or @message like /DB/ or @message like /timeout/
| stats count() as errors by bin(1m)
```

B2 modified Query:
```rb
fields @timestamp, @message 
| filter @message like /DB|mysql|timeout|refused|Access denied|could not connect/ 
| sort @timestamp desc 
| limit 50
```

B3 modified Query:
```rb
fields @timestamp, @message 
| filter @message like "ERROR" or @message like "Exception" or @message like "DB" or @message like "timeout"
| stats count() as errors by bin(1m)
```

