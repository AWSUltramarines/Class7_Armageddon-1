Claude Update this document with the changes you are about to make before you make them!

My health checks are failing. Go through my terraform code to understand why they are failing.

Update Changelog with your findings.

---

## Health Check Failure Analysis - 2026-02-08

### Problem
Target group health checks failing for instances launched from the Auto Scaling Group (ASG).

**Current Status:**
- 1 healthy instance: `i-0000457c5205217c4` (standalone test_server)
- 2 unhealthy instances: `i-09ca1508442718bf6`, `i-00750963b165b3e1c` (from ASG)
- 2 draining instances: `i-055767b689e783ce3`, `i-044703429d96298d9` (being replaced)

### Root Cause
**Line 69 in `modules/compute/main.tf`** - Launch template uses wrong security group:

```hcl
vpc_security_group_ids = [var.alb_sg_id]  # ❌ INCORRECT
```

**Impact:**
- Instances from launch template get ALB security group (`sg-0337ab822a075018b`)
- ALB security group doesn't allow inbound traffic from itself
- ALB health checks on port 80 are blocked → instances marked unhealthy
- Standalone `test_server` instance works because it correctly uses `compute_sg_id` (line 14)

**Security Group Rules Analysis:**
- **Compute SG** (`sg-0bfd20b9b2ddde7a3`): Has ingress rule allowing port 80 from ALB SG ✓
- **ALB SG** (`sg-0337ab822a075018b`): Only allows port 80 from generic CIDR, port 443 from CloudFront ❌

### Solution
Change line 69 in `modules/compute/main.tf` from:
```hcl
vpc_security_group_ids = [var.alb_sg_id]
```

To:
```hcl
vpc_security_group_ids = [var.compute_sg_id]
```

This ensures instances launched from the template have the correct security group that allows ALB health checks.

### Changes Applied
✅ Updated `modules/compute/main.tf` line 69:
- Changed `vpc_security_group_ids = [var.alb_sg_id]`
- To `vpc_security_group_ids = [var.compute_sg_id]`

**Next Steps:**
1. Run `terraform apply` to update the launch template
2. Terminate unhealthy instances to force ASG to launch new instances with correct security group
3. Wait for new instances to become healthy (60-90 seconds)
4. Verify all targets show "healthy" status

---

## Health Check Failure Analysis #2 - 2026-02-08

### Problem
Health checks STILL failing after security group fix. New investigation reveals:

**Current Status:**
- 1 healthy instance: `i-0cb2aefe90de82047` (test_server using userdata-caching.sh) ✓
- 6 unhealthy instances: All from ASG using userdata.sh ❌
- All instances now have CORRECT security group (compute_sg_id) ✓

### Root Cause #2
**Line 71 in `modules/compute/main.tf`** - Launch template uses wrong/broken user data script:

```hcl
user_data = filebase64("${path.root}/userdata.sh")  # ❌ BROKEN SCRIPT
```

**Critical Errors in userdata.sh:**
1. Line 16: Uses `logging.basicConfig()` but `logging` module is NEVER imported
2. Line 18: References `CloudWatchLogHandler` which doesn't exist
3. Line 29-30: References undefined variables `PARAM_ENDPOINT` and `PARAM_DBNAME`

**Result:** Flask app fails to start → health checks fail → instances marked unhealthy

**Why test_server is healthy:**
- Uses correct script: `userdata-caching.sh` (line 16 in compute/main.tf)
- Uses `templatefile()` with proper variable interpolation ✓

### Solution
Change line 71 in `modules/compute/main.tf` to match the working test_server configuration:

**From:**
```hcl
user_data = filebase64("${path.root}/userdata.sh")
```

**To:**
```hcl
user_data_base64 = base64encode(templatefile("${path.root}/userdata-caching.sh", {
  cf_header_pw = var.cf_header_pw
  secret_name  = var.secret_name
}))
```

This ensures ASG instances use the same working Flask app configuration as test_server.

### Changes Applied
✅ Updated `modules/compute/main.tf` launch template (lines 63-77):

**Before:**
```hcl
user_data = filebase64("${path.root}/userdata.sh")
```

**After:**
```hcl
user_data_base64 = base64encode(templatefile("${path.root}/userdata-caching.sh", {
  cf_header_pw = var.cf_header_pw
  secret_name  = var.secret_name
}))

iam_instance_profile {
  name = var.iam_instance_profile
}
```

