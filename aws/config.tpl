# =============================================================================
# AWS CLI config template — rendered into ~/.aws/config via `op inject`
# (see bin/render-aws-config). The account ID lives in 1Password instead of
# here, so this template is safe to commit as-is.
#
# Adjust the op:// reference below to match your actual vault/item/field —
# create a 1Password item (e.g. "AWS" in your Private vault) with an
# "account_id" field holding the numeric account ID, or point this at
# wherever you'd rather keep it.
# =============================================================================
[default]
login_session = arn:aws:iam::{{ op://Private/AWS/account_id }}:root
region = us-west-2