**Additional Changes:**
- Added IAM instance profile to launch template (required for Secrets Manager access)

**Next Steps:**
1. Run `terraform apply` to update launch template
2. Terminate unhealthy instances (ASG will replace them)
3. New instances will:
   - Use working `userdata-caching.sh` script ✓
   - Have correct security group (compute_sg_id) ✓
   - Have IAM permissions for Secrets Manager ✓
   - Pass health checks ✓

---

## Health Check Failure Analysis #3 - 2026-02-08

### Problem
ASG still creating unhealthy instances after applying all previous fixes.

### Root Cause #3
**Launch template (lines 61-83 in `modules/compute/main.tf`)** - Missing user_data configuration entirely!

Current state:
```hcl
resource "aws_launch_template" "dev_lt" {
  image_id      = aws_instance.test_server.ami
  instance_type = var.instance_type
  vpc_security_group_ids = [var.compute_sg_id]
  iam_instance_profile {
    name = var.iam_instance_profile
  }
  # NO USER DATA! ❌
}
```

**Result:** Instances launch with NO Flask app → health checks fail

**Additional Issue:**
- Line 16: test_server uses `filebase64()` instead of `templatefile()`
- Variables like `${cf_header_pw}` and `${secret_name}` are NOT interpolated
- Flask app receives literal strings instead of actual values

### Solution
Add user_data to launch template AND fix test_server user_data:

```hcl
# Launch template
user_data_base64 = base64encode(templatefile("${path.root}/userdata-caching.sh", {
  cf_header_pw = var.cf_header_pw
  secret_name  = var.secret_name
}))

# test_server
user_data_base64 = base64encode(templatefile("${path.root}/userdata-caching.sh", {
  cf_header_pw = var.cf_header_pw
  secret_name  = var.secret_name
}))
```

### Changes Applied
✅ Updated `modules/compute/main.tf`:

**1. Fixed test_server (lines 16-19):**
- Changed: `user_data_base64 = filebase64("${path.root}/userdata-caching.sh")`
- To: `user_data_base64 = base64encode(templatefile(...))` with variable interpolation

**2. Added user_data to launch template (after line 67):**
- Added missing user_data configuration (launch templates use `user_data`, not `user_data_base64`)
- Uses templatefile() with cf_header_pw and secret_name variables

**Next Steps:**
1. `terraform apply` is running - wait for completion
2. ASG will create new instances with:
   - Flask app properly configured ✓
   - Correct security group ✓
   - IAM permissions ✓
   - Variable interpolation working ✓
3. Instances should now pass health checks

**Correction Applied:**
- Fixed attribute name: `user_data_base64` → `user_data` (aws_launch_template uses `user_data`, not `user_data_base64`)

---

## 500 Error Analysis - 2026-02-08

### Problem
CloudFront returning 500 INTERNAL SERVER ERROR when accessing `/init` endpoint:

```
$ curl -I https://dustycloudeng.click/init
HTTP/1.1 500 INTERNAL SERVER ERROR
Server: Werkzeug/2.2.3 Python/3.7.16
X-Cache: Error from cloudfront
```

### Root Cause #4
**Lines 43-44 in `userdata-caching.sh`** - Duplicate/malformed return statements in `get_conn()` function:

```python
return pymysql.connect(
    host=c.get("host"),
    user=c.get("username"),
    password=c.get("password"),
    port=int(c.get("port", 3306)),
    database=c.get("dbname", "labdb"),
    return pymysql.connect(host=host, user=user, password=password, port=port, database=db, autocommit=True)
)
```

**Impact:**
- Python syntax error when app.py is created
- Flask app fails to start
- All HTTP requests result in 500 errors
- CloudFront receives error responses from origin

### Solution
Fix lines 37-44 in `userdata-caching.sh` to have a single, correct return statement:

```python
def get_conn():
    c = get_db_creds()
    return pymysql.connect(
        host=c.get("host"),
        user=c.get("username"),
        password=c.get("password"),
        port=int(c.get("port", 3306)),
        database=c.get("dbname", "labdb"),
        autocommit=True
    )
```

**Next Steps:**
1. Fix `userdata-caching.sh` syntax error
2. Run `terraform apply` to update instances
3. Terminate existing instances to force recreation with fixed script
4. Verify `/init` endpoint returns 200 OK

---